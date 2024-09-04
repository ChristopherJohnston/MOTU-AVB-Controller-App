import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:motu_control/api/motu.dart';
import 'package:motu_control/screens/send_screen.dart';
import 'package:motu_control/screens/error_screen.dart';
import 'package:motu_control/screens/mixer_screen.dart';
import 'package:motu_control/screens/waiting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:motu_control/components/server_chooser.dart';

final int clientId = ApiPolling.getClientId();

enum Page { mixer, group, aux, reverb }

final _router = GoRouter(
  initialLocation: "/mixer/0",
  routes: [
    GoRoute(
      path: "/:page/:channel",
      builder: (context, state) => MainPage(
        page: Page.values
            .firstWhere((e) => e.name == state.pathParameters["page"]),
        channel: state.pathParameters["channel"] ?? "0",
      ),
    ),
  ],
);

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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1F2022),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1F2022),
        ),
        menuTheme: const MenuThemeData(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(
              Color(0xFF1F2022),
            ),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

getSharedPreferences() async {
  return await SharedPreferences.getInstance();
}

class MainPage extends StatefulWidget {
  final String channel;
  final Page page;

  const MainPage({
    super.key,
    this.page = Page.mixer,
    this.channel = "0",
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  ApiPolling? apiPollingInstance;

  void createPollingInstance(String apiBaseUrl) {
    setState(() {
      apiPollingInstance = ApiPolling(apiBaseUrl, clientId: clientId);
    });
  }

  @override
  void initState() {
    super.initState();

    // Get App preferences
    getSharedPreferences().then(
      (prefs) async {
        if (prefs.getString('apiBaseUrl') == null) {
          log('Missing apiBaseUrl, request to user...');

          await showServerChooser(context, prefs).then((value) {
            createPollingInstance(prefs.getString('apiBaseUrl'));
          });
        } else {
          createPollingInstance(prefs.getString('apiBaseUrl'));
        }
      },
    );
  }

  @override
  void dispose() {
    apiPollingInstance?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: apiPollingInstance!.stream,
      builder: (
        BuildContext context,
        AsyncSnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (snapshot.hasError) {
          return ErrorScreen(snapshot);
        } else {
          // Fader visibility is stored in browser local storage at touch-console_faderVisibility

          Map<int, List<int>> auxInputList = {
            0: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
            2: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
            4: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
            6: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
            8: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
            10: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
            12: [0, 1, 2, 3, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 23, 35],
          };

          Map<int, List<int>> groupInputList = {
            0: [24, 25, 26, 27, 28, 29, 30, 31, 32, 34],
            2: [],
            4: [],
          };
          List<int> groupList = [0, 2, 4];
          List<int> auxList = [0, 2, 4, 6, 8, 10, 12];

          Map<int, List<Map<String, dynamic>>> auxInputChannels = {};
          for (MapEntry<int, List<int>> channel in auxInputList.entries) {
            auxInputChannels[channel.key] = channel.value
                .map((input) => {
                      "channel": input,
                      "type": "chan",
                      "name": apiPollingInstance!.getMixerChannelName(input)
                    })
                .toList();
          }

          Map<int, List<Map<String, dynamic>>> groupChannels = {};

          for (MapEntry<int, List<int>> channel in groupInputList.entries) {
            groupChannels[channel.key] = channel.value
                .map((input) => {
                      "channel": input,
                      "type": "chan",
                      "name": apiPollingInstance!.getMixerChannelName(input)
                    })
                .toList();
          }

          List<int> allInputsList =
              apiPollingInstance!.getChannelList("obank", "Mix In");

          final List<Map<String, dynamic>> allInputChannels = [];
          for (int channel in allInputsList) {
            allInputChannels.add({
              "channel": channel,
              "type": "chan",
              "name": apiPollingInstance!.getMixerChannelName(channel)
            });
          }

          List<Map<String, dynamic>> groups = groupList
              .map((int channel) => {
                    "channel": channel,
                    "type": "group",
                    "name": apiPollingInstance!.getGroupName(channel)
                  })
              .toList();

          final List<Map<String, dynamic>> reverbChannels = [0]
              .map((channel) => {
                    "channel": channel,
                    "type": "reverb",
                    "name": apiPollingInstance!.getReverbName(channel)
                  })
              .toList();

          List<Map<String, dynamic>> auxes = [];
          for (int channel in auxList) {
            auxes.add({
              "channel": channel,
              "type": "aux",
              "name": apiPollingInstance!.getAuxName(channel)
            });
          }

          switch (snapshot.connectionState) {
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.done:
              return const WaitingScreen();
            case ConnectionState.active:
              {
                switch (widget.page) {
                  case Page.aux:
                    int auxChannel = int.tryParse(widget.channel) ?? 0;
                    List<Map<String, dynamic>> inputChannels =
                        auxInputChannels[auxChannel]!;

                    inputChannels.addAll(groups.toList());
                    inputChannels.addAll(reverbChannels.toList());
                    return SendScreen(
                      sendType: "aux",
                      activeSends: auxes,
                      inputChannels: inputChannels,
                      channel: auxChannel,
                      apiPollingInstance: apiPollingInstance!,
                      snapshot: snapshot,
                    );
                  case Page.group:
                    int groupChannel = int.tryParse(widget.channel) ?? 0;
                    return SendScreen(
                      sendType: "group",
                      activeSends: groups,
                      inputChannels: groupChannels[groupChannel]!,
                      channel: groupChannel,
                      apiPollingInstance: apiPollingInstance!,
                      snapshot: snapshot,
                    );
                  case Page.reverb:
                    return SendScreen(
                      sendType: "reverb",
                      activeSends: reverbChannels,
                      inputChannels: allInputChannels,
                      channel: int.tryParse(widget.channel) ?? 0,
                      apiPollingInstance: apiPollingInstance!,
                      snapshot: snapshot,
                    );
                  default:
                    // TODO: add buttons to go to group/reverb/aux screens, with back button to return to previous page
                    return MixerScreen(
                      inputChannels: allInputChannels + groups + reverbChannels,
                      apiPollingInstance: apiPollingInstance!,
                      groups: groups,
                      auxes: auxes,
                      snapshot: snapshot,
                    );
                }
              }
          }
        }
      },
    );
  }
}
