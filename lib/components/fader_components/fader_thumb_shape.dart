import 'package:flutter/material.dart';
import 'package:motu_control/utils/constants.dart';

class FaderThumbShape extends SliderComponentShape {
  late final FaderThumbStyle style;

  FaderThumbShape({
    FaderThumbStyle? style,
  }) {
    this.style = style ?? kDefaultFaderThumbStyle;
  }

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(style.thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    final paint = Paint()
      ..color = style.color //Thumb Background Color
      ..style = PaintingStyle.stroke
      ..strokeWidth = style.strokeWidth;

    TextSpan span = TextSpan(
      style: style.thumbTextStyle,
      text: "",
    );

    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    Offset textCenter =
        Offset(center.dx - (tp.width / 2), center.dy - (tp.height / 2));

    canvas.drawCircle(center, style.thumbRadius * .9, paint);
    tp.paint(canvas, textCenter);
  }
}
