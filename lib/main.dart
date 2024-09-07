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

        String? deviceUrl = state.uri.queryParameters["deviceUrl"];
        String? settings = state.uri.queryParameters["settings"];

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
  final InputSettings? settings;

  const MainPage({
    super.key,
    this.screen = Screen.mixer,
    this.channel = 0,
    this.deviceUrl,
    this.settings,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  MotuDatastoreApi? datastoreApiInstance;
  InputSettings? settings;

  void createPollingInstance(String apiBaseUrl, InputSettings settingsObj) {
    setState(() {
      settings = settingsObj;
      datastoreApiInstance = MotuDatastoreApi(
        apiBaseUrl,
        clientId: clientId,
      );
    });
  }

  @override
  void initState() {
    super.initState();

    getSharedPreferences().then(
      (prefs) async {
        InputSettings? settingsObj;
        if (widget.settings == null) {
          // Try to get settings string from shared preferences
          String? settingsStr = prefs.getString('settings');
          settingsObj = (settingsStr != null)
              ? InputSettings.fromBase64(settingsStr)
              : InputSettings.defaults();
        } else {
          // Settings was in querystring - Write to shared preferences
          prefs.setString('settings', widget.settings!.base64EncodedString!);
          settingsObj = widget.settings;
        }

        if (widget.deviceUrl != null || settingsObj?.deviceUrl != null) {
          // device url was in querystring or settings. Write to shared preferences
          String apiBaseUrl = widget.deviceUrl ?? settingsObj!.deviceUrl!;
          prefs.setString('apiBaseUrl', apiBaseUrl);
          createPollingInstance(apiBaseUrl, settingsObj!);
        } else {
          // Try to get device url from shared preferences, otherwise show chooser
          if (prefs.getString('apiBaseUrl') == null) {
            await showServerChooser(context, prefs).then((value) {
              createPollingInstance(
                  prefs.getString('apiBaseUrl'), settingsObj!);
            });
          } else {
            createPollingInstance(prefs.getString('apiBaseUrl'), settingsObj!);
          }
        }
      },
    );
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
                  auxInputList: settings!.auxInputList,
                  groupInputList: settings!.groupInputList,
                  groupList: settings!.groupList,
                  auxList: settings!.auxList,
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
