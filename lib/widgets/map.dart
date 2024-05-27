import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

import 'package:notice_track/widgets/event.dart';
import 'package:notice_track/database/firestore_service.dart';

import '../yaml_readers/yaml_reader.dart';

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
  Marker? userLocationMarker;
  Timer? _timer;  // Declare a Timer

  @override
  void initState() {
    super.initState();
    _getMarkersFromFirebase();
    _getUserLocation();
    _startPeriodicFirebaseUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel();  // Cancel the timer when the widget gets disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Marker> allMarkers = List<Marker>.from(events);
    if (userLocationMarker != null) {
      allMarkers.add(userLocationMarker!);
    }

    return FlutterMap(
      options: MapOptions(
        interactionOptions: const InteractionOptions(flags: ~InteractiveFlag.doubleTapZoom),
        initialCenter: const LatLng(40.7128, -74.0060),
        initialZoom: 10,
        onTap: _handleTap,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dev.fleaflet.flutter_map.example',
        ),
        MarkerLayer(markers: allMarkers),
      ],
    );
  }

  ////////////////////////////////////////////////////////////////////////////
  //                    _MapWidgetState helper methods                      //
  ////////////////////////////////////////////////////////////////////////////

  void _getMarkersFromFirebase() {
    widget.firestoreService.pullMarkers().listen((markerDataList) {
      setState(() {
        events = markerDataList.map((markerData) =>
            EventMarker.createEventMarker(
                markerData.position,
                markerData.label,
                    () => _showEventInfo(markerData.label, markerData.description, markerData.category)
            )
        ).toList();
      });
    });
  }

  void _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, try again next time.
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever.
      return;
    }

    // Continuously update location.
    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        userLocationMarker = Marker(
          point: LatLng(position.latitude, position.longitude),
          width: 74,
          height: 74,
          alignment: Alignment.topCenter,
          rotate: true,
          child: const Icon(
            Icons.location_on_sharp,
            size: 50,
            color: Colors.blue,
          ),
        );
      });
      _checkEventProximity(position);
    });
  }

  void _startPeriodicFirebaseUpdates() {
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _getMarkersFromFirebase();  // Get updated data from Firebase every 30 seconds.
    });
  }

  void _checkEventProximity(Position position) {
    const double distanceThreshold = 5000; // 5 Kilometer event threshold.
    LatLng userLatLng = LatLng(position.latitude, position.longitude);
    int nearbyEvents = 0;

    for (Marker marker in events) {
      double distance = Geolocator.distanceBetween(
          userLatLng.latitude,
          userLatLng.longitude,
          marker.point.latitude,
          marker.point.longitude
      );

      if (distance <= distanceThreshold) {
        nearbyEvents++;
      }

      // Fire callback with event data
      widget.onEventsNearby?.call(nearbyEvents);
    }
  }

  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    if (widget.creatingEvent) {
      TextEditingController labelController = TextEditingController();
      TextEditingController descriptionController = TextEditingController();
      TextEditingController categoryController = TextEditingController();
      String categoryItem = "";
      categoryController.addListener(() {
        setState((){
          categoryItem = categoryController.text;
        });
      });

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Text('Register Event'),
          content: _creationDialogContent(labelController, descriptionController, categoryController, (String s){
            categoryItem = s;
          }),
          actions: _creationDialogActions(context, latlng, labelController, descriptionController, categoryController, categoryItem),
        ),
      ).then((_) => widget.onEventCreationCancelled());
    }
  }

  Widget _creationDialogContent(TextEditingController labelController, TextEditingController descriptionController,
      TextEditingController categoryController, Function(String) updateCategory) {
    return SingleChildScrollView(
      child: ListBody(
        children: [
          TextField(
            controller: labelController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter event type here'),
            textInputAction: TextInputAction.next,
          ),
          // add a dropdown for a category
          DropdownMenu<String>(dropdownMenuEntries: widget.categoryReader.getCategories()[0].map<DropdownMenuEntry<String>>((dynamic e){
              return DropdownMenuEntry<String>(label: e as String, value: e);
            }).toList(),
            controller: categoryController,
            requestFocusOnTap: true,
            label: const Text("Category"),
          ),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(hintText: 'Enter description here'),
            textInputAction: TextInputAction.done,
          ),
        ],
      ),
    );
  }

  List<Widget> _creationDialogActions(BuildContext context, LatLng latlng, TextEditingController labelController, TextEditingController descriptionController,
      TextEditingController categoryController, String finalCategory) {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          if (labelController.text.isNotEmpty) {
            Marker newMarker = EventMarker.createEventMarker(
              latlng,
              labelController.text,
                  () => _showEventInfo(labelController.text, descriptionController.text, finalCategory),
            );
            setState(() => events.add(newMarker));
            widget.firestoreService.pushMarker(latlng,
                labelController.text, descriptionController.text, categoryController.text,
                DateTime.now());
            Navigator.of(context).pop();
          }
        },
        child: const Text('Submit'),
      ),
    ];
  }

  void _showEventInfo(String label, String description, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
        Text(label),
        content: Column(
          children: [
            Text(category),
            Text(description),
          ]
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
}
