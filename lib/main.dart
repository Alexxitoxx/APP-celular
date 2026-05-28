import 'package:flutter/material.dart';
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

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    DashboardScreen(onNavigateTab: _onItemTapped),
    const TranscribeScreen(),
    SpeakScreen(onNavigateToHistory: () => _onItemTapped(3)),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
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
    );
  }
}
