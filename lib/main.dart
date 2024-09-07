import 'package:flutter/material.dart';
import 'package:motu_control/utils/constants.dart';
import 'package:motu_control/utils/screen.dart';
import 'package:motu_control/utils/settings.dart';
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
      builder: (context, state) {
        final page = state.pathParameters["page"];
        final channel =
            int.tryParse(state.pathParameters["channel"] ?? "0") ?? 0;

        final deviceUrl = state.uri.queryParameters["deviceUrl"];
        final settings = state.uri.queryParameters["settings"];

        InputSettings? settingsObj =
            (settings != null) ? InputSettings.fromBase64(settings) : null;

        return MainPage(
          screen: Screen.values.firstWhere((e) => e.name == page),
          channel: channel,
          deviceUrl: deviceUrl ?? settingsObj?.deviceUrl,
          settings: settingsObj,
        );
      },
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
  final String? deviceUrl;
  final InputSettings settings;

  MainPage({
    super.key,
    this.screen = Screen.mixer,
    this.channel = 0,
    this.deviceUrl,
    InputSettings? settings,
  }) : settings = settings ?? InputSettings.defaults();

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

    if (widget.deviceUrl != null) {
      // use querystring-provided url
      createPollingInstance(widget.deviceUrl!);
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
                  auxInputList: widget.settings.auxInputList,
                  groupInputList: widget.settings.groupInputList,
                  groupList: widget.settings.groupList,
                  auxList: widget.settings.auxList,
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
