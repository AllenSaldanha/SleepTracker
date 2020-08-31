import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
//import 'package:sleeptracker/screens/statistics.dart';
import 'package:sleeptracker/data/datasaved.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:background_fetch/background_fetch.dart';

void backgroundFetchHeadlessTask(String taskId) async {
  print('[BackgroundFetch] Headless event received.');
  BackgroundFetch.finish(taskId);
}

void main(){
  runApp(Mainpage());
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class Mainpage extends StatefulWidget {
  static const String id = 'mainpage';
  @override
  _MainpageState createState() => _MainpageState();

}

class _MainpageState extends State<Mainpage> {

  //background stuff
  bool _enabled = true;
  int _status = 0;
  List<DateTime> _events = [];

  void initState() {
    super.initState();
    initPlatformState();
  }
  Future<void> initPlatformState() async {
    // Configure BackgroundFetch.
    BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: false,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE
    ), (String taskId) async {
      // This is the fetch-event callback.
      print("[BackgroundFetch] Event received $taskId");
      setState(() {
        _events.insert(0, new DateTime.now());
      });
      // IMPORTANT:  You must signal completion of your task or the OS can punish your app
      // for taking too long in the background.
      BackgroundFetch.finish(taskId);
    }).then((int status) {
      print('[BackgroundFetch] configure success: $status');
      setState(() {
        _status = status;
      });
    }).catchError((e) {
      print('[BackgroundFetch] configure ERROR: $e');
      setState(() {
        _status = e;
      });
    });

    // Optionally query the current BackgroundFetch status.
    int status = await BackgroundFetch.status;
    setState(() {
      _status = status;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  void _onClickEnable(enabled) {
    setState(() {
      _enabled = enabled;
    });
    if (enabled) {
      BackgroundFetch.start().then((int status) {
        print('[BackgroundFetch] start success: $status');
      }).catchError((e) {
        print('[BackgroundFetch] start FAILURE: $e');
      });
    } else {
      BackgroundFetch.stop().then((int status) {
        print('[BackgroundFetch] stop success: $status');
      });
    }
  }

  void _onClickStatus() async {
    int status = await BackgroundFetch.status;
    print('[BackgroundFetch] status: $status');
    setState(() {
      _status = status;
    });
  }

  var stopwatch = Stopwatch();
  String sleepButton = 'Start Sleep';
  DateTime currDt = DateTime.now();
  String stopwatchtime = '00:00:00';
  var swatch  = Stopwatch();
  final dur = const Duration(seconds: 1);

  void startTimer(){
    Timer(dur,keepRunning);
  }

  void keepRunning(){
    if(swatch.isRunning){
      startTimer();
    }
    setState(() {
      stopwatchtime = swatch.elapsed.inHours.toString().padLeft(2,'0')+':'
                      + (swatch.elapsed.inMinutes%60).toString().padLeft(2,'0')+':'
                      + (swatch.elapsed.inSeconds%60).toString().padLeft(2,'0');
    });
  }

  saveSleepData(double finalSleepTime) async{
    SharedPreferences prefs  =await SharedPreferences.getInstance();
    setState((){
      prefs.setDouble('${currDt.day}-${currDt.month}-${currDt.year}', finalSleepTime);
    });
  }

  double timecalc(String sleepingtime){
    int hours=int.parse(sleepingtime.substring(0,2));
    int minutes=int.parse(sleepingtime.substring(3,5));
    int seconds=int.parse(sleepingtime.substring(6,8));
    double rettime=hours+(minutes/60)+(seconds/3600);
    return rettime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: FlatButton(
                  child:Icon(
                    Icons.show_chart,
                    size: 70.0,
                  ),
                  shape: CircleBorder(),
                  onPressed: (){
                    Navigator.pushNamed(context, Statistics.id);
                  },
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    color: Color(0xFF23202E),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        '${currDt.day}-${currDt.month}-${currDt.year}',
                        style: TextStyle(
                          fontSize: 50.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    color: Color(0xFF23202E),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        stopwatchtime,
                        style: TextStyle(
                          fontSize: 50.0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FlatButton(
                  child: Text(
                    sleepButton,
                    style: TextStyle(
                      fontSize: 30.0,
                    ),
                  ),
                  shape: CircleBorder(),
                  onPressed: (){
                    if(sleepButton=='Start Sleep') {
                      swatch.start();
                      startTimer();
                      setState(() {
                        sleepButton = 'Stop Sleep';
                      });
                    }
                    else{
                      swatch.stop();
                      lastSleep = stopwatchtime;
                      double timeInt=timecalc(lastSleep);
                      print('This is the time last slept $timeInt');
                      saveSleepData(timeInt);
                      swatch.reset();
                      setState(() {
                        sleepButton = 'Start Sleep';
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}











//----------------------------------------------------------------------------------------------------------------------------------------------------------
//SCREEN 2




class Statistics extends StatefulWidget{
  static const String id = 'statistics';
  @override
  _StatisticsState createState () => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  var currDtSts = DateTime.now();
  double lastSlept=0.0;
  double lastSlept6=0.0;
  double lastSlept5=0.0;
  double lastSlept4=0.0;
  double lastSlept3=0.0;
  double lastSlept2=0.0;
  double lastSlept1=0.0;

  accessSleepData(String sleepDate) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double finalSleep = prefs.getDouble(sleepDate);
    return finalSleep;
  }
  //Jan-31,Feb-28/29,March-31,April-30,May-31,June-30,July-31,Aug-31,Sept-30,Oct-31,Nov-30,Dec-31
  String previousDay(int noOfDaysBack){
    int day=(currDtSts.day-noOfDaysBack).abs();
    int dy=currDtSts.day;
    int mnth=currDtSts.month;
    int yr=currDtSts.year;
    //1-7=-6
    //2-7=-5
    if (currDtSts.month==1){
      yr= currDtSts.year-1;
      mnth = currDtSts.month-1;
      dy = (currDtSts.day-noOfDaysBack).isNegative?31-(day-1):currDtSts.day-noOfDaysBack;
    }
    else if(currDtSts.month==2 ||currDtSts.month==4 ||currDtSts.month==6 ||currDtSts.month== 8 ||currDtSts.month== 9 ||currDtSts.month== 11){
      dy = (currDtSts.day-noOfDaysBack).isNegative?31-(day-1):currDtSts.day-noOfDaysBack;
    }
    else if(currDtSts.month==3){
      if(currDtSts.year%4==0){
        dy = (currDtSts.day-noOfDaysBack).isNegative?29-(day-1):currDtSts.day-noOfDaysBack;
      }
      else{
        dy = (currDtSts.day-noOfDaysBack).isNegative?28-(day-1):currDtSts.day-noOfDaysBack;
      }
    }
    else if(currDtSts.month==5||currDtSts.month==7||currDtSts.month==10||currDtSts.month==12){
      dy = (currDtSts.day-noOfDaysBack).isNegative?30-(day-1):currDtSts.day-noOfDaysBack;
    }
    //print('$dy-$mnth-$yr');
    return ('$dy-$mnth-$yr');
  }

  lastSleep(String sleepDate)async{
    double lastsleeptime=await accessSleepData('$sleepDate');
    lastsleeptime=double.parse((lastsleeptime).toStringAsFixed(2));//Rounding of to 2 decimal places
    lastSlept=lastsleeptime;
    return lastsleeptime;
  }

  lastSleepWeek()async{
    double lastsleeptime6=await accessSleepData('${previousDay(6)}')??0;
    lastsleeptime6=double.parse((lastsleeptime6).toStringAsFixed(2));//Rounding of to 2 decimal places
    lastSlept6=lastsleeptime6;
    double lastsleeptime5=await accessSleepData('${previousDay(5)}')??0;
    lastsleeptime5=double.parse((lastsleeptime5).toStringAsFixed(2));//Rounding of to 2 decimal places
    lastSlept5=lastsleeptime5;
    double lastsleeptime4=await accessSleepData('${previousDay(4)}')??0;
    lastsleeptime4=double.parse((lastsleeptime4).toStringAsFixed(2));//Rounding of to 2 decimal places
    lastSlept4=lastsleeptime4;
    double lastsleeptime3=await accessSleepData('${previousDay(3)}')??0;
    lastsleeptime3=double.parse((lastsleeptime3).toStringAsFixed(2));//Rounding of to 2 decimal places
    lastSlept3=lastsleeptime3;
    double lastsleeptime2=await accessSleepData('${previousDay(2)}')??0;
    lastsleeptime2=double.parse((lastsleeptime2).toStringAsFixed(2));//Rounding of to 2 decimal places
    lastSlept2=lastsleeptime2;
    double lastsleeptime1=await accessSleepData('${previousDay(1)}')??0;
    lastsleeptime1=double.parse((lastsleeptime1).toStringAsFixed(2));//Rounding of to 2 decimal places
    lastSlept1=lastsleeptime1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 10.0,
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  FlatButton(
                    child: Icon(
                      Icons.arrow_back,
                      size: 30.0,
                      color: Colors.black,
                    ),
                    onPressed: (){
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'Last Sleep: $lastSlept hr',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20.0,
                    ),
                  ),
                  FlatButton(
                    child: Icon(
                      Icons.refresh,
                      size: 30.0,
                      color: Colors.black,
                    ),
                    onPressed: (){
                      setState(() {
                        lastSleep('${currDtSts.day}-${currDtSts.month}-${currDtSts.year}');
                        lastSleepWeek();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.all(15.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                color: Colors.white,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 30.0,
                      ),
                      Text(
                        'This week',
                        style: TextStyle(
                          fontSize: 20.0,
                          color: Colors.black,
                        ),
                      )
                    ],
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.lightBlueAccent,
                      ),
                      child: SfCartesianChart(
                        primaryXAxis: CategoryAxis(),
                        series: <ChartSeries>[
                          LineSeries<SleepingData,String>(
                            dataSource:[//todo fix the error in the chart and create the chart for month
                              //try refreshing these values along with the last sleep
                              SleepingData(previousDay(6),lastSlept6),
                              SleepingData(previousDay(5),lastSlept5),
                              SleepingData(previousDay(4),lastSlept4),
                              SleepingData(previousDay(3),lastSlept3),
                              SleepingData(previousDay(2),lastSlept2),
                              SleepingData(previousDay(1),lastSlept1),
                              SleepingData('${currDtSts.day}-${currDtSts.month}-${currDtSts.year}',lastSlept),
                            ],
                            xValueMapper: (SleepingData slept, _) => slept.date,
                            yValueMapper: (SleepingData slept, _) => slept.time,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(),
//            child: Container(
//              margin: EdgeInsets.all(15.0),
//              decoration: BoxDecoration(
//                borderRadius: BorderRadius.circular(10.0),
//                color: Colors.white,
//              ),
//              child: Column(
//                children: <Widget>[
//                  Row(
//                    children: <Widget>[
//                      Icon(
//                        Icons.arrow_drop_down,
//                        size: 40.0,
//                        color: Colors.black,
//                      ),
//                      Text(
//                        'This month',
//                        style: TextStyle(
//                          fontSize: 20.0,
//                          color: Colors.black,
//                        ),
//                      )
//                    ],
//                  ),
//                  Expanded(
//                    child: Container(
//                      margin: EdgeInsets.all(10.0),
//                      decoration: BoxDecoration(
//                        borderRadius: BorderRadius.circular(10.0),
//                        color: Colors.lightBlueAccent,
//                      ),
//                      child: SfCartesianChart(),
//                    ),
//                  ),
//                ],
//              ),
//            ),
          ),
        ],
      ),
    );
  }
}

class SleepingData{
  SleepingData(this.date,this.time);
  final String date;
  final double time;
}
