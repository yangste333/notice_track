import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _bucketUrl = "location-tracker-475db.appspot.com/photos/";

  Stream<List<MarkerData>> pullMarkers() {
    return _firestore.collection('alerts').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => MarkerData.fromFirestore(doc.data())).toList());
  }

  Future<void> pushMarker(LatLng position, String label, String description, String category, List<XFile> images, DateTime timestamp) async {
    try {
      // Upload images to Firebase Storage and collect the resulting URLs in a list.
      List<String> photoUrls = await Future.wait(images.map((image) async {
        final String localFilePath = image.path;
        // print('@@@@@@ Photo path: $localFilePath');
        File localFile = File(localFilePath);

        if (await localFile.exists()) {
          // print('@@@@@@ Local file exists and is accessible');
          final String destinationStoragePath = '$_bucketUrl${DateTime.now().millisecondsSinceEpoch}.jpg';
          final storageRef = _storage.ref().child(destinationStoragePath);
          print('@@@@@@ Uploading image to: $destinationStoragePath');

          try {
            // Uploading file to Firebase Storage.
            TaskSnapshot uploadTaskSnapshot = await storageRef.putFile(localFile);
            String downloadURL = await uploadTaskSnapshot.ref.getDownloadURL();
            // print('@@@@@@ Uploaded image URL: $downloadURL');
            return downloadURL;
          } catch (e) {
            // print('@@@@@@ Firebase Storage upload failed: $e');
            rethrow;
          }
        } else {
          // print('@@@@@@ ERROR: Local file does not exist: $localFilePath');
          throw Exception('@@@@@@ Local file does not exist: $localFilePath');
        }
      }));

      // Add marker data to Firestore.
      await _firestore.collection('alerts').add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'label': label,
        'description': description,
        'category': category,
        'photoUrls': photoUrls,
        'datetime': timestamp,
      });
    } catch (e) {
      // print('@@@@@@ ERROR UPLOADING MARKER: $e');
      rethrow;
    }
  }
}

class MarkerData {
  final LatLng position;
  final String label;
  final String description;
  final String category;
  final List<String> photoUrls;
  final DateTime datetime;

  MarkerData({
    required this.position,
    required this.label,
    required this.description,
    required this.category,
    required this.photoUrls,
    required this.datetime,
  });

  factory MarkerData.fromFirestore(Map<String, dynamic> firestoreDoc) {
    return MarkerData(
      position: LatLng(firestoreDoc['latitude'], firestoreDoc['longitude']),
      label: firestoreDoc['label'] ?? 'Unknown',
      description: firestoreDoc['description'] ?? 'No description provided.',
      category: firestoreDoc['category'] ?? 'Other',
      photoUrls: firestoreDoc['photoUrls'] != null ? List<String>.from(firestoreDoc['photoUrls']) : [],
      datetime: firestoreDoc['datetime']?.toDate() ?? DateTime.now(),
    );
  }
}
