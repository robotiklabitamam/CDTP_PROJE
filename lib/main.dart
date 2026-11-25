import 'package:material_ui/material_ui.dart';

import 'ui/home_shell.dart';
import 'ui/theme.dart';

void main() {
  runApp(const CdtpApp());
}

class CdtpApp extends StatelessWidget {
  const CdtpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ÇDTP Robot',
      debugShowCheckedModeBanner: false,
      theme: buildYtuTheme(),
      home: const HomeShell(),
    );
  }
}
