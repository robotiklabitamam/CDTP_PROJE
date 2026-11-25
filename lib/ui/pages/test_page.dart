import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/section_card.dart';

/// README 7. bölümdeki görevler.
enum TestTask {
  staticBalance('A', 'Statik Denge', Icons.accessibility_new_rounded,
      '30 s boyunca yer değiştirme < 10 cm, |eğim| < 15°, kutu robot üzerinde.'),
  guidance('B', 'Robot Yönlendirmesi', Icons.alt_route_rounded,
      'Seçilen yönde 0,8–1,2 m hareket, sonunda ≥ 3 s durma, her komutta tepki < 2 s.'),
  charging('C', 'Şarj Etme', Icons.ev_station_rounded,
      'Robot durduktan sonra en geç 5 s içinde şarj başlamalı.'),
  integrated('E', 'Bütünleşik Görev', Icons.hub_rounded,
      'Denge → komutlarla hareket → hedefte bekleme → istasyona yönelme → şarj.');

  const TestTask(this.module, this.title, this.icon, this.criteria);

  final String module;
  final String title;
  final IconData icon;
  final String criteria;
}

enum ExpectedDirection { forward, backward }

/// 2. sekme: görev seçimi, kamera önizlemesi, sayaç ve test kontrolleri.
///
/// Tasarım aşaması: Kalibrasyon / Testi Başlat / Testi Bitir henüz bir şey yapmaz.
class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  TestTask _task = TestTask.staticBalance;
  ExpectedDirection _direction = ExpectedDirection.forward;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          title: 'Görev Seçimi',
          icon: Icons.assignment_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final task in TestTask.values)
                    ChoiceChip(
                      selected: task == _task,
                      showCheckmark: false,
                      avatar: Icon(
                        task.icon,
                        size: 18,
                        color: task == _task ? Colors.white : YtuColors.navy,
                      ),
                      label: Text('${task.module} · ${task.title}'),
                      onSelected: (_) => setState(() => _task = task),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: YtuColors.goldLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.flag_rounded, size: 18, color: YtuColors.navy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _task.criteria,
                        style: const TextStyle(fontSize: 13, color: YtuColors.navy),
                      ),
                    ),
                  ],
                ),
              ),
              if (_task == TestTask.guidance) ...[
                const SizedBox(height: 12),
                const Text(
                  'Beklenen yön',
                  style: TextStyle(fontWeight: FontWeight.w600, color: YtuColors.navy),
                ),
                const SizedBox(height: 6),
                SegmentedButton<ExpectedDirection>(
                  segments: const [
                    ButtonSegment(
                      value: ExpectedDirection.forward,
                      label: Text('İleri'),
                      icon: Icon(Icons.arrow_upward_rounded),
                    ),
                    ButtonSegment(
                      value: ExpectedDirection.backward,
                      label: Text('Geri'),
                      icon: Icon(Icons.arrow_downward_rounded),
                    ),
                  ],
                  selected: {_direction},
                  onSelectionChanged: (s) => setState(() => _direction = s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: YtuColors.navy,
                    selectedForegroundColor: Colors.white,
                    foregroundColor: YtuColors.navy,
                    side: const BorderSide(color: YtuColors.gold),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _CameraPlaceholder(),
        const SizedBox(height: 14),
        const _TimerCard(),
        const SizedBox(height: 14),
        const _PreflightCard(),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Kalibrasyon'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.ev_station_rounded),
                label: const Text('İstasyonu Kaydet'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Testi Başlat'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: YtuColors.gold,
                  foregroundColor: YtuColors.navy,
                ),
                icon: const Icon(Icons.stop_rounded),
                label: const Text('Testi Bitir'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          color: YtuColors.navyDark,
          child: Stack(
            children: [
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam_off_rounded, size: 44, color: YtuColors.gold),
                    SizedBox(height: 8),
                    Text(
                      'Kamera önizlemesi',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Test başlatıldığında burada görünecek',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Positioned(
                left: 10,
                top: 10,
                child: _OverlayChip(icon: Icons.fiber_manual_record, text: 'REC', dim: true),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: const [
                    _OverlayChip(icon: Icons.directions_run_rounded, text: 'Durum: —'),
                    _OverlayChip(icon: Icons.explore_rounded, text: 'Yön: —'),
                    _OverlayChip(icon: Icons.straighten_rounded, text: '0.00 m'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({required this.icon, required this.text, this.dim = false});

  final IconData icon;
  final String text;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final color = dim ? Colors.white38 : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: YtuColors.gold.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: dim ? Colors.white38 : YtuColors.gold),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            const Text(
              'TEST SÜRESİ',
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: YtuColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '00:00.0',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: YtuColors.navy,
                fontFeatures: tabularFigures,
              ),
            ),
            Container(
              height: 3,
              width: 64,
              decoration: BoxDecoration(
                color: YtuColors.gold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreflightCard extends StatelessWidget {
  const _PreflightCard();

  @override
  Widget build(BuildContext context) {
    const items = [
      'BLE bağlı ve son 2 s içinde telemetri geldi',
      'Kamera açık ve robot marker\'ı görüntüde',
      'Kalibrasyon yapıldı',
    ];
    return SectionCard(
      title: 'Ön Kontrol',
      subtitle: 'Tüm koşullar sağlanınca test başlatılabilir',
      icon: Icons.checklist_rounded,
      child: Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.cancel_rounded, size: 20, color: YtuColors.danger),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
