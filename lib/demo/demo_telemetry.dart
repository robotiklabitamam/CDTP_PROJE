import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

enum LinkStatus { connected, searching, disconnected }

/// Tasarım aşaması için sahte telemetri kaynağı (1 Hz).
///
/// TODO(robot): Adım 5'te README 4.2'deki `RobotLink` / `FakeRobotLink`
/// ile değiştirilecek. Buradaki değerlerin hiçbiri gerçek ölçüm değildir.
class DemoTelemetry extends ChangeNotifier {
  DemoTelemetry({Random? random}) : _rng = random ?? Random();

  final Random _rng;
  final Stopwatch _clock = Stopwatch();
  Timer? _timer;

  LinkStatus link = LinkStatus.connected;
  final bool simulated = true;

  int seq = 0;
  int batteryPct = 78;
  bool charging = false;
  double tiltDeg = 0;
  int batteryMv = 0;
  int robotMs = 0;
  Duration? _lastPacketAt;

  /// Son telemetri 2 s'den eskiyse true (README 4.1, veri tazeliği).
  bool get isStale =>
      _lastPacketAt == null || _clock.elapsed - _lastPacketAt! > const Duration(seconds: 2);

  void start() {
    if (_timer != null) return;
    _clock.start();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final t = _clock.elapsedMilliseconds / 1000;
    seq = (seq + 1) & 0xFF;
    tiltDeg = 3 * sin(t / 4) + (_rng.nextDouble() - 0.5) * 0.6;
    charging = (t ~/ 20).isOdd;
    if (_rng.nextInt(8) == 0) {
      batteryPct = (batteryPct + (charging ? 1 : -1)).clamp(0, 100);
    }
    batteryMv = 6400 + batteryPct * 18 + _rng.nextInt(20);
    robotMs = 1200000 + _clock.elapsedMilliseconds;
    _lastPacketAt = _clock.elapsed;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }
}
