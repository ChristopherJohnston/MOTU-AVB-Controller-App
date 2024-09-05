import 'package:flutter/material.dart';

class SendHeader extends StatelessWidget {
  final int selectedChannel;
  final Function(int?)? channelChanged;
  final List<Map<String, dynamic>> sends;
  final String label;
  final IconData iconData;

  const SendHeader({
    super.key,
    required this.selectedChannel,
    required this.sends,
    this.label = "Channel",
    this.iconData = Icons.headphones,
    this.channelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropdownMenu<int>(
          label: Text(label),
          initialSelection: selectedChannel,
          hintText: "Select an output.",
          leadingIcon: Icon(
            iconData,
            color: Colors.white,
          ),
          dropdownMenuEntries: sends.map(
            (entry) {
              return DropdownMenuEntry<int>(
                value: entry["channel"],
                label: entry["name"],
              );
            },
          ).toList(),
          onSelected: channelChanged,
        ),
      ],
    );
  }
}
