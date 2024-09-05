import 'package:flutter/material.dart';
import 'package:motu_control/api/motu.dart';
import 'package:motu_control/utils/constants.dart';
import 'package:motu_control/utils/db_slider_utils.dart';
import 'package:motu_control/components/fader_components/fader_thumb_shape.dart';
import 'fader_components/fader_track_shape.dart';
import 'package:logger/logger.dart';

class CustomRoundSliderTickMarkShape extends SliderTickMarkShape {
  final double tickMarkRadius;

  const CustomRoundSliderTickMarkShape({this.tickMarkRadius = 2.0});

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

final Logger logger = Logger(
  printer: PrettyPrinter(
      // or use SimplePrinter
      methodCount: 2, // number of method calls to be displayed
      errorMethodCount: 8, // number of method calls if stacktrace is provided
      lineLength: 120, // width of the output
      colors: true, // Colorful log messages
      printEmojis: false, // Print an emoji for each log level
      printTime: false // Should each log print contain a timestamp
      ),
);

class Fader extends StatelessWidget {
  final double sliderHeight;
  final double min = 0.0;
  final double max = 1.0;
  final double value; // 0-4
  final Function(double)? valueChanged;
  final ChannelType type;

  const Fader({
    this.sliderHeight = 48,
    this.value = 1.0,
    this.type = ChannelType.chan,
    this.valueChanged,
    super.key,
  });

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
          activeTrackColor: kFaderColors[type],
          inactiveTrackColor: kFaderInactiveTrackColor,
          trackHeight: 5,
          trackShape: const FaderTrackShape(),
          thumbShape: const FaderThumbShape(
            thumbRadius: 15,
          ),
          overlayColor: kFaderOverlayColor,
          tickMarkShape:
              const CustomRoundSliderTickMarkShape(tickMarkRadius: 3.0),
          activeTickMarkColor: kActiveFaderTickMarkColor,
          inactiveTickMarkColor: kInactiveFaderTickMarkColor,
        ),
        child: Slider(
          value: sliderPosition,
          min: min,
          max: max,
          divisions: 100,
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
      width: 100,
      child: Column(
        children: [
          SizedBox(
            height: sliderHeight,
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
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          )
        ],
      ),
    );
  }
}
