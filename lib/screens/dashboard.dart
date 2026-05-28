import 'package:flutter/material.dart';
import 'detector.dart';
import 'transcribe.dart';
import 'speak.dart';
import '../services/storage_service.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;
  const DashboardScreen({super.key, this.onNavigateTab});

  void _showDeveloperInfo(BuildContext context) {
    final double scale = StorageService.getFontSizeMultiplier();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF7C3AED), width: 3),
                  image: const DecorationImage(
                    image: AssetImage('assets/image.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SpeakSee App 📱',
                style: TextStyle(
                  fontSize: 22 * scale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Herramienta Inteligente de Accesibilidad y Seguridad',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Materia:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14 * scale)),
                  Text('Interacción Humano-Máquina', style: TextStyle(color: Colors.grey[700], fontSize: 14 * scale)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estudiante:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14 * scale)),
                  Text('Alexxitoxx', style: TextStyle(color: Colors.grey[700], fontSize: 14 * scale)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Versión:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14 * scale)),
                  Text('v2.1.0-Premium', style: TextStyle(color: const Color(0xFFEC4899), fontWeight: FontWeight.bold, fontSize: 14 * scale)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotifications(BuildContext context) {
    final double scale = StorageService.getFontSizeMultiplier();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notificaciones 🔔',
                    style: TextStyle(
                      fontSize: 18 * scale,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'CONSEJOS DE ACCESIBILIDAD',
                style: TextStyle(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                Icons.lightbulb_outline,
                'Coloca tu teléfono con la pantalla hacia abajo para maximizar la visibilidad del parpadeo del flash en tu mesa.',
                const Color(0xFFF59E0B),
                scale,
              ),
              _buildNotificationItem(
                Icons.vibration,
                'Mantén el modo de vibración activado para percibir las alertas táctiles en tus bolsillos.',
                const Color(0xFF3B82F6),
                scale,
              ),
              const SizedBox(height: 16),
              Text(
                'ALERTAS RECIENTES',
                style: TextStyle(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                Icons.check_circle_outline,
                'Sistema de monitoreo de peligros listo y escuchando el entorno correctamente.',
                const Color(0xFF10B981),
                scale,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(IconData icon, String text, Color iconColor, double scale) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13 * scale,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double scale = StorageService.getFontSizeMultiplier();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showDeveloperInfo(context),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          radius: 26,
                          backgroundColor: Color(0xFFF5F3FF),
                          backgroundImage: AssetImage('assets/image.png'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, María',
                          style: TextStyle(
                            fontSize: 24 * scale,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                        Text(
                          '¿Cómo podemos ayudarte hoy?',
                          style: TextStyle(
                            fontSize: 14 * scale,
                            color: const Color(0xB37C3AED), // 70% opacity
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showNotifications(context),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_none,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            Row(
              children: [
                           // Listen Card
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(1); // Navigate to Escuchar tab
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TranscribeScreen()),
                        );
                      }
                    },
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -32,
                            right: -32,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                  ),
                                ),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Escuchar',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Voz a texto en vivo',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Speak Card
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (onNavigateTab != null) {
                        onNavigateTab!(2); // Navigate to Hablar tab
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SpeakScreen()),
                        );
                      }
                    },
                    child: Container(
                      height: 160,
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
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF5F3FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hablar',
                                  style: TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Texto a voz',
                                  style: TextStyle(
                                    color: Color(0x997C3AED), // 60% opacity
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
 
            // Detector de Peligros Card (Full Width)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DetectorScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -16,
                      right: -16,
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.radar_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Detector de Peligros',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Alerta sísmica, ambulancias, patrullas y claxon',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
