import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:opsplash_flutter/main.dart';
import 'package:opsplash_flutter/page_info.dart';
import 'package:opsplash_flutter/page_tool.dart';

class PageHome extends StatefulWidget {
  const PageHome({super.key});

  @override
  State<PageHome> createState() => _PageHomeState();
}

class _PageHomeState extends State<PageHome> {
  int selected = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: const NavigationAppBar(
        title: Text("opsplash on web"),
        leading: Icon(FluentIcons.cake),
        automaticallyImplyLeading: false,
        actions: DarkLightSwitch(),
      ),
      pane: NavigationPane(
          selected: selected,
          header: const Text("Items"),
          items: <NavigationPaneItem>[
            PaneItem(
                icon: const Icon(FluentIcons.home),
                title: const Text("Home"),
                body: const PageHomeBody()),
            PaneItem(
                icon: const Icon(FluentIcons.toolbox),
                title: const Text("Tool"),
                body: const PageToolBody()),
          ],
          footerItems: <NavigationPaneItem>[
            PaneItem(
                icon: const Icon(FluentIcons.info), title: Text("About"), body: const AboutPage())
          ],
          onChanged: (select) {
            setState(() {
              selected = select;
            });
          }),
    );
  }
}

class PageHomeBody extends StatelessWidget {
  const PageHomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Container(
      padding: const EdgeInsets.all(80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                "assets/CircleCashTeamLogo.png",
                width: 40,
              ),
              const SizedBox(
                width: 20,
              ),
              Text(
                "OPSPLASH",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          Text(
            "Written by Circle Cash Team",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    ));
  }
}

class DarkLightSwitch extends StatefulWidget {
  const DarkLightSwitch({super.key});

  @override
  State<DarkLightSwitch> createState() => _DarkLightSwitchState();
}

class _DarkLightSwitchState extends State<DarkLightSwitch> {
  bool isLight = false;

  void _changeBrightness(BuildContext context) {
    var myapp = context.findAncestorStateOfType<MyAppState>();
    if (myapp != null) {
      myapp.changeBrightness(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    isLight = FluentTheme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ToggleButton(
              checked: isLight,
              onChanged: (value) {
                setState(() {
                  _changeBrightness(context);
                  isLight = value;
                });
              },
              child: isLight
                  ? const Icon(FluentIcons.brightness)
                  : const Icon(FluentIcons.lower_brightness)),
        ],
      ),
    );
  }
}
