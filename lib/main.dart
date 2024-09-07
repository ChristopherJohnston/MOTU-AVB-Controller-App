import 'package:flutter/material.dart';
import 'package:motu_control/utils/constants.dart';
import 'package:motu_control/utils/screen.dart';
import 'package:motu_control/api/datastore.dart';
import 'package:motu_control/api/channel_state.dart';
import 'package:motu_control/api/datastore_api.dart';
import 'package:motu_control/api/mixer_state.dart';
import 'package:motu_control/screens/channel_screen.dart';
import 'package:motu_control/screens/send_screen.dart';
import 'package:motu_control/screens/error_screen.dart';
import 'package:motu_control/screens/mixer_screen.dart';
import 'package:motu_control/screens/waiting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:motu_control/components/server_chooser.dart';

//
// SETTINGS
//

// String? deviceUrl = "http://1248.local/datastore";
//String? deviceUrl = "http://localhost:8888/datastore";
String? deviceUrl;

// In Touch console, fader visibility is stored in browser local storage
// at touch-console_faderVisibility

// Channels to show as inputs to each aux.
Map<ChannelType, Map<int, List<int>>> auxInputList = {
  ChannelType.chan: {
    0: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
    2: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
    4: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
    6: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
    8: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
    10: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
    12: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
  },
  ChannelType.group: {
    0: [0],
    2: [0],
    4: [0],
    6: [0],
    8: [0],
    10: [0],
    12: [0],
  }
};

// Channels to show as inputs to each group.
Map<int, List<int>> groupInputList = {
  0: [24, 25, 26, 27, 28, 29, 30, 31, 32, 34],
  2: [],
  4: [],
};

// Active Groups
List<int> groupList = [0, 2, 4];

// Active Auxes
List<int> auxList = [0, 2, 4, 6, 8, 10, 12];

//
// END SETTINGS
//

///
/// Mixer State
///

// Unique clientId for the Motu API.
final int clientId = MotuDatastoreApi.getClientId();

// Create a single route for the app. We will determine
// which page to display in the build method,
// depending on the page parameter
final _router = GoRouter(
  initialLocation: "/mixer/0",
  routes: [
    GoRoute(
      path: "/:page/:channel",
      builder: (context, state) => MainPage(
        screen: Screen.values
            .firstWhere((e) => e.name == state.pathParameters["page"]),
        channel: int.tryParse(state.pathParameters["channel"] ?? "0") ?? 0,
      ),
    ),
  ],
);

///
/// Main entry point to the application
///
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MOTUControlPanel());
}

///
/// Main application widget
///
class MOTUControlPanel extends StatelessWidget {
  const MOTUControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MOTU Control Panel',
      theme: kMainTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

getSharedPreferences() async {
  return await SharedPreferences.getInstance();
}

///
/// Main (and only) page of the app
/// maintains a Motu Datastore instance and
/// passes mixer state to the pages.
///
class MainPage extends StatefulWidget {
  final int channel;
  final Screen screen;

  const MainPage({
    super.key,
    this.screen = Screen.mixer,
    this.channel = 0,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  MotuDatastoreApi? datastoreApiInstance;

  void createPollingInstance(String apiBaseUrl) {
    setState(() {
      datastoreApiInstance = MotuDatastoreApi(
        apiBaseUrl,
        clientId: clientId,
      );
    });
  }

  @override
  void initState() {
    super.initState();

    if (deviceUrl != null) {
      createPollingInstance(deviceUrl!);
    } else {
      // Get App preferences to determine MOTU URL
      getSharedPreferences().then(
        (prefs) async {
          if (prefs.getString('apiBaseUrl') == null) {
            await showServerChooser(context, prefs).then((value) {
              createPollingInstance(prefs.getString('apiBaseUrl'));
            });
          } else {
            createPollingInstance(prefs.getString('apiBaseUrl'));
          }
        },
      );
    }
  }

  @override
  void dispose() {
    datastoreApiInstance?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (datastoreApiInstance == null) {
      return const WaitingScreen(message: "Waiting for server URL");
    }

    return StreamBuilder<Datastore>(
      stream: datastoreApiInstance!.stream,
      builder: (
        BuildContext context,
        AsyncSnapshot<Datastore> snapshot,
      ) {
        if (snapshot.hasError) {
          return ErrorScreen(snapshot);
        } else {
          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.done:
              return const WaitingScreen();
            case ConnectionState.active:
              {
                // Generate the mixer state from the datastore.
                // This will be passed down to the widgets.
                MixerState mixerState = MixerState.fromDatastore(
                  datastore: snapshot.data!,
                  auxInputList: auxInputList,
                  groupInputList: groupInputList,
                  groupList: groupList,
                  auxList: auxList,
                );

                switch (widget.screen) {
                  case Screen.chan:
                    return ChannelScreen(
                      index: widget.channel,
                      state: mixerState,
                      datastoreApiInstance: datastoreApiInstance!,
                    );
                  case Screen.aux:
                    return SendScreen(
                      sendType: ChannelType.aux,
                      channel: widget.channel,
                      state: mixerState,
                      datastoreApiInstance: datastoreApiInstance!,
                    );
                  case Screen.group:
                    return SendScreen(
                      sendType: ChannelType.group,
                      headerIcon: kGroupIcon,
                      channel: widget.channel,
                      state: mixerState,
                      datastoreApiInstance: datastoreApiInstance!,
                    );
                  case Screen.reverb:
                    return SendScreen(
                      sendType: ChannelType.reverb,
                      headerIcon: kReverbIcon,
                      channel: widget.channel,
                      state: mixerState,
                      datastoreApiInstance: datastoreApiInstance!,
                    );
                  default:
                    return MixerScreen(
                      state: mixerState,
                      datastoreApiInstance: datastoreApiInstance!,
                    );
                }
              }
          }
        }
      },
    );
  }
}
