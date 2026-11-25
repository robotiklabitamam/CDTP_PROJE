import 'package:material_ui/material_ui.dart';

const ytuLogoAsset = 'assets/images/ytu_logo.webp';

class YtuLogo extends StatelessWidget {
  const YtuLogo({super.key, this.size = 40, this.opacity = 1});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Image.asset(
        ytuLogoAsset,
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
        semanticLabel: 'Yıldız Teknik Üniversitesi logosu',
      ),
    );
  }
}
