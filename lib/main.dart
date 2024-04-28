import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:location_tracker/view_all_issues_page.dart';
import 'firebase_options.dart';
import 'firebase_write.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseDriver driver = FirebaseDriver();
  LocationAlert test = const LocationAlert(latitude: 0.001, longitude: 0.002, title: "Test", category: Category.Other, description: "Test");
  driver.write(test);
  print(driver.read());
  runApp(MyApp(database: driver));
}

class MyApp extends StatelessWidget {
  final FirebaseDriver database;
  const MyApp({super.key, required this.database});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: ShowCurrentIssues(database: database),
    );
  }
}


