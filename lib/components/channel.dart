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
  final String outputPrefix;
  final int outputChannel;

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
    this.outputPrefix = "input",
    this.outputChannel = 0,
  });

  @override
  Widget build(BuildContext context) {
    String faderPath = "mix/$prefix/$channelNumber/matrix/";
    faderPath += (outputPrefix == "input")
        ? "fader"
        : "$outputPrefix/$outputChannel/send";

    String panPath = "mix/$prefix/$channelNumber/matrix/";
    panPath += (["input", "main"].contains(outputPrefix))
        ? "pan"
        : "$outputPrefix/$outputChannel/pan";

    String soloPath = 'mix/$prefix/$channelNumber/matrix/solo';
    String mutePath = 'mix/$prefix/$channelNumber/matrix/mute';

    double soloValue = snapshotData[soloPath] ?? 0.0;
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
        Row(children: [
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
          IconToggleButton(
            label: "",
            icon: Icons.settings_voice,
            activeColor: const Color.fromARGB(255, 150, 182, 10),
            inactiveColor: const Color.fromRGBO(147, 147, 147, 1),
            active: soloValue == 1.0 ? true : false,
            onPressed: () {
              toggleBoolean(
                soloPath,
                soloValue,
              );
            },
          ),
        ]),
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
        // TODO: Stereo channels do not have a panner.
        // Add Mono/Stereo indicator and show/hide panner
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
