import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../demo/demo_telemetry.dart';
import '../theme.dart';
import '../widgets/status_bar.dart' show formatSigned;

/// 4. sekme (geçici): telefon kamerasını açar ve rastgele/sahte değerler gösterir.
///
/// Kamera yalnızca bu sekme görünürken açık tutulur; sekmeden çıkınca ya da
/// uygulama arka plana geçince kapatılır.
class DebugPage extends StatefulWidget {
  const DebugPage({super.key, required this.active, required this.telemetry});

  final bool active;
  final DemoTelemetry telemetry;

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  String? _error;
  bool _opening = false;

  /// Her açma/kapama isteğinde artar; geç biten eski açma işlemlerini ayıklar.
  int _generation = 0;

  final _rng = Random();
  Timer? _ticker;
  _VisionSample _sample = _VisionSample.empty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) _activate();
  }

  @override
  void didUpdateWidget(DebugPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      widget.active ? _activate() : _deactivate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.active) return;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _closeCamera();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _openCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _generation++;
    _controller?.dispose();
    super.dispose();
  }

  void _activate() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      setState(() => _sample = _VisionSample.random(_rng));
    });
    _openCamera();
  }

  void _deactivate() {
    _ticker?.cancel();
    _ticker = null;
    _closeCamera();
  }

  Future<void> _openCamera() async {
    final gen = ++_generation;
    await _disposeController();
    setState(() {
      _opening = true;
      _error = null;
    });

    String? error;
    CameraController? controller;
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        final back = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
        _cameraIndex = back < 0 ? 0 : back;
      }
      if (_cameras.isEmpty) {
        error = 'Bu cihazda kamera bulunamadı.';
      } else {
        controller = CameraController(
          _cameras[_cameraIndex],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await controller.initialize();
      }
    } on CameraException catch (e) {
      error = switch (e.code) {
        'CameraAccessDenied' || 'CameraAccessDeniedWithoutPrompt' || 'CameraAccessRestricted' =>
          'Kamera izni verilmedi.\nAyarlar → Gizlilik ve Güvenlik → Kamera bölümünden izin verin.',
        _ => 'Kamera açılamadı (${e.code}).\n${e.description ?? ''}'.trim(),
      };
    } on MissingPluginException {
      error = 'Bu platformda kamera desteklenmiyor.\nUygulamayı iPhone ya da Android telefonda çalıştırın.';
    } catch (e) {
      error = 'Kamera açılamadı: $e';
    }

    if (!mounted || gen != _generation) {
      await controller?.dispose();
      return;
    }
    if (error != null) {
      await controller?.dispose();
      controller = null;
    }
    setState(() {
      _controller = controller;
      _error = error;
      _opening = false;
    });
  }

  Future<void> _closeCamera() async {
    _generation++;
    await _disposeController();
    if (mounted) setState(() => _opening = false);
  }

  Future<void> _disposeController() async {
    final c = _controller;
    if (c == null) return;
    if (mounted) {
      setState(() => _controller = null);
    } else {
      _controller = null;
    }
    await c.dispose();
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _openCamera();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPreview(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _cameras.length > 1 && !_opening ? _switchCamera : null,
                icon: const Icon(Icons.cameraswitch_rounded),
                label: const Text('Ön / Arka'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _opening ? null : _openCamera,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Yeniden Aç'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ListenableBuilder(
          listenable: widget.telemetry,
          builder: (context, _) {
            final t = widget.telemetry;
            return _ValueSection(
              title: 'Telemetri (simülasyon, 1 Hz)',
              icon: Icons.sensors_rounded,
              values: [
                ('seq', '${t.seq}'),
                ('Şarj', '${t.batteryPct} %'),
                ('Şarj oluyor', t.charging ? 'Evet' : 'Hayır'),
                ('Eğim', '${formatSigned(t.tiltDeg, digits: 2)}°'),
                ('Batarya', '${t.batteryMv} mV'),
                ('robot_ms', '${t.robotMs}'),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        _ValueSection(
          title: 'Görüntü işleme (rastgele değerler)',
          icon: Icons.center_focus_strong_rounded,
          values: [
            ('Hareket', _sample.motion),
            ('Yön', _sample.direction),
            ('Robot marker', _sample.markerVisible ? 'Görünüyor' : 'Yok'),
            ('Kutu marker', _sample.boxVisible ? 'Görünüyor' : 'Yok'),
            ('x', '${_sample.x.toStringAsFixed(2)} m'),
            ('y', '${_sample.y.toStringAsFixed(2)} m'),
            ('Yaw', '${formatSigned(_sample.yaw)}°'),
            ('Mesafe', '${_sample.distance.toStringAsFixed(2)} m'),
            ('İşleme hızı', '${_sample.fps.toStringAsFixed(1)} Hz'),
          ],
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final c = _controller;
    final Widget content;
    if (c != null && c.value.isInitialized) {
      final portrait = MediaQuery.orientationOf(context) == Orientation.portrait;
      final ar = c.value.aspectRatio; // sensör yönünde (yatay) en/boy oranı
      content = Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: portrait ? 100 : 100 * ar,
              height: portrait ? 100 * ar : 100,
              child: CameraPreview(c),
            ),
          ),
          const _Reticle(),
          Positioned(
            left: 10,
            top: 10,
            child: _Badge(
              icon: Icons.circle,
              iconColor: Colors.redAccent,
              text: 'CANLI · ${_lensName(c.description.lensDirection)}',
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: _Badge(
              icon: Icons.speed_rounded,
              text: '${_sample.fps.toStringAsFixed(1)} Hz',
            ),
          ),
        ],
      );
    } else if (_error != null) {
      content = _PreviewMessage(icon: Icons.no_photography_rounded, text: _error!);
    } else if (_opening) {
      content = const _PreviewMessage(icon: Icons.photo_camera_rounded, text: 'Kamera açılıyor…', busy: true);
    } else {
      content = const _PreviewMessage(icon: Icons.photo_camera_rounded, text: 'Kamera kapalı');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: ColoredBox(color: YtuColors.navyDark, child: content),
      ),
    );
  }

  static String _lensName(CameraLensDirection d) => switch (d) {
        CameraLensDirection.back => 'Arka',
        CameraLensDirection.front => 'Ön',
        CameraLensDirection.external => 'Harici',
      };
}

class _VisionSample {
  const _VisionSample({
    required this.motion,
    required this.direction,
    required this.markerVisible,
    required this.boxVisible,
    required this.x,
    required this.y,
    required this.yaw,
    required this.distance,
    required this.fps,
  });

  static const empty = _VisionSample(
    motion: '—',
    direction: '—',
    markerVisible: false,
    boxVisible: false,
    x: 0,
    y: 0,
    yaw: 0,
    distance: 0,
    fps: 0,
  );

  static const _motions = ['Hareket ediyor', 'Dönüyor', 'Statik denge', 'Toparlanma'];
  static const _directions = ['İleri', 'Geri', 'Sağ', 'Sol'];

  factory _VisionSample.random(Random r) => _VisionSample(
        motion: _motions[r.nextInt(_motions.length)],
        direction: _directions[r.nextInt(_directions.length)],
        markerVisible: r.nextDouble() < 0.85,
        boxVisible: r.nextDouble() < 0.8,
        x: (r.nextDouble() - 0.5) * 2,
        y: r.nextDouble() * 1.5,
        yaw: (r.nextDouble() - 0.5) * 360,
        distance: r.nextDouble() * 1.4,
        fps: 10 + r.nextDouble() * 5,
      );

  final String motion;
  final String direction;
  final bool markerVisible;
  final bool boxVisible;
  final double x;
  final double y;
  final double yaw;
  final double distance;
  final double fps;
}

class _ValueSection extends StatelessWidget {
  const _ValueSection({required this.title, required this.icon, required this.values});

  final String title;
  final IconData icon;
  final List<(String, String)> values;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: YtuColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: YtuColors.navy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final columns = constraints.maxWidth > 420 ? 3 : 2;
                final w = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (final (label, value) in values)
                      SizedBox(width: w, child: _ValueTile(label: label, value: value)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: YtuColors.background,
        borderRadius: BorderRadius.circular(10),
        border: const Border(left: BorderSide(color: YtuColors.gold, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: YtuColors.textMuted)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: YtuColors.navy,
              fontFeatures: tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMessage extends StatelessWidget {
  const _PreviewMessage({required this.icon, required this.text, this.busy = false});

  final IconData icon;
  final String text;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(color: YtuColors.gold, strokeWidth: 3),
              )
            else
              Icon(icon, size: 44, color: YtuColors.gold),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.text, this.iconColor = YtuColors.gold});

  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFeatures: tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

/// Önizlemenin ortasında altın renkli nişangâh.
class _Reticle extends StatelessWidget {
  const _Reticle();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: YtuColors.gold.withValues(alpha: 0.9), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Icon(Icons.add, color: YtuColors.gold, size: 22)),
        ),
      ),
    );
  }
}
