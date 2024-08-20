import 'package:flutter/material.dart';
import 'package:homesensors/homepage.dart';
import 'package:homesensors/utils/motion_detector_func.dart';
import 'package:provider/provider.dart';
import 'package:homesensors/theme/theme_data.dart';
import 'package:adaptive_theme/adaptive_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => MotionDetector(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;

  const MyApp({Key? key, this.savedThemeMode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: lightTheme,
      dark: darkTheme,
      initial: savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        title: 'Home Sensors',
        theme: theme,
        darkTheme: darkTheme,
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
