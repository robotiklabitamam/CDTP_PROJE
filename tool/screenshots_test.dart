// Telefon/emülatör olmadan tasarımı görmek için ekran görüntüsü üretir.
//
//   flutter test tool/screenshots_test.dart
//
// Çıktılar: docs/screenshots/*.png (390 x 844 pt, iPhone boyutu).
// Not: Kamera bu ortamda olmadığı için Debug sekmesi "desteklenmiyor" durumunu gösterir.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cdtp_robot_app/main.dart';
import 'package:cdtp_robot_app/ui/widgets/ytu_logo.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Future<void> _loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(await File('$dir/$f').readAsBytes());

  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
    roboto.addFont(read('Roboto-$w.ttf'));
  }
  await roboto.load();
  await (FontLoader('MaterialIcons')..addFont(read('MaterialIcons-Regular.otf'))).load();
}

void main() {
  final boundary = GlobalKey();

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.pump(const Duration(milliseconds: 400));
    final ro = boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await ro.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('docs/screenshots/$name.png');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  // ListView çocukları tembel ölçtüğü için en sona birkaç adımda inilir.
  Future<void> scrollToEnd(WidgetTester tester) async {
    final pos = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    for (var i = 0; i < 5 && pos.pixels != pos.maxScrollExtent; i++) {
      pos.jumpTo(pos.maxScrollExtent);
      await tester.pump();
    }
  }

  Future<void> openTab(WidgetTester tester, String tab) async {
    await tester.tap(find.widgetWithText(NavigationDestination, tab));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('ekran görüntüleri', (tester) async {
    await tester.runAsync(_loadFonts);
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(RepaintBoundary(key: boundary, child: const CdtpApp()));
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(Scaffold).first);
      await precacheImage(const AssetImage(ytuLogoAsset), ctx);
    });

    await openTab(tester, 'Kontrol');
    await shoot(tester, '1_kontrol');

    await openTab(tester, 'Test');
    await shoot(tester, '2_test_ust');
    await scrollToEnd(tester);
    await shoot(tester, '2_test_alt');

    await openTab(tester, 'Kayıtlar');
    await shoot(tester, '3_kayitlar');

    await openTab(tester, 'Debug');
    await shoot(tester, '4_debug');
    await scrollToEnd(tester);
    await shoot(tester, '4_debug_alt');

    await openTab(tester, 'Kontrol');
  });
}
