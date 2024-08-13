import 'package:fluent_ui/fluent_ui.dart';
import 'package:opsplash_flutter/page_home.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  var thememode = ThemeMode.system;

  void changeBrightness(BuildContext context) {
    setState(() {
      if (FluentTheme.of(context).brightness == Brightness.light) {
        thememode = ThemeMode.dark;
      } else {
        thememode = ThemeMode.light;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: "opsplash on web",
      theme: FluentThemeData.light(),
      darkTheme: FluentThemeData.dark(),
      themeMode: thememode,
      home: const PageHome(),
    );
  }
}
