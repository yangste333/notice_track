import 'package:flutter/material.dart';
import 'package:notice_track/database/firestore_service.dart';
import 'package:notice_track/home_page.dart';

class MyApp extends StatelessWidget {
  final FirestoreService firestoreService;
  const MyApp({super.key, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoticeTrack',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
      ),
      home: MyHomePage(title: 'NoticeTrack', firestoreService: firestoreService,),
    );
  }
}
