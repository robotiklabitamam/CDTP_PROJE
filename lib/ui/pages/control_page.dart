import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/section_card.dart';

/// 1. sekme: BLE bağlantısı, manuel komutlar ve komut olayları.
///
/// Tasarım aşaması: butonlar henüz bir şey yapmaz (adım 5'te bağlanacak).
class ControlPage extends StatelessWidget {
  const ControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _ConnectionCard(),
        SizedBox(height: 14),
        SectionCard(
          title: 'Manuel Komut',
          subtitle: 'Yalnızca geliştirme ve deneme içindir',
          icon: Icons.gamepad_rounded,
          child: _DirectionPad(),
        ),
        SizedBox(height: 14),
        _CommandEventsCard(),
      ],
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Robot Bağlantısı',
      subtitle: 'BLE · CDTP-ROBOT',
      icon: Icons.bluetooth_rounded,
      trailing: const _Pill(label: 'Bağlı değil', color: YtuColors.textMuted),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: YtuColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.smart_toy_outlined, color: YtuColors.navy),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Henüz cihaz bulunmadı.\n"Cihaz Ara" ile taramayı başlatın.',
                    style: TextStyle(color: YtuColors.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.radar_rounded),
                  label: const Text('Cihaz Ara'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.link_rounded),
                  label: const Text('Bağlan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DirectionPad extends StatelessWidget {
  const _DirectionPad();

  @override
  Widget build(BuildContext context) {
    const gap = 10.0;
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: const Column(
              children: [
                Row(
                  children: [
                    Spacer(),
                    SizedBox(width: gap),
                    _PadButton(icon: Icons.arrow_upward_rounded, label: 'İLERİ'),
                    SizedBox(width: gap),
                    Spacer(),
                  ],
                ),
                SizedBox(height: gap),
                Row(
                  children: [
                    _PadButton(icon: Icons.turn_left_rounded, label: 'SOL'),
                    SizedBox(width: gap),
                    _PadButton(icon: Icons.stop_rounded, label: 'DUR', stop: true),
                    SizedBox(width: gap),
                    _PadButton(icon: Icons.turn_right_rounded, label: 'SAĞ'),
                  ],
                ),
                SizedBox(height: gap),
                Row(
                  children: [
                    Spacer(),
                    SizedBox(width: gap),
                    _PadButton(icon: Icons.arrow_downward_rounded, label: 'GERİ'),
                    SizedBox(width: gap),
                    Spacer(),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 16, color: YtuColors.gold),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'Kabul testlerinde komutlar yalnızca eldivenden gelir. '
                'Test sırasında yalnızca DUR aktif kalır.',
                style: TextStyle(fontSize: 12, color: YtuColors.textMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({required this.icon, required this.label, this.stop = false});

  final IconData icon;
  final String label;
  final bool stop;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: stop ? YtuColors.gold : YtuColors.navy,
            foregroundColor: stop ? YtuColors.navy : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(stop ? 100 : 20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: stop ? 38 : 32),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommandEventsCard extends StatelessWidget {
  const _CommandEventsCard();

  @override
  Widget build(BuildContext context) {
    const header = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: YtuColors.textMuted);
    return SectionCard(
      title: 'Son Komut Olayları',
      icon: Icons.history_rounded,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Komut', style: header)),
                Expanded(flex: 3, child: Text('Kaynak', style: header)),
                Expanded(flex: 2, child: Text('Gecikme', style: header, textAlign: TextAlign.end)),
              ],
            ),
          ),
          const Divider(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Henüz komut olayı yok',
              style: TextStyle(color: YtuColors.textMuted.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
