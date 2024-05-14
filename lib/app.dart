import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:notice_track/home_page.dart';
import 'package:notice_track/yaml_readers/yaml_reader.dart';
import 'package:notice_track/database/firestore_service.dart';

class MyApp extends StatelessWidget {
  final FirestoreService firestoreService;
  final Box settingsBox;
  final YamlReader settingsReader;
  const MyApp({super.key, required this.firestoreService, required this.settingsBox, required this.settingsReader});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoticeTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: MyHomePage(title: 'NoticeTrack', firestoreService: firestoreService, settingsBox: settingsBox, settingsReader: settingsReader,),
    );
  }
}
