import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state for UI representation
  bool _silentMode = false;
  bool _emergencyAlerts = true;
  bool _alertVibration = true;
  bool _saveHistory = true;
  
  String _volumeSpeaker = 'Alto';
  String _textSize = 'Grande';
  String _alertTone = 'Fuerte';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _silentMode = StorageService.getSettingBool('silent_mode', false);
      _emergencyAlerts = StorageService.getSettingBool('emergency_alerts', true);
      _alertVibration = StorageService.getSettingBool('alert_vibration', true);
      _saveHistory = StorageService.getSettingBool('save_history', true);

      _volumeSpeaker = StorageService.getSettingString('volume_speaker', 'Alto');
      _textSize = StorageService.getSettingString('text_size', 'Grande');
      _alertTone = StorageService.getSettingString('alert_tone', 'Fuerte');
    });
  }

  void _updateToggle(String key, bool value) {
    StorageService.setSettingBool(key, value);
    _loadSettings();
  }

  void _updateString(String key, String value) {
    StorageService.setSettingString(key, value);
    _loadSettings();
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
            width: double.infinity,
            child: const Text(
              'Configuración',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7C3AED),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F3FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'M',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'María Gómez',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Perfil Básico',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Settings Groups
                _buildSettingGroup(
                  'PREFERENCIAS DE AUDIO',
                  [
                    _buildSettingItem(icon: Icons.volume_up, label: 'Volumen del altavoz', value: _volumeSpeaker),
                    _buildSettingItem(
                      icon: Icons.dark_mode_outlined, 
                      label: 'Modo silencioso', 
                      isToggle: true, 
                      toggleActive: _silentMode,
                      onToggle: (val) => _updateToggle('silent_mode', val),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSettingGroup(
                  'APARIENCIA Y TEXTO',
                  [
                    _buildSettingItem(icon: Icons.text_fields, label: 'Tamaño de texto', value: _textSize),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSettingGroup(
                  'CONFIGURACIÓN DE ALERTAS',
                  [
                    _buildSettingItem(
                      icon: Icons.notifications_none, 
                      label: 'Alertas de emergencia', 
                      isToggle: true, 
                      toggleActive: _emergencyAlerts,
                      onToggle: (val) => _updateToggle('emergency_alerts', val),
                    ),
                    _buildSettingItem(icon: Icons.volume_up, label: 'Tono de alerta', value: _alertTone),
                    _buildSettingItem(
                      icon: Icons.vibration, 
                      label: 'Vibración en alertas', 
                      isToggle: true, 
                      toggleActive: _alertVibration,
                      onToggle: (val) => _updateToggle('alert_vibration', val),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                _buildSettingGroup(
                  'PRIVACIDAD',
                  [
                    _buildSettingItem(
                      icon: Icons.shield_outlined, 
                      label: 'Guardar historial de voz', 
                      isToggle: true, 
                      toggleActive: _saveHistory,
                      onToggle: (val) => _updateToggle('save_history', val),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Help Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {},
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.help_outline, color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Ayuda y Soporte',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSettingGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              int idx = entry.key;
              Widget item = entry.value;
              return Column(
                children: [
                  item,
                  if (idx != items.length - 1)
                    Divider(height: 1, color: Colors.grey.withOpacity(0.1), indent: 16, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String label,
    String? value,
    bool isToggle = false,
    bool toggleActive = false,
    Function(bool)? onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          if (isToggle)
            SizedBox(
              height: 24,
              child: Switch(
                value: toggleActive,
                onChanged: onToggle,
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF7C3AED),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey[300],
              ),
            )
          else if (value != null)
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
              ],
            ),
        ],
      ),
    );
  }
}
