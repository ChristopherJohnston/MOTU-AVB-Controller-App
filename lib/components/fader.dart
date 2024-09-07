import 'package:flutter/material.dart';
import 'package:motu_control/utils/constants.dart';
import 'package:motu_control/utils/db_slider_utils.dart';
import 'package:motu_control/components/fader_components/fader_thumb_shape.dart';
import 'fader_components/fader_track_shape.dart';

class CustomRoundSliderTickMarkShape extends SliderTickMarkShape {
  final double tickMarkRadius;

  const CustomRoundSliderTickMarkShape({
    this.tickMarkRadius = 3.0,
  });

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
  }) {
    // Defines the size of the tick marks
    return Size.fromRadius(tickMarkRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    bool isEnabled = false,
    TextDirection? textDirection,
  }) {
    if (sliderTheme.tickMarkShape == null ||
        sliderTheme.inactiveTickMarkColor == null ||
        sliderTheme.activeTickMarkColor == null) {
      return;
    }

    // Determine the color for the tick mark based on whether the slider is enabled and active
    final Color tickMarkColor = isEnabled
        ? sliderTheme.activeTickMarkColor!
        : sliderTheme.inactiveTickMarkColor!;

    final Paint paint = Paint()
      ..color = tickMarkColor
          .withOpacity(enableAnimation.value) // Ensure tick mark is visible
      ..style = PaintingStyle.fill;

    context.canvas.drawCircle(center, tickMarkRadius, paint);
  }
}

class Fader extends StatelessWidget {
  late final FaderStyle style;
  final double min = 0.0;
  final double max = 1.0;
  final double value; // 0-4
  final Function(double)? valueChanged;

  Fader({
    this.value = 1.0,
    this.valueChanged,
    FaderStyle? style,
    super.key,
  }) {
    this.style = style ?? kDefaultFaderStyle;
  }

  @override
  Widget build(BuildContext context) {
    double sliderPosition = inputToSlider(value);

    Widget slider = GestureDetector(
      onDoubleTap: () {
        if (valueChanged != null) {
          // Set value to 1.0 on double-tap (0 dB)
          valueChanged!(
              (value == inputFor0dB) ? inputForMinusInfdB : inputFor0dB);
        }
      },
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: style.activeTrackColor,
          inactiveTrackColor: style.inactiveTrackColor,
          trackHeight: style.trackHeight,
          trackShape: const FaderTrackShape(),
          thumbShape: FaderThumbShape(
            style: style.thumbStyle,
          ),
          overlayColor: style.overlayColor,
          tickMarkShape: CustomRoundSliderTickMarkShape(
            tickMarkRadius: style.tickMarkRadius,
          ),
          activeTickMarkColor: style.activeTickMarkColor,
          inactiveTickMarkColor: style.inactiveTickMarkColor,
        ),
        child: Slider(
          value: sliderPosition,
          min: min,
          max: max,
          divisions: style.divisions,
          onChanged: (newValue) {
            if (valueChanged != null) {
              double newInputValue = sliderToInput(newValue);
              valueChanged!(newInputValue);
            }
          },
        ),
      ),
    );

    return SizedBox(
      width: style.width,
      child: Column(
        children: [
          SizedBox(
            height: style.sliderHeight,
            child: RotatedBox(
              quarterTurns: 3,
              child: slider,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          // Slider Value
          Text(
            inputToDbStr(value),
            style: style.valueTextStyle,
          )
        ],
      ),
    );
  }
}
