import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showServerChooser(
    BuildContext context, SharedPreferences prefs) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return ServerChooser(
        onSave: (String server) {
          prefs.setString('apiBaseUrl', server);
          Navigator.of(context).pop();
        },
      );
    },
  );
}

class ServerChooser extends StatelessWidget {
  final myController = TextEditingController();
  final Function(String)? onSave;

  ServerChooser({
    super.key,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Insert your MOTU interface API URL'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            const Text('It should look like this:'),
            const Text('http://localhost:1280/some-characters/datastore'),
            TextField(
              controller: myController,
              decoration: const InputDecoration(
                hintText: 'URL',
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Save'),
          onPressed: () {
            if (myController.text.isNotEmpty) {
              if (onSave != null) {
                onSave!(myController.text);
              }
            }
          },
        ),
      ],
    );
  }
}
