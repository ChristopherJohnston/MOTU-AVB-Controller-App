import 'package:flutter/material.dart';
import 'package:flutter_icon_shadow/flutter_icon_shadow.dart';
import 'package:motu_control/utils/color_manipulation.dart';

class IconToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color activeColor;
  final Color inactiveColor;
  final bool active;
  final GestureTapCallback onPressed;

  const IconToggleButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.activeColor,
      required this.inactiveColor,
      required this.active,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: IconShadow(
          Icon(
            icon,
            color: active ? lighten(activeColor, 0.22) : inactiveColor,
            size: 26,
          ),
          shadowColor: activeColor,
          showShadow: active ? true : false),
      iconSize: 26,
      hoverColor: const Color(0x00FFFFFF),
      splashColor: const Color(0x00FFFFFF),
      highlightColor: const Color(0x00FFFFFF),
      onPressed: onPressed,
    );
  }
}
