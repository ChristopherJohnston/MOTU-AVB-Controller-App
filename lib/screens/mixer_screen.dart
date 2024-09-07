import 'package:flutter/material.dart';
import 'package:motu_control/api/mixer_state.dart';
import 'package:motu_control/api/datastore_api.dart';
import 'package:motu_control/components/channel.dart';
import 'package:motu_control/components/main_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:motu_control/utils/constants.dart';
import 'package:motu_control/api/channel_state.dart';

class MixerScreen extends StatefulWidget {
  final MixerState state;
  final MotuDatastoreApi datastoreApiInstance;

  const MixerScreen({
    required this.state,
    required this.datastoreApiInstance,
    super.key,
  });

  @override
  State<MixerScreen> createState() => _MixerScreenState();
}

class _MixerScreenState extends State<MixerScreen> {
  ChannelType outputType = ChannelType.chan;
  int outputChannel = 0;

  ///
  /// Builds a UI containing all of the mixer faders, including
  /// input channels, groups, reverb, main/mon and auxes.
  ///
  Widget buildMixerFaders(BuildContext context) {
    List<Widget> faders = [];

    // Iterate the input channels to dynamically generate the fader row
    for (ChannelState inputChannel
        in widget.state.allInputChannelStates.values) {
      faders.add(Channel(
        state: inputChannel,
        toggleBoolean: widget.datastoreApiInstance.toggleBoolean,
        valueChanged: widget.datastoreApiInstance.setDouble,
        output: (outputType != ChannelType.chan)
            ? widget.state.outputStates[outputType]![outputChannel]!
            : null,
        channelClicked: (ChannelType inputChannelType, int channelNumber) {
          context.go('/${inputChannelType.name}/$channelNumber');
        },
      ));
    }

    // Add Group Channels
    for (int groupIndex in widget.state.allGroupsList) {
      faders.add(Channel(
        state: widget.state.outputStates[ChannelType.group]![groupIndex]!,
        toggleBoolean: widget.datastoreApiInstance.toggleBoolean,
        valueChanged: widget.datastoreApiInstance.setDouble,
        output: (![ChannelType.chan, ChannelType.group].contains(outputType))
            ? widget.state.outputStates[outputType]![outputChannel]!
            : null,
      ));
    }

    // Add Reverb Channel
    faders.add(Channel(
      state: widget.state.outputStates[ChannelType.reverb]![0]!,
      toggleBoolean: widget.datastoreApiInstance.toggleBoolean,
      valueChanged: widget.datastoreApiInstance.setDouble,
      output: (![ChannelType.chan, ChannelType.reverb, ChannelType.group]
              .contains(outputType))
          ? widget.state.outputStates[outputType]![outputChannel]!
          : null,
    ));

    // Add the output fader for the Main & Mon mixes
    faders.addAll([
      const SizedBox(width: 20),
      Channel(
        state: widget.state.outputStates[ChannelType.main]![0]!,
        toggleBoolean: widget.datastoreApiInstance.toggleBoolean,
        valueChanged: widget.datastoreApiInstance.setDouble,
      ),
      Channel(
        state: widget.state.outputStates[ChannelType.monitor]![0]!,
        toggleBoolean: widget.datastoreApiInstance.toggleBoolean,
        valueChanged: widget.datastoreApiInstance.setDouble,
      ),
      const SizedBox(width: 20),
    ]);

    // // Add Aux Faders
    faders.addAll(widget.state.outputStates[ChannelType.aux]!.values.map(
      (aux) {
        return Channel(
          state: aux,
          toggleBoolean: widget.datastoreApiInstance.toggleBoolean,
          valueChanged: widget.datastoreApiInstance.setDouble,
          channelClicked: (ChannelType inputChannelType, int channelNumber) {
            context.go('/${inputChannelType.name}/$channelNumber');
          },
        );
      },
    ));

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
      actions: [
        OnFaderSelection(
          outputType: outputType,
          outputChannel: outputChannel,
          groups: widget.state.outputStates[ChannelType.group]!.values.toList(),
          auxes: widget.state.outputStates[ChannelType.aux]!.values.toList(),
          onSelectionChanged: (ChannelType type, int channel) {
            // Set the output which is "on faders"
            setState(() {
              outputType = type;
              outputChannel = channel;
            });
          },
        )
      ],
      body: buildMixerFaders(context),
    );
  }
}

