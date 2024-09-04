import 'package:flutter/material.dart';
import 'package:motu_control/components/fader.dart';
import 'package:motu_control/components/panner.dart';
import 'package:motu_control/components/icon_toggle_button.dart';
import 'package:motu_control/utils/db_slider_utils.dart';

///
/// Faders and Panners for channel sends
///
class ChannelSend extends StatelessWidget {
  final String name;
  final int inputChannelNumber;
  final int outputChannelNumber;
  final Map<String, dynamic> snapshotData;
  final Function(String, double) valueChanged;
  final String inputChannelPrefix;
  final String outputChannelPrefix;
  final Function(String, int)? channelClicked;

  const ChannelSend(
    this.name,
    this.inputChannelNumber,
    this.outputChannelNumber,
    this.snapshotData,
    this.valueChanged, {
    super.key,
    this.inputChannelPrefix = "chan",
    this.outputChannelPrefix = "aux",
    this.channelClicked,
  });

  @override
  Widget build(BuildContext context) {
    String sendPath =
        'mix/$inputChannelPrefix/$inputChannelNumber/matrix/$outputChannelPrefix/$outputChannelNumber/send';
    String panPath =
        'mix/$inputChannelPrefix/$inputChannelNumber/matrix/$outputChannelPrefix/$outputChannelNumber/pan';

    double sendValue = snapshotData[sendPath] ?? inputForMinusInfdB;
    double panValue = snapshotData[panPath] ?? 0.0;

    // For groups and reverbs we want to link to the relevant page
    Widget header = Text(
      name,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
    );

    header = TextButton(
      onPressed: () {
        if (channelClicked != null) {
          channelClicked!(
              (inputChannelPrefix == "chan") ? "mixer" : inputChannelPrefix,
              inputChannelNumber);
        }
      },
      child: header,
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
              sendPath,
              sendValue > inputForMinusInfdB
                  ? inputForMinusInfdB
                  : inputForMinus12dB,
            );
          },
        ),
        Fader(
          sliderHeight: 440,
          value: sendValue,
          valueChanged: (value) => {
            valueChanged(
              sendPath,
              value,
            )
          },
        ),
        const SizedBox(height: 20),
        Panner(
          min: -1.0,
          max: 1.0,
          value: panValue,
          valueChanged: (value) => {
            valueChanged(
              panPath,
              value,
            )
          },
        ),
      ],
    );
  }
}
