import 'package:covid19/routes.dart';
import 'package:covid19/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() {
  runApp(new MaterialApp(
    home: Scaffold(
      body: RegisterScreen(),
    ),
    debugShowCheckedModeBanner: false,
    theme: new ThemeData(
      primaryColorDark: Colors.greenAccent,
      primaryColor: Colors.green,
    ),
    routes: covidRoutes,
  ));
  configLoading();
}

void configLoading() {
  EasyLoading.instance
    ..displayDuration = const Duration(milliseconds: 2000)
    ..indicatorType = EasyLoadingIndicatorType.fadingCircle
    ..loadingStyle = EasyLoadingStyle.dark
    ..indicatorSize = 45.0
    ..radius = 10.0
    ..progressColor = Colors.yellow
    ..backgroundColor = Colors.green
    ..indicatorColor = Colors.yellow
    ..textColor = Colors.yellow
    ..maskColor = Colors.blue.withOpacity(0.5)
    ..userInteractions = true;
}
