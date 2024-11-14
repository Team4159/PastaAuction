import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bids.dart' as bids;
import 'components/gridpage.dart';
import 'components/mybidspage.dart';
import 'items.dart' as items;

late final SharedPreferences prefs;
late final GlobalKey<ScaffoldMessengerState> _scaffoldMessenger = GlobalKey();

void main() async {
  // Start the DB connector
  await Supabase.initialize(
      debug: false,
      url: 'https://eyjwzmofydqautoxeghu.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV5and6bW9meWRxYXV0b3hlZ2h1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzEzMTg3NzYsImV4cCI6MjA0Njg5NDc3Nn0.NoU0BAmppSjVBHvqzYHik1z3biEtUW5VA3_eHKIequA');
  // Initialize the local dbs
  await Future.wait([
    SharedPreferences.getInstance().then((sp) => prefs = sp),
    items.loadItemList(),
    bids.reloadTopBids()
  ]);
  bids.fillStartBids();
  // Start the App
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
      title: 'Pasta Auction',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
          inputDecorationTheme: const InputDecorationTheme(border: UnderlineInputBorder())),
      darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.red, brightness: Brightness.dark),
          inputDecorationTheme: const InputDecorationTheme(border: UnderlineInputBorder())),
      scaffoldMessengerKey: _scaffoldMessenger,
      routes: {"/": (ctx) => GridPage(), "/bids": (ctx) => const MyBidsPage()}));
  // Initialize the live feed
  bids.subscribe((retry, [err]) => _scaffoldMessenger.currentState!.showSnackBar(SnackBar(
      content: Text(err is RealtimeSubscribeException
          ? prettyStatus[err.status]!
          : err?.toString() ?? "Unknown Error"),
      duration: Duration(days: 1),
      showCloseIcon: true,
      action: SnackBarAction(label: "retry", onPressed: retry))));
}

final prettyStatus = {
  RealtimeSubscribeStatus.channelError: "Temporary Connection Error",
  RealtimeSubscribeStatus.closed: "Disconnected: Server",
  RealtimeSubscribeStatus.timedOut: "Disconnected: Timed Out",
  RealtimeSubscribeStatus.subscribed: "Nominal (Ignore)"
};
