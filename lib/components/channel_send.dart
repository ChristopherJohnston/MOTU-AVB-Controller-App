import 'package:flutter/material.dart';
import 'package:motu_control/components/fader.dart';
import 'package:motu_control/components/panner.dart';
import 'package:motu_control/components/icon_toggle_button.dart';
import 'package:motu_control/utils/db_slider_utils.dart';
import 'package:motu_control/api/motu.dart';

///
/// Faders and Panners for channel sends
///
class ChannelSend extends StatelessWidget {
  final String name;
  final int inputChannelNumber;
  final int outputChannelNumber;
  final Datastore snapshotData;
  final Function(String, double) valueChanged;
  final ChannelType inputChannelType;
  final ChannelType outputChannelType;
  final Function(ChannelType, int)? channelClicked;

  const ChannelSend(
    this.name,
    this.inputChannelNumber,
    this.outputChannelNumber,
    this.snapshotData,
    this.valueChanged, {
    super.key,
    this.inputChannelType = ChannelType.chan,
    this.outputChannelType = ChannelType.aux,
    this.channelClicked,
  });

  @override
  Widget build(BuildContext context) {
    double sendValue = snapshotData.getOutputSendValue(
          inputChannelType,
          inputChannelNumber,
          outputChannelType,
          outputChannelNumber,
        ) ??
        inputForMinusInfdB;

    double panValue = snapshotData.getOutputPanValue(
          inputChannelType,
          inputChannelNumber,
          outputChannelType,
          outputChannelNumber,
        ) ??
        0.0;

    // For groups and reverbs we want to link to the relevant page
    Widget header = TextButton(
      onPressed: () {
        if (channelClicked != null) {
          channelClicked!(inputChannelType, inputChannelNumber);
        }
      },
      child: Text(
        name,
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
              snapshotData.getOutputPath(
                inputChannelType,
                inputChannelNumber,
                outputChannelType,
                outputChannelNumber,
                ChannelValue.send,
              ),
              sendValue > inputForMinusInfdB
                  ? inputForMinusInfdB
                  : inputForMinus12dB,
            );
          },
        ),
        Fader(
          sliderHeight: 440,
          value: sendValue,
          type: outputChannelType,
          valueChanged: (value) => {
            valueChanged(
              snapshotData.getOutputPath(
                inputChannelType,
                inputChannelNumber,
                outputChannelType,
                outputChannelNumber,
                ChannelValue.send,
              ),
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
              snapshotData.getOutputPath(
                inputChannelType,
                inputChannelNumber,
                outputChannelType,
                outputChannelNumber,
                ChannelValue.pan,
              ),
              value,
            )
          },
        ),
      ],
    );
  }
}