class OutputChannel {
  final ChannelType type;
  final Color color;
  final String name;
  final int channel;
  final IconData icon;

  OutputChannel({
    required this.type,
    required this.color,
    required this.name,
    required this.channel,
    required this.icon,
  });
}

class OnFaderSelection extends StatelessWidget {
  final List<OutputChannel> outputChannels = [
    OutputChannel(
      type: ChannelType.chan,
      color: kChannelColor,
      name: "Inputs",
      channel: 0,
      icon: kInputIcon,
    ),
    OutputChannel(
      type: ChannelType.main,
      color: kMainColor,
      name: "Main",
      channel: 0,
      icon: kMainIcon,
    ),
    OutputChannel(
      type: ChannelType.reverb,
      color: kReverbColor,
      name: "Reverb",
      channel: 0,
      icon: kReverbIcon,
    ),
  ];

  final ChannelType outputType;
  final int outputChannel;
  final List<ChannelState> groups;
  final List<ChannelState> auxes;
  final Function(ChannelType, int)? onSelectionChanged;

  OnFaderSelection({
    super.key,
    required this.outputType,
    required this.outputChannel,
    this.groups = const [],
    this.auxes = const [],
    this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "On Fader:",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: kChannelTypeColors[outputType],
          ),
        ),
        Row(
          children: outputChannels.map((output) {
            return IconButton(
              onPressed: () => onSelectionChanged!(
                output.type,
                output.channel,
              ),
              icon: Icon(output.icon),
              selectedIcon: Icon(
                output.icon,
                color: output.color,
              ),
              hoverColor: output.color.withAlpha(150),
              highlightColor: output.color,
              isSelected: (outputType == output.type &&
                  outputChannel == output.channel),
            );
          }).toList(),
        ),
        SendDropdown(
          type: ChannelType.group,
          sends: groups,
          selectedType: outputType,
          label: const Text("Group"),
          hintText: "Select a Group.",
          activeColor: kGroupColor,
          icon: kGroupIcon,
          onSelectionChanged: onSelectionChanged,
        ),
        SendDropdown(
          type: ChannelType.aux,
          sends: auxes,
          selectedType: outputType,
          label: const Text("Aux"),
          hintText: "Select an Aux.",
          activeColor: kAuxColor,
          icon: kAuxIcon,
          onSelectionChanged: onSelectionChanged,
        ),
      ],
    );
  }
}

class SendDropdown extends StatelessWidget {
  const SendDropdown({
    super.key,
    required this.type,
    required this.sends,
    required this.selectedType,
    this.icon = kGroupIcon,
    this.label = const Text("Send"),
    this.hintText = "Select a Send",
    required this.onSelectionChanged,
    this.activeColor = kGroupColor,
    this.inactiveColor = Colors.white,
  });

  final ChannelType type;
  final Widget label;
  final String hintText;
  final ChannelType selectedType;
  final Color activeColor;
  final Color inactiveColor;
  final List<ChannelState> sends;
  final IconData icon;
  final Function(ChannelType p1, int p2)? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<int>(
      hintText: hintText,
      label: label,
      leadingIcon: Icon(
        icon,
        color: (selectedType == type) ? activeColor : inactiveColor,
      ),
      dropdownMenuEntries: sends.map(
        (ChannelState send) {
          return DropdownMenuEntry<int>(
            value: send.index,
            label: send.name,
          );
        },
      ).toList(),
      onSelected: (int? value) => onSelectionChanged!(type, value ?? 0),
    );
  }
}
