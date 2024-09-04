import 'package:flutter/material.dart';
import 'package:motu_control/components/main_scaffold.dart';

class WaitingScreen extends StatelessWidget {
  const WaitingScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const MainScaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(),
          ),
          SizedBox(
            height: 20,
          ),
          Text(
            'Connecting to MOTU',
            style: TextStyle(color: Colors.white),
          )
        ],
      ),
    );
  }
}
