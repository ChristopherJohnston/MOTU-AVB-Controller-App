import 'package:flutter/material.dart';
import 'package:motu_control/utils/constants.dart';
import 'package:motu_control/api/motu.dart';
import 'package:motu_control/screens/channel_screen.dart';
import 'package:motu_control/screens/send_screen.dart';
import 'package:motu_control/screens/error_screen.dart';
import 'package:motu_control/screens/mixer_screen.dart';
import 'package:motu_control/screens/waiting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:motu_control/components/server_chooser.dart';

// SETTINGS
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

// END SETTINGS

class AppSettings {
  final Map<int, List<ChannelDefinition>> auxInputChannels;
  final Map<int, List<ChannelDefinition>> groupChannels;
  final List<int> allInputsList;
  final List<ChannelDefinition> allInputChannels;
  final List<ChannelDefinition> groups;
  final List<ChannelDefinition> reverbChannels;
  final List<ChannelDefinition> auxes;
  final List<ChannelDefinition> mixerChannels;

  AppSettings({
    required this.auxInputChannels,
    required this.groupChannels,
    required this.allInputsList,
    required this.allInputChannels,
    required this.groups,
    required this.reverbChannels,
    required this.auxes,
  }) : mixerChannels = allInputChannels + groups + reverbChannels;
}

AppSettings setupIO(Datastore datastore) {
  Map<int, List<ChannelDefinition>> auxInputChannels = {};
  for (MapEntry<int, List<int>> channel in auxInputList.entries) {
    auxInputChannels[channel.key] = channel.value
        .map(
          (input) => ChannelDefinition(
            index: input,
            type: ChannelType.chan,
            name: datastore.getMixerChannelName(input),
          ),
        )
        .toList();
  }

  Map<int, List<ChannelDefinition>> groupChannels = {};

  for (MapEntry<int, List<int>> channel in groupInputList.entries) {
    groupChannels[channel.key] = channel.value
        .map(
          (input) => ChannelDefinition(
            index: input,
            type: ChannelType.chan,
            name: datastore.getMixerChannelName(input),
          ),
        )
        .toList();
  }

  List<int> allInputsList = datastore.getChannelList("obank", "Mix In");

  final List<ChannelDefinition> allInputChannels = [];
  for (int channel in allInputsList) {
    allInputChannels.add(ChannelDefinition(
      index: channel,
      type: ChannelType.chan,
      name: datastore.getMixerChannelName(channel),
    ));
  }

  List<ChannelDefinition> groups = groupList
      .map((int channel) => ChannelDefinition(
            index: channel,
            type: ChannelType.group,
            name: datastore.getGroupName(channel),
          ))
      .toList();

  final List<ChannelDefinition> reverbChannels = [0]
      .map((channel) => ChannelDefinition(
            index: channel,
            type: ChannelType.reverb,
            name: datastore.getReverbName(channel),
          ))
      .toList();

  List<ChannelDefinition> auxes = [];
  for (int channel in auxList) {
    auxes.add(ChannelDefinition(
      index: channel,
      type: ChannelType.aux,
      name: datastore.getAuxName(channel),
    ));
  }

  return AppSettings(
    auxInputChannels: auxInputChannels,
    groupChannels: groupChannels,
    allInputsList: allInputsList,
    allInputChannels: allInputChannels,
    groups: groups,
    reverbChannels: reverbChannels,
    auxes: auxes,
  );
}

final int clientId = MotuDatastoreApi.getClientId();

enum Page { chan, mixer, group, aux, reverb }

final _router = GoRouter(
  initialLocation: "/mixer/0",
  routes: [
    GoRoute(
      path: "/:page/:channel",
      builder: (context, state) => MainPage(
        page: Page.values
            .firstWhere((e) => e.name == state.pathParameters["page"]),
        channel: int.tryParse(state.pathParameters["channel"] ?? "0") ?? 0,
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
      theme: kMainTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}

getSharedPreferences() async {
  return await SharedPreferences.getInstance();
}

class MainPage extends StatefulWidget {
  final int channel;
  final Page page;

  const MainPage({
    super.key,
    this.page = Page.mixer,
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

    // Get App preferences
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
                AppSettings settings = setupIO(
                  snapshot.data!,
                );

                switch (widget.page) {
                  case Page.chan:
                    ChannelDefinition inputChannel = settings.allInputChannels
                        .firstWhere((e) => e.index == widget.channel);

                    return ChannelScreen(
                      inputChannel: inputChannel,
                      datastoreApiInstance: datastoreApiInstance!,
                      snapshot: snapshot,
                      groups: settings.groups,
                      auxes: settings.auxes,
                    );
                  case Page.aux:
                    List<ChannelDefinition> inputChannels =
                        settings.auxInputChannels[widget.channel]!;

                    inputChannels.addAll(settings.groups.toList());
                    inputChannels.addAll(settings.reverbChannels.toList());
                    return SendScreen(
                      sendType: ChannelType.aux,
                      activeSends: settings.auxes,
                      inputChannels: inputChannels,
                      channel: widget.channel,
                      datastoreApiInstance: datastoreApiInstance!,
                      snapshot: snapshot,
                    );
                  case Page.group:
                    return SendScreen(
                      sendType: ChannelType.group,
                      headerIcon: Icons.group,
                      activeSends: settings.groups,
                      inputChannels: settings.groupChannels[widget.channel]!,
                      channel: widget.channel,
                      datastoreApiInstance: datastoreApiInstance!,
                      snapshot: snapshot,
                    );
                  case Page.reverb:
                    return SendScreen(
                      sendType: ChannelType.reverb,
                      headerIcon: Icons.double_arrow,
                      activeSends: settings.reverbChannels,
                      inputChannels: settings.allInputChannels,
                      channel: widget.channel,
                      datastoreApiInstance: datastoreApiInstance!,
                      snapshot: snapshot,
                    );
                  default:
                    return MixerScreen(
                      inputChannels: settings.mixerChannels,
                      datastoreApiInstance: datastoreApiInstance!,
                      groups: settings.groups,
                      auxes: settings.auxes,
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
