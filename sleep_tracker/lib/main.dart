import 'package:flutter/material.dart';
import 'screens/mainpage.dart';
import 'screens/statistics.dart';

void main()=>runApp(SleepTrack());


class SleepTrack extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(//Copywith modifies the already existing theme with our changes
        primaryColor: Color(0xFF0A0E21),//remove # and put 0xFF instead
        scaffoldBackgroundColor: Color(0xFF0A0E21),
      ),
      initialRoute: Mainpage.id,
      routes:{
        Mainpage.id: (context) => Mainpage(),
        Statistics.id: (context) => Statistics(),
    },
    );
  }
}