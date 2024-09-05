import 'package:flutter/material.dart';
import 'package:motu_control/api/motu.dart';
import 'package:motu_control/components/channel.dart';
import 'package:motu_control/components/main_scaffold.dart';
import 'package:go_router/go_router.dart';

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

// levels: http://1248.local/meters?meters=mix/level:ext/input

Widget buildMixerFaders(
  BuildContext context,
  List<Map<String, dynamic>> inputChannels,
  List<Map<String, dynamic>> auxChannels,
  MotuDatastoreApi datastoreApiInstance,
  AsyncSnapshot<Map<String, dynamic>> snapshot,
  String outputPrefix,
  int outputChannel,
) {
  List<Widget> children;
  List<Widget> faders = [];

  // Iterate the channels dictionary to dynamically
  // generate the fader row.
  for (Map<String, dynamic> inputChannel in inputChannels) {
    faders.add(Channel(
      inputChannel["name"],
      inputChannel["channel"],
      snapshot.data!,
      datastoreApiInstance.toggleBoolean,
      datastoreApiInstance.setDouble,
      prefix: inputChannel["type"],
      outputPrefix: outputPrefix,
      outputChannel: outputChannel,
      channelClicked: (String inputChannelType, int channelNumber) {
        context.go('/$inputChannelType/$channelNumber');
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
      prefix: "main",
    ),
    Channel(
      "Monitor",
      0,
      snapshot.data!,
      datastoreApiInstance.toggleBoolean,
      datastoreApiInstance.setDouble,
      prefix: "monitor",
    ),
    const SizedBox(width: 20),
  ]);

  faders.addAll(auxChannels.map(
    (a) {
      return Channel(
        a["name"],
        a["channel"],
        snapshot.data!,
        datastoreApiInstance.toggleBoolean,
        datastoreApiInstance.setDouble,
        prefix: "aux",
        channelClicked: (String inputChannelType, int channelNumber) {
          context.go('/$inputChannelType/$channelNumber');
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
  final List<Map<String, dynamic>> inputChannels;
  final MotuDatastoreApi datastoreApiInstance;
  final List<Map<String, dynamic>> groups;
  final List<Map<String, dynamic>> auxes;
  final AsyncSnapshot<Map<String, dynamic>> snapshot;

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
  String outputPrefix = "input";
  int outputChannel = 0;

  void onFaderChange(String newPrefix, int channel) {
    setState(() {
      outputPrefix = newPrefix;
      outputChannel = channel;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> outputChannels = [
      {"prefix": "input", "name": "Input", "channel": 0, "icon": Icons.mic},
      {"prefix": "main", "name": "Main", "channel": 0, "icon": Icons.speaker},
      {
        "prefix": "reverb",
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
              onPressed: () =>
                  onFaderChange(output["prefix"], output["channel"]),
              icon: Icon(output["icon"] as IconData),
              selectedIcon: Icon(
                output["icon"] as IconData,
                color: Colors.purple,
              ),
              hoverColor: Colors.purple.withAlpha(150),
              highlightColor: Colors.purple,
              isSelected: (outputPrefix == output["prefix"] &&
                  outputChannel == output["channel"]),
            );
          }).toList(),
        ),
        DropdownMenu<int>(
          hintText: "Select a Group.",
          label: const Text("Group"),
          leadingIcon: Icon(
            Icons.group,
            color: (outputPrefix == "group") ? Colors.purple : Colors.white,
          ),
          dropdownMenuEntries: widget.groups.map(
            (Map<String, dynamic> group) {
              return DropdownMenuEntry<int>(
                value: group["channel"],
                label: group["name"],
              );
            },
          ).toList(),
          onSelected: (int? value) => onFaderChange("group", value ?? 0),
        ),
        DropdownMenu<int>(
          hintText: "Select an Aux.",
          label: const Text("Aux"),
          leadingIcon: Icon(
            Icons.headphones,
            color: (outputPrefix == "aux") ? Colors.purple : Colors.white,
          ),
          dropdownMenuEntries: widget.auxes.map(
            (Map<String, dynamic> aux) {
              return DropdownMenuEntry<int>(
                value: aux["channel"],
                label: aux["name"],
              );
            },
          ).toList(),
          onSelected: (int? value) => onFaderChange("aux", value ?? 0),
        ),
      ],
      body: buildMixerFaders(
          context,
          widget.inputChannels,
          widget.auxes,
          widget.datastoreApiInstance,
          widget.snapshot,
          outputPrefix,
          outputChannel),
    );
  }
}
