import 'package:cdtp_robot_app/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    // iPhone 14/15 boyutu (390 x 844 pt).
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const CdtpApp());
    await tester.pump();
  }

  testWidgets('dört sekme gezilebiliyor ve her sayfada logo var', (tester) async {
    await pumpApp(tester);

    for (final tab in ['Kontrol', 'Test', 'Kayıtlar', 'Debug']) {
      await tester.tap(find.widgetWithText(NavigationDestination, tab));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.bySemanticsLabel('Yıldız Teknik Üniversitesi logosu'), findsWidgets);
    }
  });

  testWidgets('Kayıtlar sayfasında "Test yapılmadı" yazıyor', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Kayıtlar'));
    await tester.pump();
    expect(find.text('Test yapılmadı'), findsOneWidget);
  });

  testWidgets('Kontrol ve Test butonları basılınca hata vermiyor', (tester) async {
    await pumpApp(tester);
    for (final label in ['Cihaz Ara', 'Bağlan', 'İLERİ', 'DUR']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }

    await tester.tap(find.widgetWithText(NavigationDestination, 'Test'));
    await tester.pump();
    await tester.tap(find.text('B · Robot Yönlendirmesi'));
    await tester.pump();
    expect(find.text('Beklenen yön'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Testi Başlat'), 200);
    await tester.tap(find.text('Testi Başlat'));
    await tester.tap(find.text('Testi Bitir'));
    await tester.pump();
  });

  testWidgets('Debug sekmesi kamera olmayan ortamda mesaj gösteriyor', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Debug'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Platform kanalının (kamera eklentisi yok) cevabı gerçek zamanlı gelir.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
    expect(find.textContaining('Bu platformda kamera desteklenmiyor'), findsOneWidget);
    // Sekmeden çıkınca kamera ve zamanlayıcı kapanmalı.
    await tester.tap(find.widgetWithText(NavigationDestination, 'Kontrol'));
    await tester.pump();
  });
}
