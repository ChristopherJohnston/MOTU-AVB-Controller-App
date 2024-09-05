import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainScaffold extends StatelessWidget {
  final List<Widget> actions;
  final Widget? title;
  final Widget body;

  const MainScaffold({
    super.key,
    this.actions = const [],
    this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: actions,
        title: title ??
            TextButton(
              onPressed: () {
                context.go('/mixer/0');
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
            ListTile(
              leading: const Icon(Icons.settings_input_component),
              title: const Text('Mixer'),
              onTap: () {
                Navigator.pop(context);
                context.go('/mixer/0');
              },
            ),
            ListTile(
              leading: const Icon(Icons.headphones),
              title: const Text('Aux'),
              onTap: () {
                Navigator.pop(context);
                context.go('/aux/0');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Group'),
              onTap: () {
                Navigator.pop(context);
                context.go('/group/0');
              },
            ),
            ListTile(
              leading: const Icon(Icons.double_arrow),
              title: const Text('Reverb'),
              onTap: () {
                Navigator.pop(context);
                context.go('/reverb/0');
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
