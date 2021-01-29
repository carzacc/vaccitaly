import 'package:flutter/material.dart';

import 'screens.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vaccitaly',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData.from(
          colorScheme: ColorScheme.dark(background: Colors.black)),
      themeMode: ThemeMode.system,
      home: HomePage(),
    );
  }
}
