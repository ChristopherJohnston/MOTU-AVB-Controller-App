import 'package:flutter/material.dart';
import 'package:motu_control/components/main_scaffold.dart';

class WaitingScreen extends StatelessWidget {
  final String message;

  const WaitingScreen({
    super.key,
    this.message = 'Connecting to MOTU',
  });

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(
            height: 20,
          ),
          Text(
            message,
            style: const TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }
}
