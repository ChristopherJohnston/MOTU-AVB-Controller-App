import 'package:flutter/material.dart';
import 'package:motu_control/components/fader.dart';
import 'package:motu_control/components/icon_toggle_button.dart';
import 'package:motu_control/components/panner.dart';
import 'package:motu_control/utils/db_slider_utils.dart';

class Channel extends StatelessWidget {
  final String name;
  final int channelNumber;
  final Map<String, dynamic> snapshotData;
  final String prefix;

  final Function(String, double) toggleBoolean;
  final Function(String, double) valueChanged;

  const Channel(
    this.name,
    this.channelNumber,
    this.snapshotData,
    this.toggleBoolean,
    this.valueChanged, {
    super.key,
    this.prefix = "chan",
  });

  @override
  Widget build(BuildContext context) {
    String mutePath = 'mix/$prefix/$channelNumber/matrix/mute';
    String faderPath = 'mix/$prefix/$channelNumber/matrix/fader';
    String panPath = 'mix/$prefix/$channelNumber/matrix/pan';

    double muteValue = snapshotData[mutePath] ?? 0.0;
    double faderValue = snapshotData[faderPath] ?? inputForMinusInfdB;
    double panValue = snapshotData[panPath] ?? 0.0;

    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        IconToggleButton(
          label: "",
          icon: Icons.mic_off,
          activeColor: const Color(0xFFFF0000),
          inactiveColor: const Color.fromRGBO(147, 147, 147, 1),
          active: muteValue == 1.0 ? true : false,
          onPressed: () {
            toggleBoolean(
              mutePath,
              muteValue,
            );
          },
        ),
        Fader(
          sliderHeight: 440,
          value: faderValue,
          valueChanged: (value) => {
            valueChanged(
              faderPath,
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
        // IconToggleButton(
        //   label: "",
        //   icon: Icons.animation,
        //   activeColor: const Color(0xFFFFFFFF),
        //   inactiveColor: const Color(0xFF939393),
        //   active: snapshotData['mix/reverb/$channelNumber/reverb/enable'] == 1.0
        //       ? true
        //       : false,
        //   onPressed: () {
        //     toggleBoolean('mix/reverb/$channelNumber/reverb/enable',
        //         snapshotData['mix/reverb/$channelNumber/reverb/enable'] ?? 0.0);
        //   },
        // )
      ],
    );
  }
}
