import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:notice_track/widgets/event.dart';
import 'package:notice_track/database/firestore_service.dart';

class MapWidget extends StatefulWidget {
  final bool creatingEvent;
  final VoidCallback onEventCreationCancelled;
  final FirestoreService firestoreService;

  const MapWidget({super.key, required this.creatingEvent, required this.onEventCreationCancelled, required this.firestoreService});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  List<Marker> events = [];


  @override
  void initState() {
    super.initState();
    _getMarkersFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
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
        MarkerLayer(markers: events)
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
                    () => _showEventInfo(markerData.label, markerData.description)
            )
        ).toList();
      });
    });
  }

  void _handleTap(TapPosition tapPosition, LatLng latlng) {
    if (widget.creatingEvent) {
      TextEditingController labelController = TextEditingController();
      TextEditingController descriptionController = TextEditingController();

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog(
          title: const Text('Register Event'),
          content: _creationDialogContent(labelController, descriptionController),
          actions: _creationDialogActions(context, latlng, labelController, descriptionController),
        ),
      ).then((_) => widget.onEventCreationCancelled());
    }
  }

  Widget _creationDialogContent(TextEditingController labelController, TextEditingController descriptionController) {
    return SingleChildScrollView(
      child: ListBody(
        children: [
          TextField(
            controller: labelController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter event type here'),
            textInputAction: TextInputAction.next,
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

  List<Widget> _creationDialogActions(BuildContext context, LatLng latlng, TextEditingController labelController, TextEditingController descriptionController) {
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
                  () => _showEventInfo(labelController.text, descriptionController.text),
            );
            setState(() => events.add(newMarker));
            widget.firestoreService.pushMarker(latlng, labelController.text, descriptionController.text);
            Navigator.of(context).pop();
          }
        },
        child: const Text('Submit'),
      ),
    ];
  }

  void _showEventInfo(String label, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: Text(description),
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
