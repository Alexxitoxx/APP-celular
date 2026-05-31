import 'package:flutter/material.dart';
import 'dart:async';
import 'package:tflite_audio/tflite_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/detector.dart';
import 'screens/dashboard.dart';
import 'screens/transcribe.dart';
import 'screens/speak.dart';
import 'screens/history.dart';
import 'screens/settings.dart';

import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpeakSee',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C3AED),
          primary: const Color(0xFF7C3AED),
          secondary: const Color(0xFFEC4899),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F3FF),
        useMaterial3: true,
        fontFamily: 'Inter', // Assuming standard font if they add it later, defaults to sans-serif otherwise
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  StreamSubscription<Map<dynamic, dynamic>>? _bgSubscription;
  bool _isBgListening = false;
  bool _isDetectorScreenOpen = false;
  bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Iniciar escucha acústica continua en segundo plano
    _initBgDetection();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopBgListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      debugPrint("[IA Segundo Plano] App en segundo plano. Deteniendo escucha.");
      _stopBgListening();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint("[IA Segundo Plano] App en primer plano. Reactivando escucha.");
      if (_selectedIndex != 1 && _selectedIndex != 2) { // Reactivar solo si no estamos en la pestaña "Escuchar" ni "Hablar"
        _startBgListeningDelayed();
      }
    }
  }

  void _initBgDetection() async {
    try {
      debugPrint("[IA Segundo Plano] Solicitando permisos de micrófono...");
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
      }
      if (!status.isGranted) {
        debugPrint("[IA Segundo Plano] Permiso de micrófono denegado.");
        return;
      }

      debugPrint("[IA Segundo Plano] Cargando modelo TFLite de audio...");
      await TfliteAudio.loadModel(
        model: 'assets/soundclassifier_with_metadata.tflite',
        label: 'assets/labels.txt',
        numThreads: 1,
        isAsset: true,
        inputType: 'rawAudio',
      );
      debugPrint("[IA Segundo Plano] Modelo cargado con éxito en memoria.");
      _isModelLoaded = true;
      
      if (_selectedIndex != 1 && _selectedIndex != 2) {
        _startBgListeningDelayed();
      }
    } catch (e) {
      debugPrint("[IA Segundo Plano] Error al inicializar: $e");
    }
  }

  void _startBgListeningDelayed() {
    // Retraso de seguridad para permitir que el hardware libere sesiones previas
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _startBgListening();
    });
  }

  void _startBgListening() {
    if (!_isModelLoaded || _isBgListening || _isDetectorScreenOpen || _bgSubscription != null || _selectedIndex == 1 || _selectedIndex == 2) return;

    try {
      debugPrint("[IA Segundo Plano] Iniciando flujo de escucha continua...");
      final recognitionStream = TfliteAudio.startAudioRecognition(
        sampleRate: 44100,
        audioLength: 44032,
        bufferSize: 22016,
        numOfInferences: 100000,
        detectionThreshold: 0.75, // Aumentar confianza a 75% para evitar falsas alarmas sismicas en segundo plano
      );

      if (mounted) {
        setState(() {
          _isBgListening = true;
        });
      }

      _bgSubscription = recognitionStream.listen(
        (event) {
          if (!mounted || _isDetectorScreenOpen || _selectedIndex == 1) return;
          if (!StorageService.getSettingBool('emergency_alerts', true)) return;

          String result = event["recognitionResult"] ?? "";
          debugPrint("[IA Segundo Plano] Inferencia: $result");

          if (result.contains("Alerta sismica") || result.contains("Alerta sísmica") || result.contains("Ambulancia") || result.contains("Ambulancias") || result.contains("Patrulla") || result.contains("Claxon")) {
            _triggerGlobalAlarm(result);
          }
        },
        onError: (err) {
          debugPrint("[IA Segundo Plano] Error en stream: $err");
          _stopBgListening();
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _startBgListeningDelayed();
          });
        },
        onDone: () {
          debugPrint("[IA Segundo Plano] Stream completado");
          _stopBgListening();
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (mounted) _startBgListeningDelayed();
          });
        },
      );
    } catch (e) {
      debugPrint("[IA Segundo Plano] Falló inicio de escucha: $e");
    }
  }

  void _stopBgListening() {
    _bgSubscription?.cancel();
    _bgSubscription = null;
    try {
      TfliteAudio.stopAudioRecognition();
      debugPrint("[IA Segundo Plano] TfliteAudio.stopAudioRecognition() llamado con éxito.");
    } catch (e) {
      debugPrint("[IA Segundo Plano] Error al llamar stopAudioRecognition: $e");
    }
    if (mounted) {
      setState(() {
        _isBgListening = false;
      });
    }
    debugPrint("[IA Segundo Plano] Escucha detenida.");
  }

  void _openDetectorManually() {
    debugPrint("[IA Segundo Plano] Abriendo detector manualmente, pausando escucha de fondo...");
    _isDetectorScreenOpen = true;
    _stopBgListening();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DetectorScreen(),
      ),
    ).then((_) {
      debugPrint("[IA Segundo Plano] Detector manual cerrado, reanudando escucha de fondo...");
      _isDetectorScreenOpen = false;
      _startBgListeningDelayed();
    });
  }

  void _triggerGlobalAlarm(String result) {
    String alarmType = 'Alerta de Emergencia 🚨';
    if (result.contains("Alerta sismica") || result.contains("Alerta sísmica")) {
      alarmType = 'Alerta Sísmica 🚨';
    } else if (result.contains("Ambulancia") || result.contains("Ambulancias")) {
      alarmType = 'Ambulancia 🚑';
    } else if (result.contains("Patrulla")) {
      alarmType = 'Patrulla 🚓';
    } else if (result.contains("Claxon")) {
      alarmType = 'Claxon de Auto 🔊';
    }

    debugPrint("[IA Segundo Plano] ¡ALARMA DETECTADA! Disparando pantalla global de alerta: $alarmType");
    _isDetectorScreenOpen = true;
    _stopBgListening();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetectorScreen(
          triggerEmergencyOnInit: true,
          initialAlarmType: alarmType,
        ),
      ),
    ).then((_) {
      debugPrint("[IA Segundo Plano] Pantalla de alerta cerrada, reanudando escucha de fondo...");
      _isDetectorScreenOpen = false;
      _startBgListeningDelayed();
    });
  }

  List<Widget> get _pages => [
    DashboardScreen(
      onNavigateTab: _onItemTapped,
      onOpenDetector: _openDetectorManually,
    ),
    const TranscribeScreen(),
    SpeakScreen(onNavigateToHistory: () => _onItemTapped(3)),
    const HistoryScreen(),
    SettingsScreen(onSettingsChanged: () {
      setState(() {});
    }),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1 || index == 2) {
      // Pestaña "Escuchar" (Dictado) o "Hablar" (TTS) - Detener la escucha de fondo para liberar el hardware del micrófono y bocina
      debugPrint("[IA Segundo Plano] Cambiado a pestaña $index. Deteniendo detector para liberar audio.");
      _stopBgListening();
    } else {
      // Regreso a Inicio, Historial o Ajustes - Reactivar la escucha en segundo plano
      debugPrint("[IA Segundo Plano] Cambiado a pestaña $index. Reactivando detector.");
      _startBgListeningDelayed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: const Color(0xFF7C3AED),
              unselectedItemColor: const Color(0xFF7C3AED).withOpacity(0.4),
              selectedFontSize: 10,
              unselectedFontSize: 10,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Inicio',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.mic_none),
                  activeIcon: Icon(Icons.mic),
                  label: 'Escuchar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  activeIcon: Icon(Icons.chat_bubble),
                  label: 'Hablar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  activeIcon: Icon(Icons.history),
                  label: 'Historial',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
