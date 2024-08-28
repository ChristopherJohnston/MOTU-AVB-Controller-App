import 'package:flutter/material.dart';
import 'package:motu_control/components/fader_components/fader_thumb_shape.dart';
import 'fader_components/fader_track_shape.dart';

class Panner extends StatelessWidget {
  final double sliderWidth;
  final double min;
  final double max;
  final double value;
  final Function(double)? valueChanged;

  const Panner({
    this.sliderWidth = 36,
    this.max = 1.0,
    this.min = -1.0,
    this.value = 0,
    this.valueChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget slider = Slider(
      value: value,
      divisions: 24,
      min: min,
      max: max,
      onChanged: (value) {
        if (valueChanged != null) {
          valueChanged!(value);
        }
      },
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: 1 - value / min,
                        color: const Color(0XFF111111),
                        backgroundColor: const Color(0xFFFF0000),
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: value / max,
                        backgroundColor: const Color(0XFF111111),
                        color: const Color(0xFFFF0000),
                      ),
                    )
                  ],
                ),
                GestureDetector(
                  onDoubleTap: () {
                    if (valueChanged != null) {
                      // Set value to 0.0 on double-tap (centred)
                      valueChanged!(0.0);
                    }
                  },
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        trackHeight: 5,
                        trackShape: const FaderTrackShape(),
                        thumbShape: const FaderThumbShape(
                          thumbRadius: 8,
                        ),
                        overlayColor: Colors.white.withOpacity(.1),
                        tickMarkShape: SliderTickMarkShape.noTickMark),
                    child: slider,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
