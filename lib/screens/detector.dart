import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tflite_audio/tflite_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:torch_light/torch_light.dart';
import 'package:permission_handler/permission_handler.dart';

class DetectorScreen extends StatefulWidget {
  final bool triggerEmergencyOnInit;
  const DetectorScreen({super.key, this.triggerEmergencyOnInit = false});

  @override
  State<DetectorScreen> createState() => _DetectorScreenState();
}

class _DetectorScreenState extends State<DetectorScreen> with TickerProviderStateMixin {
  bool _isListening = false;
  double _soundLevel = 0.0;
  String _lastWords = "Inicializando red neuronal local...";
  
  // Controlador de la animación estroboscópica visual (parpadeo de pantalla en alertas)
  late AnimationController _strobeController;
  bool _isAlarmActive = false;
  String _activeAlarmType = "";
  
  // Temporizadores y suscripciones para la linterna y reconocimiento acústico
  Timer? _strobeTimer;
  Timer? _waveTimer; // Temporizador para animar las ondas de forma orgánica
  bool _torchOn = false;
  StreamSubscription<Map<dynamic, dynamic>>? _tfliteSubscription;

  // Controlador de la animación de ondas de sonido en pantalla
  late AnimationController _waveController;

  // Categorías de sonido con colores distintivos, iconos e información para la UI
  final List<Map<String, dynamic>> _soundCategories = [
    {
      'name': 'Alerta Sísmica',
      'icon': Icons.warning_amber_rounded,
      'color': const Color(0xFFEF4444), // Rojo
      'desc': 'Alarma sísmica mexicana',
    },
    {
      'name': 'Ambulancia',
      'icon': Icons.local_hospital_outlined,
      'color': const Color(0xFFF59E0B), // Ámbar
      'desc': 'Sirena médica (Hi-Lo)',
    },
    {
      'name': 'Patrulla',
      'icon': Icons.local_police_outlined,
      'color': const Color(0xFF3B82F6), // Azul
      'desc': 'Sirena policial (Yelp)',
    },
    {
      'name': 'Claxon / Bocina',
      'icon': Icons.volume_up_outlined,
      'color': const Color(0xFF8B5CF6), // Morado
      'desc': 'Bocinas y ruidos secos',
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Iniciar controlador de la animación de la onda central
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Iniciar controlador estroboscópico de parpadeo visual en pantalla de alerta
    _strobeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Cargar el modelo e iniciar el monitoreo acústico neural
    _initTflite();

    // Iniciar la fluctuación fluida y orgánica del radar central morado
    _waveTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && _isListening && !_isAlarmActive) {
        setState(() {
          // Fluctuación natural orgánica entre 0.15 y 0.55
          _soundLevel = 0.15 + (0.40 * (double.tryParse((0.5 + (0.5 * (timer.tick % 10) / 10)).toString()) ?? 0.0));
        });
      }
    });

    // Comprobar si se requiere disparar la alarma de emergencia inmediatamente al abrir la pantalla
    if (widget.triggerEmergencyOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerAlarm('Alerta de Emergencia Manual 🚨', isSimulated: true);
      });
    }
  }

  @override
  void dispose() {
    _stopTfliteListening();
    _waveTimer?.cancel();
    _stopAllAlerts();
    _waveController.dispose();
    _strobeController.dispose();
    super.dispose();
  }

  // Inicializar y cargar el modelo Teachable Machine TFLite en memoria
  void _initTflite() async {
    try {
      debugPrint("Verificando permisos de micrófono con permission_handler...");
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }

      if (!status.isGranted) {
        setState(() {
          _lastWords = "Permiso de micrófono requerido.";
        });
        return;
      }

      debugPrint("Permiso concedido. Cargando modelo TFLite de audio...");
      await TfliteAudio.loadModel(
        model: 'assets/soundclassifier_with_metadata.tflite',
        label: 'assets/labels.txt',
        numThreads: 1,
        isAsset: true,
        inputType: 'rawAudio',
      );
      debugPrint("Modelo TFLite cargado con éxito.");
      _startTfliteListening();
    } catch (e) {
      debugPrint("Error al cargar modelo TFLite o permisos: $e");
      setState(() {
        _lastWords = "Error al inicializar la red neuronal.";
      });
    }
  }

  // Iniciar la escucha continua e inferencia en tiempo real usando TfliteAudio
  void _startTfliteListening() {
    if (_isAlarmActive || _tfliteSubscription != null) return;

    setState(() {
      _isListening = true;
      _lastWords = "Monitoreando IA local activa...";
    });

    try {
      // Configuramos la grabación continua con el sample rate e input de Teachable Machine
      final recognitionStream = TfliteAudio.startAudioRecognition(
        sampleRate: 44100,
        audioLength: 44032, // Requerido por Teachable Machine para ventana de 1s
        bufferSize: 22016,  // Mitad del audioLength
        numOfInferences: 10000, // Inferencia continua durante miles de ventanas consecutivas
      );

      _tfliteSubscription = recognitionStream.listen(
        (event) {
          if (!mounted || _isAlarmActive) return;

          String result = event["recognitionResult"] ?? "";
          debugPrint("Inferencia IA: $result");

          // Si el resultado predice una clase que no es Ruido de Fondo, disparamos la alerta respectiva
          if (result.contains("Alerta sismica")) {
            _triggerAlarm('Alerta Sísmica 🚨', isSimulated: false);
          } else if (result.contains("Ambulancia")) {
            _triggerAlarm('Ambulancia 🚑', isSimulated: false);
          } else if (result.contains("Patrulla")) {
            _triggerAlarm('Patrulla 🚓', isSimulated: false);
          }
        },
        onError: (err) {
          debugPrint("Error en TfliteAudio Stream: $err");
          _stopTfliteListening();
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted && !_isAlarmActive) {
              _startTfliteListening();
            }
          });
        },
        onDone: () {
          debugPrint("TfliteAudio Stream completado");
          _stopTfliteListening();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isAlarmActive) {
              _startTfliteListening();
            }
          });
        },
      );
    } catch (e) {
      debugPrint("Error al iniciar escucha TFLite: $e");
    }
  }

  void _stopTfliteListening() {
    _tfliteSubscription?.cancel();
    _tfliteSubscription = null;
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  // Activar la alerta visual, sonora y física de alto impacto
  void _triggerAlarm(String alarmType, {required bool isSimulated}) {
    if (_isAlarmActive) return;

    // Detener el micrófono de TfliteAudio de inmediato para liberar recursos de hardware
    _stopTfliteListening();

    setState(() {
      _isAlarmActive = true;
      _activeAlarmType = alarmType;
      _isListening = false;
      _soundLevel = 1.0; // Nivel estático al máximo durante el estallido
    });

    // 1. Activar animación de colores estroboscópicos parpadeantes en pantalla
    _strobeController.repeat(reverse: true);

    // 2. Activar el patrón de vibración física continua de alta potencia
    _triggerVibration();

    // 3. Activar el parpadeo físico del flash de la cámara del dispositivo
    _triggerCameraFlash();
  }

  // Iniciar parpadeo del flash/linterna de la cámara física del celular
  void _triggerCameraFlash() async {
    try {
      bool hasTorch = await TorchLight.isTorchAvailable();
      if (hasTorch) {
        _strobeTimer?.cancel();
        _strobeTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) async {
          if (!_isAlarmActive) {
            timer.cancel();
            _strobeTimer = null;
            await TorchLight.disableTorch();
            return;
          }
          _torchOn = !_torchOn;
          try {
            if (_torchOn) {
              await TorchLight.enableTorch();
            } else {
              await TorchLight.disableTorch();
            }
          } catch (_) {}
        });
      }
    } catch (e) {
      debugPrint('Error de linterna física: $e');
    }
  }

  // Ejecutar el patrón rítmico personalizado de vibración del dispositivo
  void _triggerVibration() async {
    try {
      bool? hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        // Patrón: vibrar por 400ms, pausar por 100ms, repetir indefinidamente
        Vibration.vibrate(
          pattern: [100, 400, 100, 400, 100, 400],
          repeat: 0, // repetir indefinidamente
          intensities: [0, 255, 0, 255, 0, 255],
        );
      }
    } catch (e) {
      debugPrint('Error de vibración del sistema: $e');
    }
  }

  // Detener de forma 100% segura y redundante todos los canales activos de alerta
  void _stopAllAlerts() async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
      }
    } catch (_) {}

    // Detener animación de parpadeo de colores en la pantalla
    _strobeController.stop();
    _strobeController.reset();

    // Detener parpadeo y apagar la linterna de la cámara de inmediato
    _strobeTimer?.cancel();
    _strobeTimer = null;
    _torchOn = false;
    
    // Apagado físico reiterado en bucle corto de 5 pasos para limpiar retrasos de hardware en el Samsung A35
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () async {
        try {
          await TorchLight.disableTorch();
        } catch (_) {}
      });
    }

    // Detener vibración del teléfono
    try {
      await Vibration.cancel();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isAlarmActive = false;
        _activeAlarmType = "";
        _soundLevel = 0.0;
      });
    }

    // Volver a iniciar el monitoreo inteligente
    _startTfliteListening();
  }

  @override
  Widget build(BuildContext context) {
    // Generar el fondo dinámico de pantalla que parpadea de forma fluida
    return AnimatedBuilder(
      animation: _strobeController,
      builder: (context, child) {
        Color bgColor = const Color(0xFFF5F3FF); // Color lavanda de fondo
        if (_isAlarmActive) {
          if (_activeAlarmType.contains('Sísmica')) {
            bgColor = Color.lerp(
              const Color(0xFFEF4444),
              const Color(0xFFF97316),
              _strobeController.value,
            )!;
          } else if (_activeAlarmType.contains('Ambulancia')) {
            bgColor = Color.lerp(
              const Color(0xFFEF4444),
              Colors.white,
              _strobeController.value,
            )!;
          } else if (_activeAlarmType.contains('Patrulla')) {
            bgColor = Color.lerp(
              const Color(0xFF1D4ED8),
              const Color(0xFFEF4444),
              _strobeController.value,
            )!;
          } else {
            bgColor = Color.lerp(
              const Color(0xFF7C3AED),
              const Color(0xFFFBBF24),
              _strobeController.value,
            )!;
          }
        }

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra Superior (Header)
                _buildHeader(context),

                // Contenedor principal del Visualizador de ondas o de la Pantalla de Peligro
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: _isAlarmActive 
                        ? _buildAlarmUI()
                        : _buildSoundWaveUI(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Interfaz de la barra superior con botón para retroceder
  Widget _buildHeader(BuildContext context) {
    final textColor = _isAlarmActive ? Colors.white : const Color(0xFF7C3AED);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () {
              _stopAllAlerts();
              Navigator.pop(context);
            },
          ),
          Text(
            'Detector Inteligente IA',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(width: 48), // Espaciador para centrar el título
        ],
      ),
    );
  }

  // Interfaz visual parpadeante durante la alarma de peligro
  Widget _buildAlarmUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icono gigante parpadeante de peligro
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_rounded,
            size: 80,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '¡PELIGRO DETECTADO!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            _activeAlarmType.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Botón físico para detener y reiniciar la alerta
        ElevatedButton.icon(
          onPressed: _stopAllAlerts,
          icon: const Icon(Icons.close_rounded, size: 28),
          label: const Text('DETENER ALERTA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 8,
          ),
        ),
      ],
    );
  }

  // Interfaz de monitoreo con la onda de sonido animada central y simulador de prueba
  Widget _buildSoundWaveUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        // Representación visual de las ondas de audio circulares expansivas
        Stack(
          alignment: Alignment.center,
          children: [
            // Ondas de sonido circulares concéntricas animadas
            for (int i = 1; i <= 3; i++)
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  double waveValue = (_waveController.value + (i * 0.33)) % 1.0;
                  double scale = 1.0 + (waveValue * (1.0 + _soundLevel * 1.5));
                  double opacity = (1.0 - waveValue) * 0.4;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7C3AED).withOpacity(opacity.clamp(0.0, 1.0)),
                      ),
                    ),
                  );
                },
              ),
            // Botón/Radar central morado del micrófono
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.online_prediction_rounded,
                color: Colors.white,
                size: 44,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Monitoreo Inteligente Activo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _lastWords,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
        ),

        const Spacer(),
        // Panel Premium de Simulación Manual (Fail-Safe para la demostración académica)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Simulación de Emergencias (Demostración)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
              ),
              itemCount: _soundCategories.length,
              itemBuilder: (context, index) {
                final cat = _soundCategories[index];
                return GestureDetector(
                  onTap: () => _triggerAlarm(cat['name'], isSimulated: true),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cat['color'].withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: cat['color'].withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat['icon'],
                              color: cat['color'],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cat['name'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1B4B),
                                  ),
                                ),
                                Text(
                                  cat['desc'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
