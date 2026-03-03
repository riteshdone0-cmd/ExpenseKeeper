import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 52,
    this.showName = true,
    this.nameStyle,
    this.iconColor,
    this.backgroundColor,
  });

  final double size;
  final bool showName;
  final TextStyle? nameStyle;
  final Color? iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = iconColor ?? scheme.onPrimary;
    final bg = backgroundColor ?? scheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(size * 0.28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: bg.withOpacity(0.28),
                blurRadius: size * 0.18,
                offset: Offset(0, size * 0.1),
              ),
            ],
          ),
          child: Icon(
            Icons.insights_rounded,
            color: fg,
            size: size * 0.56,
          ),
        ),
        if (showName) ...<Widget>[
          const SizedBox(width: 12),
          Text(
            'FinPilot',
            style: nameStyle ??
                Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
          ),
        ],
      ],
    );
  }
}
