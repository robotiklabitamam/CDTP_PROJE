import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../widgets/ytu_logo.dart';

/// 3. sekme: test kayıtları. Henüz test yapılmadığı için boş durum gösterilir.
class RecordsPage extends StatelessWidget {
  const RecordsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const YtuLogo(size: 160, opacity: 0.12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: YtuColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.video_library_rounded, size: 36, color: YtuColors.gold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Test yapılmadı',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: YtuColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tamamlanan testlerin videoları, ölçülen değerleri ve '
              'GEÇTİ / KALDI sonuçları burada listelenecek.',
              textAlign: TextAlign.center,
              style: TextStyle(color: YtuColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
