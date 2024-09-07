import 'package:flutter/material.dart';
import 'package:motu_control/components/main_scaffold.dart';
import 'package:motu_control/api/datastore.dart';

class ErrorScreen extends StatelessWidget {
  final AsyncSnapshot<Datastore> snapshot;

  const ErrorScreen(
    this.snapshot, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('Error: ${snapshot.error}'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Stack trace: ${snapshot.stackTrace}'),
          ),
        ],
      ),
    );
  }
}
