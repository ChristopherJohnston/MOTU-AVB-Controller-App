import 'package:flutter/material.dart';
import 'package:motu_control/api/motu.dart';
import 'package:motu_control/components/channel.dart';
import 'package:motu_control/components/main_scaffold.dart';
import 'package:go_router/go_router.dart';

Widget buildMixerFaders(
  BuildContext context,
  ChannelDefinition inputChannel,
  List<ChannelDefinition> groupChannels,
  List<ChannelDefinition> auxChannels,
  MotuDatastoreApi datastoreApiInstance,
  AsyncSnapshot<Datastore> snapshot,
) {
  List<Widget> children;
  List<Widget> faders = [
    Channel(
      inputChannel.name,
      inputChannel.index,
      snapshot.data!,
      datastoreApiInstance.toggleBoolean,
      datastoreApiInstance.setDouble,
      type: inputChannel.type,
    ),
    const SizedBox(width: 40),
    Channel(
      "Main",
      inputChannel.index,
      snapshot.data!,
      datastoreApiInstance.toggleBoolean,
      datastoreApiInstance.setDouble,
      type: inputChannel.type,
      outputType: ChannelType.main,
      outputChannel: 0,
      channelClicked: (ChannelType inputChannelType, int channelNumber) {
        context.go('/mixer/0');
      },
    ),
    Channel(
      "Reverb",
      inputChannel.index,
      snapshot.data!,
      datastoreApiInstance.toggleBoolean,
      datastoreApiInstance.setDouble,
      type: inputChannel.type,
      outputType: ChannelType.reverb,
      outputChannel: 0,
      channelClicked: (ChannelType inputChannelType, int channelNumber) {
        context.go('/reverb/0');
      },
    ),
    const SizedBox(width: 20),
  ];

  faders.addAll(groupChannels.map(
    (a) {
      return Channel(
        a.name,
        inputChannel.index,
        snapshot.data!,
        datastoreApiInstance.toggleBoolean,
        datastoreApiInstance.setDouble,
        type: inputChannel.type,
        outputType: ChannelType.group,
        outputChannel: a.index,
        channelClicked: (ChannelType inputChannelType, int channelNumber) {
          context.go('/group/${a.index}');
        },
      );
    },
  ));

  faders.add(const SizedBox(width: 20));

  faders.addAll(auxChannels.map(
    (a) {
      return Channel(
        a.name,
        inputChannel.index,
        snapshot.data!,
        datastoreApiInstance.toggleBoolean,
        datastoreApiInstance.setDouble,
        type: inputChannel.type,
        outputType: ChannelType.aux,
        outputChannel: a.index,
        channelClicked: (ChannelType inputChannelType, int channelNumber) {
          context.go('/aux/${a.index}');
        },
      );
    },
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

class ChannelScreen extends StatelessWidget {
  final ChannelDefinition inputChannel;
  final MotuDatastoreApi datastoreApiInstance;
  final List<ChannelDefinition> groups;
  final List<ChannelDefinition> auxes;
  final AsyncSnapshot<Datastore> snapshot;

  const ChannelScreen({
    required this.inputChannel,
    required this.datastoreApiInstance,
    required this.snapshot,
    required this.groups,
    required this.auxes,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      body: buildMixerFaders(
        context,
        inputChannel,
        groups,
        auxes,
        datastoreApiInstance,
        snapshot,
      ),
    );
  }
}
