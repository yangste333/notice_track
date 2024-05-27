import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  late FirebaseMessaging messaging;
  late FlutterLocalNotificationsPlugin localNotifications;

  NotificationService() {
    messaging = FirebaseMessaging.instance;
    localNotifications = FlutterLocalNotificationsPlugin();
    init();
  }

  void init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('notice_track_icon');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await localNotifications.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
    );

    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? androidNotification = message.notification?.android;
      if (notification != null && androidNotification != null) {
        localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              icon: 'notice_track_icon',
            ),
          ),
        );
      }
    });
  }

  Future<void> sendNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
        'Channel id',
        'Channel name',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        icon: 'notice_track_icon'
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await localNotifications.show(
        0,
        title,
        body,
        platformChannelSpecifics,
        payload: 'item x'
    );
  }
}
