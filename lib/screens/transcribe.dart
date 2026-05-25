
import 'package:flutter/material.dart';
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
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done') {
            setState(() {
              _isListening = false;
              _pulseController.stop();
              _pulseController.reset();
              _saveToHistory();
            });
          }
        },
        onError: (val) {
          setState(() {
            _isListening = false;
            _pulseController.stop();
            _pulseController.reset();
          });
        },
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          _text = ""; // clear previous text
          _pulseController.repeat();
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
          }),
          localeId: 'es_ES', // Can use system locale if preferred
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _pulseController.stop();
        _pulseController.reset();
      });
      _speech.stop();
      _saveToHistory();
    }
  }

  void _saveToHistory() {
    if (_text.trim().isNotEmpty) {
      final now = DateTime.now();
      String formattedDate = DateFormat('dd/MM HH:mm').format(now);
      
      StorageService.addHistoryItem(
        HistoryItem(
          id: now.millisecondsSinceEpoch,
          date: formattedDate,
          text: _text,
          type: 'Escuchado',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Modo Escucha',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7C3AED),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F3FF),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF7C3AED)),
                    onPressed: () {},
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
                                  style: const TextStyle(
                                    fontSize: 24,
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
                                    icon: const Icon(Icons.share, color: Colors.white),
                                    onPressed: () {},
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
                              fontSize: 18,
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
