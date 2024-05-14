import 'package:geolocator/geolocator.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:latlong2/latlong.dart';

import 'package:notice_track/background/notification_service.dart';
import 'package:notice_track/database/firestore_service.dart';

class BackgroundLocationService {
  late NotificationService notificationService;
  final FirestoreService firestoreService;

  BackgroundLocationService(this.firestoreService) {
    notificationService = NotificationService();
    _initiateBackgroundProcess();
  }

  Future<void> _initiateBackgroundProcess() async {
    await FlutterBackground.initialize(
      androidConfig: const FlutterBackgroundAndroidConfig(
        notificationTitle: 'Location Tracking',
        notificationText: 'Your location is being tracked in the background',
        notificationImportance: AndroidNotificationImportance.Default,
      ),
    );
  }

  Future<void> startTracking() async {
    await _initiateBackgroundProcess();
    await FlutterBackground.enableBackgroundExecution();

    Geolocator.getPositionStream().listen((Position position) {
      // Handle the location updates and check for events proximately
      _checkEventProximity(position);
    });
  }

  void _checkEventProximity(Position userPosition) {
    // Pull event positions from firebase.
    List<LatLng> eventPositions = [];
    firestoreService.pullMarkers().listen((markerDataList) {
      eventPositions = markerDataList.map((markerData) =>
          markerData.position
      ).toList();
    });

    const double distanceThreshold = 5000; // 5 Kilometer event threshold.
    int nearbyEvents = 0;
    for (LatLng eventPosition in eventPositions) {
      double distance = Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          eventPosition.latitude,
          eventPosition.longitude
      );

      if (distance <= distanceThreshold) {
        nearbyEvents++;
      }
    }

    notificationService.sendNotification('$nearbyEvents events Nearby', 'You are near $nearbyEvents events');
  }
}
