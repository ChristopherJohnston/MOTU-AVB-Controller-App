import 'package:flutter/material.dart';
import 'package:motu_control/api/motu.dart';
import 'package:motu_control/components/channel.dart';
import 'package:motu_control/components/main_scaffold.dart';
import 'package:go_router/go_router.dart';

Widget buildMixerFaders(
  BuildContext context,
  Map<String, dynamic> inputChannel,
  List<Map<String, dynamic>> groupChannels,
  List<Map<String, dynamic>> auxChannels,
  MotuDatastoreApi datastoreApiInstance,
  AsyncSnapshot<Map<String, dynamic>> snapshot,
) {
  List<Widget> children;
  List<Widget> faders = [
    Channel(
      inputChannel["name"],
      inputChannel["channel"],
      snapshot.data!,
      datastoreApiInstance.toggleBoolean,
      datastoreApiInstance.setDouble,
      prefix: inputChannel["type"],
    ),
    const SizedBox(width: 40),
    Channel(
      "Main",
      inputChannel["channel"],
      snapshot.data!,
      datastoreApiInstance.toggleBoolean,
      datastoreApiInstance.setDouble,
      prefix: inputChannel["type"],
      outputPrefix: "main",
      outputChannel: 0,
      channelClicked: (String inputChannelType, int channelNumber) {
        context.go('/mixer/0');
      },
    ),
    Channel(
      "Reverb",
      inputChannel["channel"],
      snapshot.data!,
      datastoreApiInstance.toggleBoolean,
      datastoreApiInstance.setDouble,
      prefix: inputChannel["type"],
      outputPrefix: "reverb",
      outputChannel: 0,
      channelClicked: (String inputChannelType, int channelNumber) {
        context.go('/reverb/0');
      },
    ),
    const SizedBox(width: 20),
  ];

  faders.addAll(groupChannels.map(
    (a) {
      return Channel(
        a["name"],
        inputChannel["channel"],
        snapshot.data!,
        datastoreApiInstance.toggleBoolean,
        datastoreApiInstance.setDouble,
        prefix: inputChannel["type"],
        outputPrefix: "group",
        outputChannel: a["channel"],
        channelClicked: (String inputChannelType, int channelNumber) {
          context.go('/group/${a["channel"]}');
        },
      );
    },
  ));

  faders.add(const SizedBox(width: 20));

  faders.addAll(auxChannels.map(
    (a) {
      return Channel(
        a["name"],
        inputChannel["channel"],
        snapshot.data!,
        datastoreApiInstance.toggleBoolean,
        datastoreApiInstance.setDouble,
        prefix: inputChannel["type"],
        outputPrefix: "aux",
        outputChannel: a["channel"],
        channelClicked: (String inputChannelType, int channelNumber) {
          context.go('/aux/${a["channel"]}');
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
  final Map<String, dynamic> inputChannel;
  final MotuDatastoreApi datastoreApiInstance;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> auxes;
  final AsyncSnapshot<Map<String, dynamic>> snapshot;

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
