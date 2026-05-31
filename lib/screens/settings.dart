import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../widgets/avatar_helper.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onSettingsChanged;
  const SettingsScreen({super.key, this.onSettingsChanged});

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

  String _firstName = 'María';
  String _lastName = 'Gómez';
  String _userAvatarEmoji = '👩‍🦰';
  String _userAvatarUrl = '';
  String _userAvatarImagePath = '';

  String get _userName => '$_firstName $_lastName';

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

      _firstName = StorageService.getSettingString('user_first_name', 'María');
      _lastName = StorageService.getSettingString('user_last_name', 'Gómez');
      _userAvatarEmoji = StorageService.getSettingString('user_avatar_emoji', '👩‍🦰');
      _userAvatarUrl = StorageService.getSettingString('user_avatar_url', '');
      _userAvatarImagePath = StorageService.getSettingString('user_avatar_image_path', '');
    });
  }

  void _updateToggle(String key, bool value) {
    StorageService.setSettingBool(key, value);
    _loadSettings();
    if (widget.onSettingsChanged != null) {
      widget.onSettingsChanged!();
    }
  }

  void _updateString(String key, String value) {
    StorageService.setSettingString(key, value);
    _loadSettings();
    if (widget.onSettingsChanged != null) {
      widget.onSettingsChanged!();
    }
  }

  void _showEditProfileModal() {
    final double scale = StorageService.getFontSizeMultiplier();
    final TextEditingController firstCtrl = TextEditingController(text: _firstName);
    final TextEditingController lastCtrl = TextEditingController(text: _lastName);
    final TextEditingController urlCtrl = TextEditingController(text: _userAvatarUrl);
    String selectedEmoji = _userAvatarEmoji;
    String pickedImagePath = _userAvatarImagePath;
    
    // Preset emojis list (24 items)
    final List<String> presetEmojis = [
      '👩‍🦰', '👨‍🦱', '👱‍♀️', '👨‍💼', '👩‍⚕️', '🦁', '🐼', '🦊',
      '🐱', '👾', '🚀', '🎨', '🐶', '🦄', '🐳', '🍀',
      '🍕', '🎸', '🎮', '❤️', '👑', '🌈', '🥑', '🕶️'
    ];

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickImage(ImageSource source) async {
              try {
                final ImagePicker picker = ImagePicker();
                final XFile? image = await picker.pickImage(source: source);
                if (image != null) {
                  setModalState(() {
                    pickedImagePath = image.path;
                    urlCtrl.clear(); // Clear custom image URL if file picked
                  });
                }
              } catch (e) {
                debugPrint("Error picking image: $e");
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Editar Perfil 👤',
                          style: TextStyle(
                            fontSize: 20 * scale,
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
                    
                    // Name Field
                    Text(
                      'Nombre(s)',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: firstCtrl,
                      decoration: InputDecoration(
                        hintText: 'Tu nombre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F3FF),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lastname Field
                    Text(
                      'Apellido(s)',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: lastCtrl,
                      decoration: InputDecoration(
                        hintText: 'Tu apellido',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F3FF),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Camera / Gallery picker buttons
                    Text(
                      'Foto desde Cámara o Galería',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: Text('Cámara', style: TextStyle(fontSize: 13 * scale)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F3FF),
                              foregroundColor: const Color(0xFF7C3AED),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFFE9D5FF)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: Text('Galería', style: TextStyle(fontSize: 13 * scale)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F3FF),
                              foregroundColor: const Color(0xFF7C3AED),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFFE9D5FF)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (pickedImagePath.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: FileImage(File(pickedImagePath)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '¡Foto cargada de local!',
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13 * scale),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              setModalState(() {
                                pickedImagePath = '';
                              });
                            },
                          )
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                    
                    // Preset Emojis Selection
                    Text(
                      'O elige un Avatar (Emoji)',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: presetEmojis.length,
                        itemBuilder: (context, index) {
                          final emoji = presetEmojis[index];
                          bool isSel = emoji == selectedEmoji && urlCtrl.text.isEmpty && pickedImagePath.isEmpty;
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                selectedEmoji = emoji;
                                urlCtrl.clear(); // Clear custom image URL
                                pickedImagePath = ''; // Clear picked image path
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isSel ? const Color(0xFFF5F3FF) : Colors.white,
                                border: Border.all(
                                  color: isSel ? const Color(0xFF7C3AED) : Colors.grey.withOpacity(0.1),
                                  width: isSel ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Custom Image URL Field
                    Text(
                      'O usa una URL de foto de perfil',
                      style: TextStyle(
                        fontSize: 14 * scale,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: urlCtrl,
                      onChanged: (val) {
                        if (val.trim().isNotEmpty) {
                          setModalState(() {
                            pickedImagePath = ''; // Clear local path if URL entered
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'https://ejemplo.com/foto.jpg',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F3FF),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (firstCtrl.text.trim().isNotEmpty) {
                            await StorageService.setSettingString('user_first_name', firstCtrl.text.trim());
                            await StorageService.setSettingString('user_last_name', lastCtrl.text.trim());
                            await StorageService.setSettingString('user_name', '${firstCtrl.text.trim()} ${lastCtrl.text.trim()}');
                            await StorageService.setSettingString('user_avatar_emoji', selectedEmoji);
                            await StorageService.setSettingString('user_avatar_url', urlCtrl.text.trim());
                            await StorageService.setSettingString('user_avatar_image_path', pickedImagePath);
                            _loadSettings();
                            if (widget.onSettingsChanged != null) {
                              widget.onSettingsChanged!();
                            }
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('¡Perfil actualizado con éxito! 🎉'),
                                  backgroundColor: Color(0xFF7C3AED),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 16 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
            width: double.infinity,
            child: Text(
              'Configuración',
              style: TextStyle(
                fontSize: 20 * scale,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Profile Card
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _showEditProfileModal,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            buildAvatarWidget(
                              emoji: _userAvatarEmoji,
                              url: _userAvatarUrl,
                              imagePath: _userAvatarImagePath,
                              size: 64,
                              emojiSize: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userName,
                                    style: TextStyle(
                                      fontSize: 18 * scale,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Perfil Básico',
                                        style: TextStyle(
                                          fontSize: 14 * scale,
                                          color: const Color(0xFF7C3AED),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.edit, size: 14, color: const Color(0xFF7C3AED).withOpacity(0.6)),
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
                ),
                const SizedBox(height: 32),
                
                // Settings Groups
                _buildSettingGroup(
                  'PREFERENCIAS DE AUDIO',
                  [
                    _buildSettingItem(
                      icon: Icons.volume_up, 
                      label: 'Volumen del altavoz', 
                      value: _volumeSpeaker,
                      onTap: () => _showOptionsModal(
                        'volume_speaker', 
                        'Volumen del altavoz 🔊', 
                        ['Bajo', 'Medio', 'Alto'],
                      ),
                    ),
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
                    _buildSettingItem(
                      icon: Icons.text_fields, 
                      label: 'Tamaño de texto', 
                      value: _textSize,
                      onTap: () => _showOptionsModal(
                        'text_size', 
                        'Tamaño de texto 🔠', 
                        ['Pequeño', 'Mediano', 'Grande'],
                      ),
                    ),
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
                    _buildSettingItem(
                      icon: Icons.volume_up, 
                      label: 'Tono de alerta', 
                      value: _alertTone,
                      onTap: () => _showOptionsModal(
                        'alert_tone', 
                        'Tono de alerta 🔔', 
                        ['Suave', 'Medio', 'Fuerte'],
                      ),
                    ),
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
                      onTap: _showHelpModal,
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

  void _showOptionsModal(String key, String title, List<String> options) {
    final double scale = StorageService.getFontSizeMultiplier();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String currentValue = StorageService.getSettingString(key, options[0]);
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF7C3AED),
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                bool isSelected = opt == currentValue;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    opt,
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
                    _updateString(key, opt);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  void _showHelpModal() {
    final double scale = StorageService.getFontSizeMultiplier();
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ayuda y Soporte 📖',
                      style: TextStyle(
                        fontSize: 20 * scale,
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
                _buildHelpItem(
                  '¿Cómo funciona el Detector de Peligros?',
                  'Monitorea el entorno mediante el micrófono local. Si se detecta un ruido muy fuerte (decibelios altos) o palabras clave de emergencia como "sismo", "ambulancia" o "patrulla", la aplicación disparará alertas de inmediato.',
                ),
                _buildHelpItem(
                  '¿Qué tipo de alertas genera?',
                  'Genera una secuencia estroboscópica brillante en la pantalla (rojo y amarillo), parpadea el flash de la cámara trasera de forma ultra-rápida y emite una vibración continua de alta intensidad para alertar al usuario táctil y visualmente.',
                ),
                _buildHelpItem(
                  '¿Funciona sin conexión a Internet?',
                  '¡Sí! Tanto el reconocimiento de voz del dictado como el detector de peligros operan de forma local en el dispositivo físico, garantizando que el usuario esté protegido incluso si no hay datos móviles o señal celular.',
                ),
                _buildHelpItem(
                  'Información del Proyecto',
                  'Desarrollado para el proyecto académico de la materia de Interacción Humano-Máquina.\n\nIntegrantes del Equipo:\n• Rodríguez Femat Emilio Emanuel\n• Valdez Garcia Paola Sarai\n• Zuluaga Santillan Alejandro',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpItem(String title, String content) {
    final double scale = StorageService.getFontSizeMultiplier();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16 * scale,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 14 * scale,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.withOpacity(0.1)),
        ],
      ),
    );
  }

  Widget _buildSettingGroup(String title, List<Widget> items) {
    final double scale = StorageService.getFontSizeMultiplier();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12 * scale,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
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
    VoidCallback? onTap,
  }) {
    final double scale = StorageService.getFontSizeMultiplier();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isToggle ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(width: 12),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14 * scale,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
