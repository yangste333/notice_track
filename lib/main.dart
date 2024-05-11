import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:notice_track/database/firebase_options.dart';
import 'package:notice_track/app.dart';
import 'package:notice_track/user_settings.dart';
import 'package:notice_track/yaml_readers/yaml_reader.dart';

import 'database/firestore_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  final YamlReader reader = YamlReader(filename: 'lib/assets/notification_categories.yaml');
  await reader.initializeReader();

  await Hive.initFlutter();
  Hive.registerAdapter(UserSettingsAdapter());
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  var exampleOptions = FirestoreService();
  var settingsBox = await Hive.openBox("settings");

  runApp(MyApp(firestoreService: exampleOptions, settingsBox: settingsBox, settingsReader: reader,));
}


