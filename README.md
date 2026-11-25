# ÇDTP Robot — Mobil Değerlendirme Uygulaması

YTÜ EEF ÇDTP "İki Tekerlekli Ev İçi Hasta Destek Robotu" projesinin mobil uygulaması (Flutter, hedef: iPhone).
Tam spesifikasyon: [`uygulama.md`](uygulama.md).

## Durum: tasarım aşaması

| Sekme | Şu an |
|---|---|
| Kontrol | BLE bağlantı kartı, yön tuşları ve DUR. Butonlar henüz bir şey yapmıyor. |
| Test | Görev seçimi, kamera alanı, sayaç, ön kontrol listesi. Butonlar henüz bir şey yapmıyor. |
| Kayıtlar | "Test yapılmadı" boş durumu. |
| Debug (geçici) | Telefon kamerasını açar. Telemetri ve görüntü işleme değerleri sahte/rastgele. |

Üst çubuktaki eğim/şarj değerleri `lib/demo/demo_telemetry.dart` içindeki **sahte** kaynaktan gelir ("SİM" rozeti).

## Komutlar

```bash
flutter analyze
flutter test
flutter test tool/screenshots_test.dart   # docs/screenshots/*.png tasarım görüntülerini üretir
```

## Klasörler

```
lib/
  demo/        tasarım aşaması için sahte telemetri (adım 5'te RobotLink ile değişecek)
  ui/          theme.dart (YTÜ renkleri), home_shell.dart, pages/, widgets/
assets/images/ ytu_logo.webp
```
