import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../demo/demo_telemetry.dart';
import '../theme.dart';

/// Her sayfanın üstündeki sabit çubuk (README 4.1):
/// solda eğim, ortada BLE durumu, sağda şarj.
class StatusBar extends StatelessWidget implements PreferredSizeWidget {
  const StatusBar({super.key, required this.telemetry});

  final DemoTelemetry telemetry;

  static const double height = 44;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: telemetry,
      builder: (context, _) {
        final t = telemetry;
        final disconnected = t.link == LinkStatus.disconnected;
        final stale = t.isStale;
        final fg = disconnected ? Colors.white : YtuColors.navy;

        return Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: disconnected ? YtuColors.danger : Colors.white,
            border: const Border(bottom: BorderSide(color: YtuColors.gold, width: 2)),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              fontFeatures: tabularFigures,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _Tilt(tiltDeg: t.tiltDeg, stale: stale, baseColor: fg),
                  ),
                ),
                _Link(status: t.link, simulated: t.simulated, color: fg),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _Battery(
                      pct: t.batteryPct,
                      charging: t.charging,
                      stale: stale,
                      baseColor: fg,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String formatSigned(double v, {int digits = 1}) {
  final s = v.abs().toStringAsFixed(digits);
  if (double.parse(s) == 0) return s;
  return v < 0 ? '−$s' : s;
}

class _Tilt extends StatelessWidget {
  const _Tilt({required this.tiltDeg, required this.stale, required this.baseColor});

  final double tiltDeg;
  final bool stale;
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    final abs = tiltDeg.abs();
    final color = stale
        ? YtuColors.stale
        : abs > 30
        ? YtuColors.danger
        : abs > 15
        ? YtuColors.warning
        : baseColor;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: tiltDeg * math.pi / 180,
          child: Icon(Icons.arrow_upward_rounded, size: 18, color: color),
        ),
        const SizedBox(width: 4),
        Text('${formatSigned(tiltDeg)}°', style: TextStyle(color: color)),
        if (stale) const _NoData(),
      ],
    );
  }
}

class _Battery extends StatelessWidget {
  const _Battery({
    required this.pct,
    required this.charging,
    required this.stale,
    required this.baseColor,
  });

  final int pct;
  final bool charging;
  final bool stale;
  final Color baseColor;

  IconData get _icon {
    if (pct >= 95) return Icons.battery_full_rounded;
    if (pct >= 80) return Icons.battery_6_bar_rounded;
    if (pct >= 65) return Icons.battery_5_bar_rounded;
    if (pct >= 50) return Icons.battery_4_bar_rounded;
    if (pct >= 35) return Icons.battery_3_bar_rounded;
    if (pct >= 20) return Icons.battery_2_bar_rounded;
    if (pct >= 10) return Icons.battery_1_bar_rounded;
    return Icons.battery_alert_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = stale ? YtuColors.stale : (pct < 20 ? YtuColors.danger : baseColor);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (stale) const _NoData(),
        if (charging && !stale)
          const Icon(Icons.bolt_rounded, size: 18, color: YtuColors.gold),
        Icon(_icon, size: 18, color: color),
        const SizedBox(width: 2),
        Text('$pct%', style: TextStyle(color: color)),
      ],
    );
  }
}

class _Link extends StatelessWidget {
  const _Link({required this.status, required this.simulated, required this.color});

  final LinkStatus status;
  final bool simulated;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (status) {
      LinkStatus.connected => (Icons.bluetooth_connected_rounded, 'Bağlı'),
      LinkStatus.searching => (Icons.bluetooth_searching_rounded, 'Aranıyor'),
      LinkStatus.disconnected => (Icons.bluetooth_disabled_rounded, 'Kopuk'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
        if (simulated) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: YtuColors.gold,
              borderRadius: BorderRadius.circular(5),
            ),
            child: const Text(
              'SİM',
              style: TextStyle(fontSize: 10, color: YtuColors.navy, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }
}

class _NoData extends StatelessWidget {
  const _NoData();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'veri yok',
        style: TextStyle(fontSize: 11, color: YtuColors.stale, fontWeight: FontWeight.w500),
      ),
    );
  }
}
