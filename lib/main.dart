import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:notice_track/database/firebase_options.dart';
import 'package:notice_track/app.dart';
import 'package:notice_track/user_settings.dart';
import 'package:path_provider/path_provider.dart';

import 'database/firestore_service.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(UserSettingsAdapter());
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  var exampleOptions = FirestoreService();
  runApp(MyApp(firestoreService: exampleOptions,));
}


