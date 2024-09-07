import 'package:flutter/material.dart';
import 'package:motu_control/api/mixer_state.dart';
import 'package:motu_control/api/datastore_api.dart';
import 'package:motu_control/api/channel_state.dart';
import 'package:motu_control/components/channel_send.dart';
import 'package:motu_control/components/channel.dart';
import 'package:motu_control/components/main_scaffold.dart';
import 'package:motu_control/components/send_header.dart';
import 'package:go_router/go_router.dart';
import 'package:motu_control/utils/constants.dart';

// // Channel
// // /chan/0/matrix/solo
// // /chan/0/matrix/mute
// // /chan/0/matrix/pan
// // /chan/0/matrix/fader

// // /chan/0/matrix/reverb/send
// // /chan/0/matrix/reverb/pan

// // Aux Send
// // /chan/1/matrix/aux/0/send
// // /chan/1/matrix/aux/0/pan
// // /aux/1/matrix/mute
// // /aux/1/matrix/panner
// // /aux/1/matrix/fader

// // Group Send
// // /chan/1/matrix/group/0/send
// // /chan/1/matrix/group/0/pan
// // /group/1/matrix/aux/1/send

// // Reverb

// // /reverb/0/matrix/aux/1/send

// final List<int> auxes = [0, 2, 4, 6, 8, 10, 12];
// final List<Map<String, dynamic>> auxChannels = [
//   {"channel": 0, "type": "chan"},
//   {"channel": 1, "type": "chan"},
//   {"channel": 2, "type": "chan"},
//   {"channel": 3, "type": "chan"},
//   {"channel": 4, "type": "chan"},
//   {"channel": 6, "type": "chan"},
//   {"channel": 8, "type": "chan"},
//   {"channel": 10, "type": "chan"},
//   {"channel": 12, "type": "chan"},
//   {"channel": 14, "type": "chan"},
//   {"channel": 16, "type": "chan"},
//   {"channel": 18, "type": "chan"},
//   {"channel": 20, "type": "chan"},
//   {"channel": 22, "type": "chan"},
//   {"channel": 23, "type": "chan"},
//   {"channel": 35, "type": "chan"},
//   {"channel": 0, "type": "group"},
//   {"channel": 0, "type": "reverb"},
// ];

class SendScreen extends StatelessWidget {
  final int channel;
  final ChannelType sendType;
  final MixerState state;
  final MotuDatastoreApi datastoreApiInstance;
  final IconData headerIcon;

  const SendScreen({
    required this.sendType,
    required this.channel,
    required this.state,
    this.headerIcon = kAuxIcon,
    required this.datastoreApiInstance,
    super.key,
  });

  Widget buildSendFaders(BuildContext context) {
    List<Widget> children;
    List<Widget> faders = [];

    // Add Channels
    for (int inputIndex
        in state.sendInputList[sendType]![ChannelType.chan]![channel]!) {
      faders.add(
        ChannelSend(
          state: state.allInputChannelStates[inputIndex]!,
          valueChanged: datastoreApiInstance.setDouble,
          output: state.outputStates[sendType]![channel]!,
          channelClicked: (ChannelType inputChannelType, int channelNumber) {
            context.go('/${inputChannelType.name}/$channelNumber');
          },
        ),
      );
    }

    // Add Groups
    for (int inputIndex
        in state.sendInputList[sendType]![ChannelType.group]![channel]!) {
      faders.add(
        ChannelSend(
          state: state.outputStates[ChannelType.group]![inputIndex]!,
          valueChanged: datastoreApiInstance.setDouble,
          output: state.outputStates[sendType]![channel]!,
          channelClicked: (ChannelType inputChannelType, int channelNumber) {
            context.go('/${inputChannelType.name}/$channelNumber');
          },
        ),
      );
    }

    // Add Reverb
    if (sendType == ChannelType.aux) {
      faders.add(
        ChannelSend(
          state: state.outputStates[ChannelType.reverb]![0]!,
          valueChanged: datastoreApiInstance.setDouble,
          output: state.outputStates[sendType]![channel]!,
          channelClicked: (ChannelType inputChannelType, int channelNumber) {
            context.go('/${inputChannelType.name}/$channelNumber');
          },
        ),
      );
    }

    // Iterate the auxChannels dictionary to dynamically
    // generate the fader row.
    // for (ChannelType outputType in [ChannelType.chan, ChannelType.group]) {
    //   for (ChannelState inputChannel
    //       in state.sendInputChannelStates[sendType]![outputType]![channel]!) {
    //     faders.add(
    //       ChannelSend(
    //         state: inputChannel,
    //         valueChanged: datastoreApiInstance.setDouble,
    //         output: state.outputStates[sendType]![channel]!,
    //         channelClicked: (ChannelType inputChannelType, int channelNumber) {
    //           context.go('/${inputChannelType.name}/$channelNumber');
    //         },
    //       ),
    //     );
    //   }
    // }
    faders.add(
      const SizedBox(width: 20),
    );

    // Add the output fader for the send mix
    // e,g,
    // mix/aux/<index>/matrix/mute
    //mix/aux/<index>/matrix/fader
    faders.add(Channel(
      state: state.outputStates[sendType]![channel]!,
      toggleBoolean: datastoreApiInstance.toggleBoolean,
      valueChanged: datastoreApiInstance.setDouble,
    ));

    // Build the page: Logo, Row, Faders
    children = [
      Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: faders,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      actions: [
        SendHeader(
          label: sendType.name,
          iconData: headerIcon,
          // Determine which mix is active.
          // Generally they are 2 channels for Left and Right, so always
          // take the Odd (Left) channel.
          selectedChannel: (channel % 2 > 0) ? channel - 1 : channel,
          channelChanged: (int? newValue) {
            if (newValue != null) {
              context.go('/${sendType.name}/$newValue');
            }
          },
          sends: state.outputStates[sendType]!.values.toList(),
        )
      ],
      body: buildSendFaders(context),
    );
  }
}
