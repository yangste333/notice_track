import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MarkerData>> pullMarkers() {
    return _firestore.collection('alerts').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => MarkerData.fromFirestore(doc.data())).toList());
  }

  Future<void> pushMarker(LatLng position, String label, String description) {
    return _firestore.collection('alerts').add({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'label': label,
      'description': description,
    });
  }
}

class MarkerData {
  final LatLng position;
  final String label;
  final String description;

  MarkerData({required this.position, required this.label, required this.description});

  factory MarkerData.fromFirestore(Map<String, dynamic> firestoreDoc) {
    return MarkerData(
      position: LatLng(firestoreDoc['latitude'], firestoreDoc['longitude']),
      label: firestoreDoc['label'] ?? 'Unknown',  // Fallback if null
      description: firestoreDoc['description'] ?? 'No description provided.',  // Fallback if null
    );
  }
}
