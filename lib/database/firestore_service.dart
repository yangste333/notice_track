import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<MarkerData>> pullMarkers() {
    return _firestore.collection('alerts').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => MarkerData.fromFirestore(doc.data())).toList());
  }

  Future<void> pushMarker(LatLng position, String label, String description, String category, DateTime timestamp) {
    return _firestore.collection('alerts').add({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'label': label,
      'description': description,
      'category': category,
      'datetime': timestamp,
    });
  }
}

class MarkerData {
  final LatLng position;
  final String label;
  final String description;
  final String category;
  final DateTime datetime;

  MarkerData({required this.position, required this.label, required this.description, required this.category, required this.datetime});

  factory MarkerData.fromFirestore(Map<String, dynamic> firestoreDoc) {
    return MarkerData(
      position: LatLng(firestoreDoc['latitude'], firestoreDoc['longitude']),
      label: firestoreDoc['label'] ?? 'Unknown',  // Fallback if null
      description: firestoreDoc['description'] ?? 'No description provided.',  // Fallback if null
      category: firestoreDoc['category'] ?? 'Other',
      datetime: firestoreDoc['datetime']?.toDate() ?? DateTime.now(),
    );
  }
}
