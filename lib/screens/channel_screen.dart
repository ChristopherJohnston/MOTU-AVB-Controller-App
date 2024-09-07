import 'package:flutter/material.dart';
import 'package:motu_control/api/datastore_api.dart';
import 'package:motu_control/api/mixer_state.dart';
import 'package:motu_control/components/channel.dart';
import 'package:motu_control/components/main_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:motu_control/utils/screen.dart';
import 'package:motu_control/api/channel_state.dart';

class ChannelScreen extends StatelessWidget {
  final int index;
  final MixerState state;
  final MotuDatastoreApi datastoreApiInstance;

  const ChannelScreen({
    required this.index,
    required this.state,
    required this.datastoreApiInstance,
    super.key,
  });

  Widget buildMixerFaders(
    BuildContext context,
    MixerState state,
    MotuDatastoreApi datastoreApiInstance,
  ) {
    List<Widget> faders = [
      // The selected input channel
      Channel(
        state: state.allInputChannelStates[index]!,
        toggleBoolean: datastoreApiInstance.toggleBoolean,
        valueChanged: datastoreApiInstance.setDouble,
      ),

      const SizedBox(width: 40),

      // Main Output For this channel
      Channel(
        state: state.allInputChannelStates[index]!,
        toggleBoolean: datastoreApiInstance.toggleBoolean,
        valueChanged: datastoreApiInstance.setDouble,
        output: state.outputStates[ChannelType.main]![0],
        channelClicked: (ChannelType inputChannelType, int channelNumber) {
          context.go('/${Screen.mixer.name}/0');
        },
        isOutput: true,
      ),

      const SizedBox(width: 20),

      // Reverb output for this channel
      Channel(
        state: state.allInputChannelStates[index]!,
        toggleBoolean: datastoreApiInstance.toggleBoolean,
        valueChanged: datastoreApiInstance.setDouble,
        output: state.outputStates[ChannelType.reverb]![0],
        channelClicked: (ChannelType inputChannelType, int channelNumber) {
          context.go('/${Screen.reverb.name}/0');
        },
        isOutput: true,
      ),

      const SizedBox(width: 20),
    ];

    // Group outputs for this channel
    faders
        .addAll(state.outputStates[ChannelType.group]!.values.map((groupState) {
      return Channel(
        state: state.allInputChannelStates[index]!,
        toggleBoolean: datastoreApiInstance.toggleBoolean,
        valueChanged: datastoreApiInstance.setDouble,
        output: groupState,
        channelClicked: (ChannelType inputChannelType, int channelNumber) {
          context.go('/${Screen.group.name}/${groupState.index}');
        },
        isOutput: true,
      );
    }));

    faders.add(const SizedBox(width: 20));

    // Aux outputs for this channel
    faders.addAll(state.outputStates[ChannelType.aux]!.values.map((auxState) {
      return Channel(
        state: state.allInputChannelStates[index]!,
        toggleBoolean: datastoreApiInstance.toggleBoolean,
        valueChanged: datastoreApiInstance.setDouble,
        output: auxState,
        channelClicked: (ChannelType inputChannelType, int channelNumber) {
          context.go('/${Screen.aux.name}/${auxState.index}');
        },
        isOutput: true,
      );
    }));

    // Return a horizontal scroll view of all the faders.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: faders,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      datastoreApiInstance: datastoreApiInstance,
      state: state,
      body: buildMixerFaders(
        context,
        state,
        datastoreApiInstance,
      ),
    );
  }
}
