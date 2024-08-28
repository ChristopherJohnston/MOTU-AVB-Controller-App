import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:motu_control/api/motu.dart';
import 'package:motu_control/components/aux_channel.dart';
import 'package:motu_control/components/channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

final _router = GoRouter(routes: [
  GoRoute(
    path: "/",
    builder: (context, state) => const MainPage("0"),
  ),
  GoRoute(
      path: "/aux/:aux",
      builder: (context, state) => MainPage(state.pathParameters["aux"] ?? "0"))
]);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MOTUControlPanel());
}

class MOTUControlPanel extends StatelessWidget {
  const MOTUControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MOTU Control Panel',
      theme: ThemeData(
          primarySwatch: Colors.red,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFF1F2022)),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

// Channel
// /chan/0/matrix/solo
// /chan/0/matrix/mute
// /chan/0/matrix/pan
// /chan/0/matrix/fader

// /chan/0/matrix/reverb/send
// /chan/0/matrix/reverb/pan

// Aux Send
// /chan/1/matrix/aux/0/send
// /chan/1/matrix/aux/0/pan
// /aux/1/matrix/mute
// /aux/1/matrix/panner
// /aux/1/matrix/fader

// Group Send
// /chan/1/matrix/group/0/send
// /chan/1/matrix/group/0/pan
// /group/1/matrix/aux/1/send

// Reverb

// /reverb/0/matrix/aux/1/send

final List<Map<String, dynamic>> auxChannels = [
  {"channel": 0, "type": "chan"},
  {"channel": 1, "type": "chan"},
  {"channel": 2, "type": "chan"},
  {"channel": 3, "type": "chan"},
  {"channel": 4, "type": "chan"},
  {"channel": 6, "type": "chan"},
  {"channel": 8, "type": "chan"},
  {"channel": 10, "type": "chan"},
  {"channel": 12, "type": "chan"},
  {"channel": 14, "type": "chan"},
  {"channel": 16, "type": "chan"},
  {"channel": 18, "type": "chan"},
  {"channel": 20, "type": "chan"},
  {"channel": 22, "type": "chan"},
  {"channel": 23, "type": "chan"},
  {"channel": 35, "type": "chan"},
  {"channel": 0, "type": "group"},
  {"channel": 0, "type": "reverb"},
];

class MainPage extends StatefulWidget {
  final String aux;

  const MainPage(this.aux, {super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ApiPolling? apiPollingInstance;
  Stream<Map<String, dynamic>>? apiPollingStream;
  String? apiBaseUrl;

  getSharedPreferences() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> _showMyDialog(SharedPreferences prefs) async {
    final myController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
                  prefs.setString('apiBaseUrl', myController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    // Get App preferences
    getSharedPreferences().then((prefs) async {
      if (prefs.getString('apiBaseUrl') == null) {
        log('Missing apiBaseUrl, request to user...');

        await _showMyDialog(prefs).then((value) {
          apiBaseUrl = prefs.getString('apiBaseUrl');
          setState(() {
            apiPollingInstance = ApiPolling(apiBaseUrl!);
            apiPollingStream = apiPollingInstance!.stream;
          });
        });
      } else {
        apiBaseUrl = prefs.getString('apiBaseUrl');
        setState(() {
          apiPollingInstance = ApiPolling(apiBaseUrl!);
          apiPollingStream = apiPollingInstance!.stream;
        });
      }
    });
    // apiBaseUrl = "http://localhost:8888/datastore/";
    // setState(() {
    //   apiPollingInstance = ApiPolling(apiBaseUrl!);
    //   apiPollingStream = apiPollingInstance!.stream;
    // });
  }

  @override
  void dispose() {
    apiPollingInstance?.dispose();
    super.dispose();
  }

  List<Widget> buildAuxFaders(
    AsyncSnapshot<Map<String, dynamic>> snapshot,
  ) {
    List<Widget> children;
    List<Widget> faders = [];

    // Determine which aux mix is active.
    // Generally they are 2 channels for Left and Right, so always
    // take the Odd (Left) channel.
    int aux = int.parse(widget.aux);
    if (aux % 2 > 0) {
      aux -= 1;
    }

    // Iterate the auxChannels dictionary to dynamically
    // generate the fader row.
    for (Map<String, dynamic> channel in auxChannels) {
      String name = "<No Name>";
      if (channel["type"] == "chan") {
        name = apiPollingInstance!.getMixerChannelName(channel["channel"]);
      } else if (channel["type"] == "group") {
        name = apiPollingInstance!.getGroupName(channel["channel"]);
      } else if (channel["type"] == "reverb") {
        name = apiPollingInstance!.getReverbName(channel["channel"]);
      }

      faders.add(
        AuxChannel(name, aux, channel["channel"], snapshot.data!,
            apiPollingInstance!.setDouble,
            prefix: channel["type"]),
      );
    }
    faders.add(
      const SizedBox(width: 20),
    );

    // Add the output fader for the aux mix
    faders.add(Channel(
      "Output",
      aux,
      snapshot.data!,
      apiPollingInstance!.toggleBoolean,
      apiPollingInstance!.setDouble,
      prefix: "aux",
    ));

    // Build the page: Logo, Row, Faders
    children = [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
            child: SvgPicture.asset(
              'assets/motu-logo.svg',
              width: 120,
            ),
          ),
        ],
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Aux: ${apiPollingInstance!.getAuxName(aux)}",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: faders),
      ),
    ];

    return children;
  }

  /// Buiild the page from the AVB datastore snapshot
  List<Widget> buildFromSnapshot(
    BuildContext context,
    AsyncSnapshot<Map<String, dynamic>> snapshot,
  ) {
    List<Widget> children;

    switch (snapshot.connectionState) {
      case ConnectionState.none:
        children = [];
        break;
      case ConnectionState.waiting:
        children = [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(
            height: 20,
          ),
          const Text(
            'Connecting to MOTU',
            style: TextStyle(color: Colors.white),
          )
        ];
        break;
      case ConnectionState.active:
        // For now we're just looking at aux mixes (based on the route)
        // We could in future also create faders for groups and main mixes.
        children = buildAuxFaders(snapshot);
        break;
      case ConnectionState.done:
        // Since we are Long Polling, connection should never be "done".
        children = [];
        break;
    }

    return children;
  }

  Widget buildFromStream(
    BuildContext context,
    AsyncSnapshot<Map<String, dynamic>> snapshot,
  ) {
    List<Widget> children;

    if (snapshot.hasError) {
      children = [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('Error: ${snapshot.error}'),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Stack trace: ${snapshot.stackTrace}'),
        ),
      ];
    } else {
      children = buildFromSnapshot(
        context,
        snapshot,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          padding: const EdgeInsets.fromLTRB(40.0, 40.0, 40.0, 10),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: StreamBuilder<Map<String, dynamic>>(
                  stream: apiPollingStream!,
                  builder: buildFromStream,
                ),
              ),
            ],
          )),
    );
  }
}
