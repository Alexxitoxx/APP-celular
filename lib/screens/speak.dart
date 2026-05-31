import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class SpeakScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHistory;
  const SpeakScreen({super.key, this.onNavigateToHistory});

  @override
  State<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends State<SpeakScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isPlaying = false;
  late AnimationController _pulseController;

  final List<String> _quickPhrases = [
    "Hola, ¿cómo estás?",
    "Gracias",
    "Por favor",
    "Necesito ayuda",
    "¿Dónde está el baño?",
    "Soy sordo, por favor lee esto",
  ];

  @override
  void initState() {
    super.initState();
    _initTts();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _textController.addListener(() {
      setState(() {});
    });
  }
  
  void _initTts() async {
    String selectedLang = StorageService.getSettingString('selected_language', 'es_MX');
    String ttsLang = selectedLang.replaceAll('_', '-');
    debugPrint("[TTS Init] Configurando idioma inicial: $ttsLang");
    await _flutterTts.setLanguage(ttsLang);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = true;
          _pulseController.repeat(reverse: true);
        });
      }
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _pulseController.stop();
          _pulseController.reset();
        });
      }
    });

    _flutterTts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _pulseController.stop();
          _pulseController.reset();
        });
      }
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePlay() async {
    debugPrint("[TTS] _handlePlay invocado. Texto actual: '${_textController.text}'");
    if (_textController.text.isEmpty) {
      debugPrint("[TTS] El texto está vacío, cancelando speak.");
      return;
    }
    
    // Check settings for volume/silent mode
    bool isSilent = StorageService.getSettingBool('silent_mode', false);
    debugPrint("[TTS] Modo silencioso: $isSilent");
    if (isSilent) {
      debugPrint("[TTS] Modo silencioso activo, omitiendo habla.");
      return;
    }

    // Dynamically fetch and apply the configured speaker volume
    String volumeSetting = StorageService.getSettingString('volume_speaker', 'Alto');
    double volume = 1.0;
    if (volumeSetting == 'Bajo') volume = 0.3;
    if (volumeSetting == 'Medio') volume = 0.6;
    if (volumeSetting == 'Alto') volume = 1.0;
    debugPrint("[TTS] Volumen aplicado: $volumeSetting ($volume)");
    await _flutterTts.setVolume(volume);
    
    String selectedLang = StorageService.getSettingString('selected_language', 'es_MX');
    String ttsLang = selectedLang.replaceAll('_', '-');
    debugPrint("[TTS] Idioma dinámico aplicado para speak: $ttsLang");
    await _flutterTts.setLanguage(ttsLang);
    
    try {
      debugPrint("[TTS] Ejecutando _flutterTts.speak...");
      var result = await _flutterTts.speak(_textController.text);
      debugPrint("[TTS] Resultado de speak: $result");
    } catch (e) {
      debugPrint("[TTS] Excepción en speak: $e");
    }
    _saveToHistory(); // Optionally save when speaking
  }
  
  void _saveToHistory() {
    if (_textController.text.trim().isNotEmpty) {
      final now = DateTime.now();
      String formattedDate = DateFormat('dd/MM HH:mm').format(now);
      
      StorageService.addHistoryItem(
        HistoryItem(
          id: now.millisecondsSinceEpoch,
          date: formattedDate,
          text: _textController.text.trim(),
          type: 'Hablado',
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardado en el historial')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _textController.text.isNotEmpty;
    final double scale = StorageService.getFontSizeMultiplier();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Texto a Voz',
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F3FF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.history, color: Color(0xFF7C3AED)),
                    onPressed: widget.onNavigateToHistory,
                  ),
                )
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Area
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        TextField(
                          controller: _textController,
                          maxLines: 6,
                          minLines: 6,
                          style: TextStyle(
                            fontSize: 24 * scale,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Escribe aquí para hablar...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(24),
                          ),
                        ),
                        if (hasText)
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: () {
                                _textController.clear();
                                _flutterTts.stop();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextButton.icon(
                          onPressed: hasText ? _saveToHistory : null,
                          icon: Icon(Icons.save_outlined, color: hasText ? const Color(0xFF7C3AED) : Colors.grey, size: 18),
                          label: Text(
                            'Guardar',
                            style: TextStyle(
                              color: hasText ? Colors.black87 : Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      
                      GestureDetector(
                        onTap: hasText ? _handlePlay : null,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isPlaying ? 1.0 + (_pulseController.value * 0.1) : 1.0,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: hasText ? const Color(0xFF7C3AED) : Colors.grey[300],
                              shape: BoxShape.circle,
                              boxShadow: hasText
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED).withOpacity(0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.volume_up : Icons.play_arrow,
                              color: hasText ? Colors.white : Colors.grey[500],
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Quick Phrases
                  const Text(
                    'FRASES RÁPIDAS',
                    style: TextStyle(
                      color: Color(0xFF7C3AED),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _quickPhrases.map((phrase) {
                      return GestureDetector(
                        onTap: () {
                          _textController.text = phrase;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.2)),
                          ),
                          child: Text(
                            phrase,
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
