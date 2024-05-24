import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/adapters.dart';

import 'package:notice_track/app.dart';
import 'package:notice_track/background/geolocation_service.dart';
import 'package:notice_track/user_settings.dart';
import 'package:notice_track/yaml_readers/yaml_reader.dart';
import 'package:notice_track/database/firebase_options.dart';
import 'package:notice_track/database/firestore_service.dart';
import 'package:notice_track/background/background_location.dart';

import 'background/notification_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle firebase background message
  // print("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final YamlReader reader = YamlReader(filename: 'lib/assets/notification_categories.yaml');
  await reader.initializeReader();

  await Hive.initFlutter();
  Hive.registerAdapter(UserSettingsAdapter());

  var exampleOptions = FirestoreService();
  var settingsBox = await Hive.openBox('settings');

  // Initialize the background location service to keep user updated
  NotificationService notificationService = NotificationService();
  GeolocationService geolocationService = GeolocationService();
  BackgroundLocationService backgroundLocationService = BackgroundLocationService(notificationService, exampleOptions, geolocationService);
  backgroundLocationService.startTracking();

  runApp(MyApp(firestoreService: exampleOptions, settingsBox: settingsBox, settingsReader: reader,));
}
