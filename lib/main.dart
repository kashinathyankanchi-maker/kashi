import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/map_screen.dart';
import 'screens/network_screen.dart';
import 'screens/tdr_screen.dart';
import 'screens/sdr_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const SentinelApp(),
    ),
  );
}

class SentinelApp extends StatelessWidget {
  const SentinelApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentinel Forensic',
      theme: TacticalTheme.darkTheme,
      home: const MainShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({Key? key}) : super(key: key);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _activeTabIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MapScreen(),
    NetworkScreen(),
    TdrScreen(),
    SdrScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Auto load mock heist case on startup to populate views instantly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppState>(context, listen: false).loadMockCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: TacticalTheme.accentCyan),
            const SizedBox(width: 10),
            const Text("Sentinel Forensic"),
            if (isDesktop && state.selectedNumber != null) ...[
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.redAccent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("TARGET LOCK: ", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(state.selectedNumber!, style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => state.setSelectedNumber(null),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.folder_open_rounded, color: Colors.white70, size: 18),
            label: const Text("Load Heist", style: TextStyle(color: Colors.white70)),
            onPressed: () => state.loadMockCase(),
          ),
          const SizedBox(width: 10),
          TextButton.icon(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
            label: const Text("Reset", style: TextStyle(color: Colors.white70)),
            onPressed: () => state.clearCase(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar menu for desktop
          if (isDesktop)
            Container(
              width: 220,
              decoration: const BoxDecoration(
                color: TacticalTheme.bgSecondary,
                border: Border(right: BorderSide(color: Colors.white10)),
              ),
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  _buildSidebarItem(0, Icons.dashboard_rounded, "Dashboard"),
                  _buildSidebarItem(1, Icons.map_rounded, "Map Route View"),
                  _buildSidebarItem(2, Icons.hub_rounded, "Suspect Network"),
                  _buildSidebarItem(3, Icons.compare_arrows_rounded, "Tower Intersection"),
                  _buildSidebarItem(4, Icons.person_search_rounded, "SDR Registry"),
                ],
              ),
            ),

          // Main Screen Tab View
          Expanded(
            child: _screens[_activeTabIndex],
          ),
        ],
      ),
      // Bottom navigation bar for mobile
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _activeTabIndex,
              onTap: (idx) => setState(() => _activeTabIndex = idx),
              type: BottomNavigationBarType.fixed,
              backgroundColor: TacticalTheme.bgSecondary,
              selectedItemColor: TacticalTheme.accentCyan,
              unselectedItemColor: TacticalTheme.textMuted,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Dashboard"),
                BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: "Map Route"),
                BottomNavigationBarItem(icon: Icon(Icons.hub_rounded), label: "Network"),
                BottomNavigationBarItem(icon: Icon(Icons.compare_arrows_rounded), label: "TDR Overlap"),
                BottomNavigationBarItem(icon: Icon(Icons.person_search_rounded), label: "SDR Search"),
              ],
            )
          : null,
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isSelected = _activeTabIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: Icon(icon, color: isSelected ? TacticalTheme.accentCyan : TacticalTheme.textMuted),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : TacticalTheme.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.white10,
        onTap: () => setState(() => _activeTabIndex = index),
      ),
    );
  }
}
