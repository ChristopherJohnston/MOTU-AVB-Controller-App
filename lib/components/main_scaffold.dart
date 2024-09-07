import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:motu_control/api/datastore_api.dart';
import 'package:motu_control/utils/constants.dart';
import 'package:motu_control/utils/screen.dart';
import 'package:motu_control/api/mixer_state.dart';

class MainScaffold extends StatelessWidget {
  final List<Widget> actions;
  final Widget? title;
  final Widget body;
  final MixerState? state;
  final MotuDatastoreApi? datastoreApiInstance;

  const MainScaffold({
    super.key,
    this.actions = const [],
    this.title,
    required this.body,
    this.state,
    this.datastoreApiInstance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: actions,
        title: title ??
            TextButton(
              onPressed: () {
                context.go('/${Screen.mixer.name}/0');
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                child: SvgPicture.asset(
                  'assets/motu-logo.svg',
                  width: 120,
                  color: Colors.white,
                ),
              ),
            ),
        leading: const DrawerButton(),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1F2022),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            (state != null)
                ? ListTile(
                    leading: const Icon(Icons.open_in_new),
                    title: DropdownMenu<int>(
                      hintText: "Select a preset",
                      label: const Text("Load Preset"),
                      dropdownMenuEntries: state!.devicePresets.entries.map(
                        (preset) {
                          return DropdownMenuEntry<int>(
                            value: preset.key,
                            label: preset.value,
                          );
                        },
                      ).toList(),
                      onSelected: (int? value) {
                        Navigator.pop(context);
                        datastoreApiInstance?.loadPreset(value!);
                      },
                    ),
                  )
                : const Placeholder(),
            ListTile(
              leading: const Icon(kMixerIcon),
              title: const Text('Mixer'),
              onTap: () {
                Navigator.pop(context);
                context.go('/${Screen.mixer.name}/0');
              },
            ),
            ListTile(
              leading: const Icon(kAuxIcon),
              title: const Text('Aux'),
              onTap: () {
                Navigator.pop(context);
                context.go('/${Screen.aux.name}/0');
              },
            ),
            ListTile(
              leading: const Icon(kGroupIcon),
              title: const Text('Group'),
              onTap: () {
                Navigator.pop(context);
                context.go('/${Screen.group.name}/0');
              },
            ),
            ListTile(
              leading: const Icon(kReverbIcon),
              title: const Text('Reverb'),
              onTap: () {
                Navigator.pop(context);
                context.go('/${Screen.reverb.name}/0');
              },
            ),
            const Divider(),
            // ListTile(
            //   leading: const Icon(Icons.connect_without_contact),
            //   title: const Text('Connect API'),
            //   onTap: () {
            //     Navigator.pop(context);
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.stop_circle),
            //   title: const Text('Stop Polling'),
            //   onTap: () {
            //     datastoreApiInstance?.stopPolling();
            //     Navigator.pop(context);
            //   },
            // ),
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(40.0, 40.0, 40.0, 10),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: body,
            ),
          ],
        ),
      ),
    );
  }
}

class DrawerButton extends StatelessWidget {
  const DrawerButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        Scaffold.of(context).openDrawer();
      },
    );
  }
}
