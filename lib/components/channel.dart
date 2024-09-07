import 'package:flutter/material.dart';
import 'package:motu_control/components/fader.dart';
import 'package:motu_control/components/icon_toggle_button.dart';
import 'package:motu_control/components/panner.dart';
import 'package:motu_control/utils/constants.dart';
import 'package:motu_control/api/datastore.dart';
import 'package:motu_control/api/channel_state.dart';

class Channel extends StatelessWidget {
  final ChannelState state;
  final ChannelState? output;
  final bool isOutput;

  final Function(ChannelType, int, ValueType, bool) toggleBoolean;
  final Function(
    ChannelType,
    int,
    ValueType,
    ChannelType?,
    int?,
    double,
  ) valueChanged;
  final Function(ChannelType, int)? channelClicked;

  const Channel({
    required this.state,
    required this.toggleBoolean,
    required this.valueChanged,
    super.key,
    this.output,
    this.channelClicked,
    this.isOutput = false,
  });

  @override
  Widget build(BuildContext context) {
    bool soloValue = state.channelValues.solo;
    bool muteValue = state.channelValues.mute;

    Widget header = TextButton(
      onPressed: () {
        if (channelClicked != null) {
          channelClicked!(state.type, state.index);
        }
      },
      child: Text(
        (isOutput) ? output?.name ?? state.name : state.name,
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
        Row(children: [
          IconToggleButton(
            label: "",
            icon: kMuteIcon,
            activeColor: kMuteActiveColor,
            inactiveColor: kMuteInactiveColor,
            active: muteValue,
            onPressed: () {
              toggleBoolean(
                state.type,
                state.index,
                ValueType.mute,
                muteValue,
              );
            },
          ),
          IconToggleButton(
            label: "",
            icon: kSoloIcon,
            activeColor: kSoloActiveColor,
            inactiveColor: kSoloInactiveColor,
            active: soloValue,
            onPressed: () {
              toggleBoolean(
                state.type,
                state.index,
                ValueType.solo,
                soloValue,
              );
            },
          ),
        ]),
        Fader(
          value: (output != null)
              ? state.outputValues[output!.type]![output!.index]!.send
              : state.channelValues.fader,
          style: kFaderStyles[output?.type ?? ChannelType.chan],
          valueChanged: (value) => {
            valueChanged(
              state.type,
              state.index,
              (output != null) ? ValueType.send : ValueType.fader,
              output?.type,
              output?.index,
              value,
            )
          },
        ),
        const SizedBox(height: 20),
        (!state.isStereo && output?.type != ChannelType.main)
            ? Panner(
                style: PannerStyle.fromColor(
                    kFaderStyles[output?.type ?? ChannelType.chan]!
                        .activeTrackColor),
                min: -1.0,
                max: 1.0,
                value: (output != null)
                    ? state.outputValues[output!.type]![output!.index]!.pan
                    : state.channelValues.pan,
                valueChanged: (value) => {
                  valueChanged(
                    state.type,
                    state.index,
                    ValueType.pan,
                    output?.type,
                    output?.index,
                    value,
                  )
                },
              )
            : const Text("Stereo"),
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
