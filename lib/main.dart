import 'package:flutter/material.dart';
import 'package:pastaauction/components/mybidspage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'components/gridpage.dart';
import 'bids.dart' as bids;
import 'items.dart' as items;

late final SharedPreferences prefs;

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
  ]).then((_) => bids.fillStartBids());
  bids.subscribe((context) => Scaffold);
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
      routes: {"/": (ctx) => GridPage(), "/bids": (ctx) => const MyBidsPage()}));
}
