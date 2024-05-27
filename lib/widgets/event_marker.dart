import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EventMarker {
  static Marker createEventMarker(LatLng position, String label, VoidCallback onTap) {
    return Marker(
      point: position,
      width: 74,
      height: 74,
      alignment: Alignment.topCenter,
      rotate: true,
      child: _eventMarkerIcon(label, onTap),
    );
  }

  static Widget _eventMarkerIcon(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            color: Colors.white,
            child: FittedBox(
              child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 12)),
            ),
          ),
          const Icon(
            Icons.location_on_sharp,
            size: 50,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
