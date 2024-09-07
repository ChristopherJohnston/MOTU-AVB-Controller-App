import 'package:flutter/material.dart';
import 'package:motu_control/components/fader.dart';
import 'package:motu_control/components/panner.dart';
import 'package:motu_control/components/icon_toggle_button.dart';
import 'package:motu_control/utils/db_slider_utils.dart';
import 'package:motu_control/api/datastore.dart';
import 'package:motu_control/api/channel_state.dart';
import 'package:motu_control/utils/constants.dart';

///
/// Faders and Panners for channel sends
///
class ChannelSend extends StatelessWidget {
  final ChannelState state;
  final ChannelState output;
  final Function(
    ChannelType,
    int,
    ValueType,
    ChannelType?,
    int?,
    double,
  ) valueChanged;
  final Function(ChannelType, int)? channelClicked;

  const ChannelSend({
    required this.state,
    required this.output,
    required this.valueChanged,
    super.key,
    this.channelClicked,
  });

  @override
  Widget build(BuildContext context) {
    double sendValue = state.outputValues[output.type]![output.index]!.send;
    double panValue = state.outputValues[output.type]![output.index]!.pan;

    // For groups and reverbs we want to link to the relevant page
    Widget header = TextButton(
      onPressed: () {
        if (channelClicked != null) {
          channelClicked!(state.type, state.index);
        }
      },
      child: Text(
        state.name,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );

    return Column(
      children: [
        header,
        const SizedBox(height: 10),
        IconToggleButton(
          label: "",
          icon: Icons.mic_off,
          activeColor: const Color(0xFFFF0000),
          inactiveColor: const Color.fromRGBO(147, 147, 147, 1),
          active: sendValue == inputForMinusInfdB ? true : false,
          onPressed: () {
            // Channel sends don't have a mute but we can emulate this by
            // setting the send value to -∞dB (0.0)
            // Caveat of this is we don't know the previous value on unmute
            // so for now set it to -12dB. We could store state of previous value
            // but that would mean a stateful widget.
            valueChanged(
              state.type,
              state.index,
              ValueType.send,
              output.type,
              output.index,
              sendValue > inputForMinusInfdB
                  ? inputForMinusInfdB
                  : inputForMinus12dB,
            );
          },
        ),
        Fader(
          value: sendValue,
          style: kFaderStyles[output.type]!,
          valueChanged: (value) => {
            valueChanged(
              state.type,
              state.index,
              ValueType.send,
              output.type,
              output.index,
              value,
            )
          },
        ),
        const SizedBox(height: 20),
        Panner(
          style: PannerStyle.fromColor(
              kFaderStyles[output.type]!.activeTrackColor),
          min: -1.0,
          max: 1.0,
          value: panValue,
          valueChanged: (value) => {
            valueChanged(
              state.type,
              state.index,
              ValueType.pan,
              output.type,
              output.index,
              value,
            )
          },
        ),
      ],
    );
  }
}
