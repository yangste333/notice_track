import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:notice_track/widgets/event_marker.dart';
import 'package:notice_track/database/firestore_service.dart';
import 'package:notice_track/yaml_readers/yaml_reader.dart';
import 'package:notice_track/widgets/event_creation_dialog.dart';
import 'package:notice_track/widgets/user_location_marker.dart';


class MapWidget extends StatefulWidget {
  final bool creatingEvent;
  final VoidCallback onEventCreationCancelled;
  final Function(int)? onEventsNearby;
  final FirestoreService firestoreService;
  final YamlReader categoryReader;

  const MapWidget({
    super.key,
    required this.creatingEvent,
    required this.onEventCreationCancelled,
    this.onEventsNearby,
    required this.firestoreService,
    required this.categoryReader
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  List<Marker> events = [];
  Timer? _timer;  // Declare a Timer

  @override
  void initState() {
    super.initState();
    _getMarkersFromFirebase();
    _startPeriodicFirebaseUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel();  // Cancel the timer when the widget gets disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        interactionOptions: const InteractionOptions(flags: ~InteractiveFlag.doubleTapZoom),
        initialCenter: const LatLng(47.6555, -122.3032),
        initialZoom: 10,
        onTap: _handleTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        ),
        MarkerLayer(markers: events),
        UserLocationMarker(
          onLocationUpdated: (LatLng position) {
            _checkEventProximity(position);
          },
        ),
      ],
    );
  }

  ////////////////////////////////////////////////////////////////////////////
  //                    _MapWidgetState helper methods                      //
  ////////////////////////////////////////////////////////////////////////////

  void _getMarkersFromFirebase() {
    widget.firestoreService.pullMarkers().listen((markerDataList) {
      setState(() {
        events = markerDataList.map((markerData) {
          return EventMarker.createEventMarker(
            markerData.position,
            markerData.label,
                () => _showEventInfo(markerData),
          );
        }).toList();
      });
    });
  }

  void _startPeriodicFirebaseUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _getMarkersFromFirebase();
    });
  }

  void _checkEventProximity(LatLng position) {
    const double distanceThreshold = 5000; // 5 Kilometer event threshold.
    int nearbyEvents = 0;

    for (Marker marker in events) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        marker.point.latitude,
        marker.point.longitude,
      );

      if (distance <= distanceThreshold) {
        nearbyEvents++;
      }

      widget.onEventsNearby?.call(nearbyEvents);
    }
  }

  void _handleTap(TapPosition _, LatLng latlng) {
    if (widget.creatingEvent) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) =>
            EventCreationDialog(
              latlng: latlng,
              onCancel: widget.onEventCreationCancelled,
              onSubmit: (String label, String description, String category, List<XFile> images) {
                Marker newMarker = EventMarker.createEventMarker(
                  latlng,
                  label,
                      () => _showEventInfo(MarkerData(
                    position: latlng,
                    label: label,
                    description: description,
                    category: category,
                    photoUrls: [], // Wait for firebase to process the photo
                    datetime: DateTime.now(),
                  )),
                );
                setState(() => events.add(newMarker));
                widget.firestoreService.pushMarker(
                    latlng,
                    label,
                    description,
                    category,
                    images,
                    DateTime.now());
              },
              categoryReader: widget.categoryReader,
            ),
      ).then((_) => widget.onEventCreationCancelled());
    }
  }

  void _showEventInfo(MarkerData markerData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(markerData.label),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(markerData.category),
              Text(markerData.description),
              const SizedBox(height: 10),
              if (markerData.photoUrls.isNotEmpty)
                SizedBox(
                  height: 200,
                  width: double.maxFinite,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: markerData.photoUrls.map((url) => _buildImage(url)).toList(),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    return FutureBuilder<String>(
      future: _getImageDownloadURL(url),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return const Icon(Icons.error);
        } else if (snapshot.hasData) {
          return Image.network(
              snapshot.data!, fit: BoxFit.cover, width: 150, height: 150);
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Future<String> _getImageDownloadURL(String url) async {
    // Directly returning the URL, since the marker already contains it
    return url;
  }
}
