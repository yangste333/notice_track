import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class UserLocationMarker extends StatefulWidget {
  final Function(LatLng) onLocationUpdated;
  const UserLocationMarker({super.key, required this.onLocationUpdated});

  @override
  State<UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<UserLocationMarker> {
  Marker? userLocationMarker;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
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
      widget.onLocationUpdated(LatLng(position.latitude, position.longitude));
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userLocationMarker == null) return Container();
    return MarkerLayer(markers: [userLocationMarker!]);
  }
}
