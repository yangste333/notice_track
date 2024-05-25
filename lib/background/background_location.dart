import 'package:geolocator/geolocator.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:latlong2/latlong.dart';

import 'package:notice_track/background/notification_service.dart';
import 'package:notice_track/database/firestore_service.dart';

import 'geolocation_service.dart';

abstract class BackgroundService{
  Future<void> initialize();
  Future<void> enableBackgroundExecution();
}

class FlutterBackgroundService extends BackgroundService{
  @override
  Future<void> enableBackgroundExecution() async{
    await FlutterBackground.enableBackgroundExecution();
  }

  @override
  Future<void> initialize() async{
    await FlutterBackground.initialize(
      androidConfig: const FlutterBackgroundAndroidConfig(
        notificationTitle: 'Location Tracking',
        notificationText: 'Your location is being tracked in the background',
        notificationImportance: AndroidNotificationImportance.Default,
      ),
    );
  }

}

class BackgroundLocationService {
  final NotificationService notificationService;
  final FirestoreService firestoreService;
  final GeolocationService geolocationService;
  final BackgroundService backgroundService;

  BackgroundLocationService(this.notificationService, this.firestoreService, this.geolocationService, this.backgroundService) {
    _initiateBackgroundProcess();
  }

  Future<void> _initiateBackgroundProcess() async {
    await backgroundService.initialize();
  }

  Future<void> startTracking() async {
    await _initiateBackgroundProcess();
    await backgroundService.enableBackgroundExecution();

    geolocationService.getCurrentLocation().listen((Position position) {
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
