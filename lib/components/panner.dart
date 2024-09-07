import 'package:flutter/material.dart';
import 'package:motu_control/utils/constants.dart';
import 'package:motu_control/components/fader_components/fader_thumb_shape.dart';
import 'fader_components/fader_track_shape.dart';

class Panner extends StatelessWidget {
  late final PannerStyle style;
  final double min;
  final double max;
  final double value;
  final Function(double)? valueChanged;

  Panner({
    this.max = 1.0,
    this.min = -1.0,
    this.value = 0,
    this.valueChanged,
    PannerStyle? style,
    super.key,
  }) {
    this.style = style ?? kDefaultPannerStyle;
  }

  @override
  Widget build(BuildContext context) {
    Widget slider = Slider(
      value: value,
      divisions: style.divisions,
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
        width: style.width,
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
                        color: style.inactiveTrackColor,
                        backgroundColor: style.activeTrackColor,
                      ),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: value / max,
                        backgroundColor: style.inactiveTrackColor,
                        color: style.activeTrackColor,
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
                        trackHeight: style.trackHeight,
                        trackShape: const FaderTrackShape(),
                        thumbShape: FaderThumbShape(style: style.thumbStyle),
                        overlayColor: style.overlayColor,
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
