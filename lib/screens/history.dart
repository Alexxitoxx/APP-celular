import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _historyItems = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyItems = StorageService.getHistory();
    });
  }

  void _clearAll() async {
    await StorageService.clearHistory();
    _loadHistory();
  }

  void _deleteItem(int id) async {
    await StorageService.deleteHistoryItem(id);
    _loadHistory();
  }

  void _copyItemText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text('¡Transcripción copiada al portapapeles! 📋'),
          ],
        ),
        backgroundColor: Color(0xFF7C3AED),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double scale = StorageService.getFontSizeMultiplier();
    List<HistoryItem> filteredItems = _historyItems.where((item) {
      return item.text.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             item.date.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Historial',
                  style: TextStyle(
                    fontSize: 20 * scale,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Buscar en el historial...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _historyItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'El historial está vacío',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TRANSCRIPCIONES RECIENTES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearAll,
                          child: const Text(
                            'Limpiar todo',
                            style: TextStyle(
                              color: Color(0xFFEC4899),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    ...filteredItems.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.withOpacity(0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [                                 Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 14, color: Colors.grey[400]),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.date,
                                          style: TextStyle(
                                            fontSize: 12 * scale,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item.type == "Escuchado" 
                                            ? const Color(0xFFF5F3FF) 
                                            : const Color(0xFFFDF2F8), // pink-50 approx
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        item.type,
                                        style: TextStyle(
                                          fontSize: 10 * scale,
                                          fontWeight: FontWeight.bold,
                                          color: item.type == "Escuchado" 
                                              ? const Color(0xFF7C3AED) 
                                              : const Color(0xFFEC4899),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '"${item.text}"',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14 * scale,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: Color(0xFFF5F3FF), thickness: 1),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.copy, size: 18, color: Colors.grey[400]),
                                        onPressed: () => _copyItemText(item.text),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        shape: BoxShape.circle,
                                      ),
                                      child: IconButton(
                                        icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey[400]),
                                        onPressed: () => _deleteItem(item.id),
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}
