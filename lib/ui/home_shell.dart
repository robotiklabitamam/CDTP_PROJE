import 'package:material_ui/material_ui.dart';

import '../demo/demo_telemetry.dart';
import 'pages/control_page.dart';
import 'pages/debug_page.dart';
import 'pages/records_page.dart';
import 'pages/test_page.dart';
import 'theme.dart';
import 'widgets/status_bar.dart';
import 'widgets/ytu_logo.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _debugTab = 3;

  static const _tabs = [
    (title: 'Kontrol', icon: Icons.gamepad_outlined, selected: Icons.gamepad_rounded),
    (title: 'Test', icon: Icons.fact_check_outlined, selected: Icons.fact_check_rounded),
    (title: 'Kayıtlar', icon: Icons.video_library_outlined, selected: Icons.video_library_rounded),
    (title: 'Debug', icon: Icons.bug_report_outlined, selected: Icons.bug_report_rounded),
  ];

  final DemoTelemetry _telemetry = DemoTelemetry()..start();
  int _index = 0;

  @override
  void dispose() {
    _telemetry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: [
            const YtuLogo(size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tabs[_index].title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'ÇDTP · Hasta Destek Robotu',
                    style: TextStyle(fontSize: 12, color: YtuColors.gold, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: StatusBar(telemetry: _telemetry),
      ),
      body: IndexedStack(
        index: _index,
        children: [
          const ControlPage(),
          const TestPage(),
          const RecordsPage(),
          DebugPage(active: _index == _debugTab, telemetry: _telemetry),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selected),
              label: tab.title,
            ),
        ],
      ),
    );
  }
}
