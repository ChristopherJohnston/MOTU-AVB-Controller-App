import 'package:flutter/material.dart';
import 'package:motu_control/api/motu.dart';
import 'package:motu_control/components/channel.dart';
import 'package:motu_control/components/main_scaffold.dart';
import 'package:go_router/go_router.dart';

Widget buildMixerFaders(
  BuildContext context,
  List<ChannelDefinition> inputChannels,
  List<ChannelDefinition> auxChannels,
  MotuDatastoreApi datastoreApiInstance,
  AsyncSnapshot<Datastore> snapshot,
  ChannelType outputType,
  int outputChannel,
) {
  List<Widget> children;
  List<Widget> faders = [];

  // Iterate the channels dictionary to dynamically
  // generate the fader row.
  for (ChannelDefinition inputChannel in inputChannels) {
    faders.add(Channel(
      inputChannel.name,
      inputChannel.index,
      snapshot.data!,
      datastoreApiInstance.toggleBoolean,
      datastoreApiInstance.setDouble,
      type: inputChannel.type,
      outputType: outputType,
      outputChannel: outputChannel,
      channelClicked: (ChannelType inputChannelType, int channelNumber) {
        context.go('/${inputChannelType.name}/$channelNumber');
      },
    ));
  }

  // mix/main/<index>/matrix/enable
  // mix/main/<index>/matrix/mute
  // mix/main/<index>/matrix/fader

  // mix/monitor/<index>/matrix/enable
  // mix/monitor/<index>/matrix/mute
  // mix/monitor/<index>/matrix/fader

  // Add the output fader for the Main & Mon mixes
  faders.addAll([
    const SizedBox(width: 20),
    Channel(
      "Main",
      0,
      snapshot.data!,
      datastoreApiInstance.toggleBoolean,
      datastoreApiInstance.setDouble,
      type: ChannelType.main,
    ),
    Channel(
      "Monitor",
      0,
      snapshot.data!,
      datastoreApiInstance.toggleBoolean,
      datastoreApiInstance.setDouble,
      type: ChannelType.monitor,
    ),
    const SizedBox(width: 20),
  ]);

  faders.addAll(auxChannels.map(
    (a) {
      return Channel(
        a.name,
        a.index,
        snapshot.data!,
        datastoreApiInstance.toggleBoolean,
        datastoreApiInstance.setDouble,
        type: a.type,
        channelClicked: (ChannelType inputChannelType, int channelNumber) {
          context.go('/${inputChannelType.name}/$channelNumber');
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

class MixerScreen extends StatefulWidget {
  final List<ChannelDefinition> inputChannels;
  final MotuDatastoreApi datastoreApiInstance;
  final List<ChannelDefinition> groups;
  final List<ChannelDefinition> auxes;
  final AsyncSnapshot<Datastore> snapshot;

  const MixerScreen({
    required this.inputChannels,
    required this.datastoreApiInstance,
    required this.snapshot,
    required this.groups,
    required this.auxes,
    super.key,
  });

  @override
  State<MixerScreen> createState() => _MixerScreenState();
}

class _MixerScreenState extends State<MixerScreen> {
  ChannelType outputType = ChannelType.chan;
  int outputChannel = 0;

  void onFaderChange(ChannelType type, int channel) {
    setState(() {
      outputType = type;
      outputChannel = channel;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> outputChannels = [
      {
        "type": ChannelType.chan,
        "name": "Inputs",
        "channel": 0,
        "icon": Icons.mic
      },
      {
        "type": ChannelType.main,
        "name": "Main",
        "channel": 0,
        "icon": Icons.speaker
      },
      {
        "type": ChannelType.reverb,
        "name": "Reverb",
        "channel": 0,
        "icon": Icons.double_arrow
      },
    ];

    return MainScaffold(
      actions: [
        const Text("On Fader:"),
        Row(
          children: outputChannels.map((output) {
            return IconButton(
              onPressed: () => onFaderChange(output["type"], output["channel"]),
              icon: Icon(output["icon"] as IconData),
              selectedIcon: Icon(
                output["icon"] as IconData,
                color: Colors.purple,
              ),
              hoverColor: Colors.purple.withAlpha(150),
              highlightColor: Colors.purple,
              isSelected: (outputType == output["type"] &&
                  outputChannel == output["channel"]),
            );
          }).toList(),
        ),
        DropdownMenu<int>(
          hintText: "Select a Group.",
          label: const Text("Group"),
          leadingIcon: Icon(
            Icons.group,
            color: (outputType == ChannelType.group)
                ? Colors.purple
                : Colors.white,
          ),
          dropdownMenuEntries: widget.groups.map(
            (ChannelDefinition group) {
              return DropdownMenuEntry<int>(
                value: group.index,
                label: group.name,
              );
            },
          ).toList(),
          onSelected: (int? value) =>
              onFaderChange(ChannelType.group, value ?? 0),
        ),
        DropdownMenu<int>(
          hintText: "Select an Aux.",
          label: const Text("Aux"),
          leadingIcon: Icon(
            Icons.headphones,
            color:
                (outputType == ChannelType.aux) ? Colors.purple : Colors.white,
          ),
          dropdownMenuEntries: widget.auxes.map(
            (ChannelDefinition aux) {
              return DropdownMenuEntry<int>(
                value: aux.index,
                label: aux.name,
              );
            },
          ).toList(),
          onSelected: (int? value) =>
              onFaderChange(ChannelType.aux, value ?? 0),
        ),
      ],
      body: buildMixerFaders(
        context,
        widget.inputChannels,
        widget.auxes,
        widget.datastoreApiInstance,
        widget.snapshot,
        outputType,
        outputChannel,
      ),
    );
  }
}
