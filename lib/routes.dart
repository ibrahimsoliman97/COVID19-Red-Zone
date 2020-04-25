import 'package:covid19/screens/map_screen.dart';
import 'package:covid19/screens/my_map_screen.dart';
import 'package:covid19/screens/register_screen.dart';
import 'package:flutter/material.dart';

final Map<String, WidgetBuilder> covidRoutes = <String, WidgetBuilder>{
  RegisterScreen.routeName: (BuildContext context) => RegisterScreen(),
  MapScreen.routeName: (BuildContext context) => MapScreen(),
  MyMapScreen.routeName: (BuildContext context) => MyMapScreen(),
};
