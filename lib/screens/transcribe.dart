
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/storage_service.dart';
import 'package:intl/intl.dart';

class TranscribeScreen extends StatefulWidget {
  const TranscribeScreen({super.key});

  @override
  State<TranscribeScreen> createState() => _TranscribeScreenState();
}

class _TranscribeScreenState extends State<TranscribeScreen> with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = "";
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _savedThisSession = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      _savedThisSession = false;
      bool available = await _speech.initialize(
        onStatus: (val) {
          debugPrint("[SpeechToText] Estado recibido: $val");
          if (val == 'done' || val == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
                _pulseController.stop();
                _pulseController.reset();
              });
              _saveToHistory();
            }
          }
        },
        onError: (val) {
          debugPrint("[SpeechToText] Error recibido: $val");
          if (mounted) {
            setState(() {
              _isListening = false;
              _pulseController.stop();
              _pulseController.reset();
            });
          }
        },
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          _text = ""; // clear previous text
          _pulseController.repeat();
        });
        
        String locale = StorageService.getSettingString('selected_language', 'es_MX');
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
          }),
          localeId: locale,
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _isListening = false;
          _pulseController.stop();
          _pulseController.reset();
        });
      }
      _speech.stop();
      _saveToHistory();
    }
  }

  void _saveToHistory() {
    if (!_savedThisSession && _text.trim().isNotEmpty) {
      _savedThisSession = true;
      final now = DateTime.now();
      String formattedDate = DateFormat('dd/MM HH:mm').format(now);
      
      StorageService.addHistoryItem(
        HistoryItem(
          id: now.millisecondsSinceEpoch,
          date: formattedDate,
          text: _text.trim(),
          type: 'Escuchado',
        ),
      );
      debugPrint("[SpeechToText] Grabado exitosamente en historial: $_text");
    }
  }

  void _showLanguageSelector() {
    final double scale = StorageService.getFontSizeMultiplier();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String currentLocale = StorageService.getSettingString('selected_language', 'es_MX');
        final Map<String, String> languages = {
          'es_MX': 'Español (México) 🇲🇽',
          'es_ES': 'Español (España) 🇪🇸',
          'en_US': 'Inglés (Estados Unidos) 🇺🇸',
        };
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Idioma del Dictado 🌐',
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 16),
              ...languages.entries.map((entry) {
                bool isSelected = entry.key == currentLocale;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF7C3AED) : Colors.black87,
                    ),
                  ),
                  trailing: isSelected 
                      ? const Icon(Icons.check_circle, color: Color(0xFF7C3AED)) 
                      : null,
                  onTap: () {
                    StorageService.setSettingString('selected_language', entry.key);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Idioma cambiado a ${entry.value}')),
                    );
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _copyToClipboard() {
    if (_text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('¡Texto copiado al portapapeles! 📋'),
            ],
          ),
          backgroundColor: Color(0xFF7C3AED),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  'Modo Escucha',
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
                    icon: const Icon(Icons.tune, color: Color(0xFF7C3AED)),
                    onPressed: _showLanguageSelector,
                  ),
                )
              ],
            ),
          ),
          
          // Main content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                child: _text.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: RichText(
                                text: TextSpan(
                                  text: _text,
                                  style: TextStyle(
                                    fontSize: 24 * scale,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (!_isListening)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                    onPressed: () => setState(() => _text = ""),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED).withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.copy, color: Colors.white),
                                    onPressed: _copyToClipboard,
                                  ),
                                ),
                              ],
                            )
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.mic,
                            size: 48,
                            color: const Color(0xFF7C3AED).withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isListening ? 'Escuchando...' : 'Presiona el botón para comenzar',
                            style: TextStyle(
                              fontSize: 18 * scale,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7C3AED).withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          
          // Pulsing Button
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_isListening) ...[
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEC4899).withOpacity(
                                (((1 - (_pulseAnimation.value - 1)) > 0 ? (1 - (_pulseAnimation.value - 1)) : 0).clamp(0.0, 1.0)).toDouble()
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1 + (_pulseAnimation.value - 1) * 1.5,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEC4899).withOpacity(
                                (((1 - (_pulseAnimation.value - 1)) * 0.5 > 0 ? (1 - (_pulseAnimation.value - 1)) * 0.5 : 0).clamp(0.0, 1.0)).toDouble()
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
                GestureDetector(
                  onTap: _listen,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? const Color(0xFFEC4899) : const Color(0xFF7C3AED),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? const Color(0xFFEC4899) : const Color(0xFF7C3AED)).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
