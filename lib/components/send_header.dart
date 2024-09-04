import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SendHeader extends StatelessWidget {
  final int selectedChannel;
  final Function(int?)? channelChanged;
  final List<Map<String, dynamic>> sends;

  const SendHeader({
    super.key,
    required this.selectedChannel,
    required this.sends,
    this.channelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
          child: SvgPicture.asset(
            'assets/motu-logo.svg',
            width: 120,
            color: Colors.white,
          ),
        ),
        DropdownMenu<int>(
          initialSelection: selectedChannel,
          hintText: "Select an output.",
          leadingIcon: const Icon(
            Icons.headphones,
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
