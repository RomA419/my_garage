import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Простая визуализация "силиуэта" автомобиля с цветом.
///
/// Поддерживает SVG-ресурс (если задан), иначе использует иконку.
class CarPreview extends StatelessWidget {
  final IconData? icon;
  final String? svgAsset;
  final String? pngAsset;
  final Color color;
  final double size;
  final String? title;
  final String? subtitle;

  const CarPreview({
    super.key,
    this.icon,
    this.svgAsset,
    this.pngAsset,
    required this.color,
    this.size = 120,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 1.4,
          height: size * 0.7,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.25),
                theme.cardColor.withOpacity(0.1),
              ],
            ),
            border: Border.all(color: theme.dividerColor.withOpacity(0.25), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: pngAsset != null
                ? Image.asset(
                    pngAsset!,
                    width: size,
                    height: size,
                    color: color,
                    colorBlendMode: BlendMode.srcATop,
                    fit: BoxFit.contain,
                  )
                : svgAsset != null
                    ? SvgPicture.asset(
                        svgAsset!,
                        width: size,
                        height: size,
                        colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
                        fit: BoxFit.contain,
                      )
                    : ColorFiltered(
                        colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
                        child: Icon(
                          icon,
                          size: size,
                          color: theme.textTheme.bodyLarge?.color?.withOpacity(0.4) ?? Colors.grey,
                        ),
                      ),
          ),
        ),
        if (title != null) ...[
          const SizedBox(height: 12),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
          ),
        ],
      ],
    );
  }
}
