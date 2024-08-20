import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.white,
  textTheme: const TextTheme (
    bodyLarge: TextStyle(
      color: Color.fromARGB(255, 0, 0, 0),
      fontSize: 20,
    ),
  ), 
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.black,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      color: Color.fromARGB(255, 28, 140, 252),
      fontSize: 20.0
    ),
  ),
);
