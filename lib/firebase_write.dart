import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

enum Category{
  Dangers,
  Wildlife,
  Events,
  Other
}

class LocationAlert{
  final double latitude;
  final double longitude;
  final String title;
  final Category category;
  final String description;

  const LocationAlert({required this.latitude, required this.longitude,
    required this.title, required this.category, required this.description});

  factory LocationAlert.fromDocumentSnapshot(DocumentSnapshot doc){
    final data = doc.data() as Map<String, dynamic>;
    return LocationAlert(
      latitude: data['latitude'],
      longitude: data['longitude'],
      title: data['title'],
      category: Category.values.firstWhere((e) =>
        e.toString().split('.').last == data['category'], orElse: () => Category.Dangers),
      description: data['description'],
    );
  }
}

class FirebaseDriver{

  FirebaseDriver(){
    initialize();
  }

  initialize() async{
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  Map<String, dynamic> _convertToMap(LocationAlert l){
    return {
      'latitude': l.latitude,
      'longitude': l.longitude,
      'title': l.title,
      'category': l.category.name,
      'description': l.description
    };
  }

  Future<bool> write(LocationAlert l) async{
    try {
      var database = FirebaseFirestore.instance.collection('alerts').doc();
      final nameMap = _convertToMap(l);
      await database.set(nameMap);
      return true;
    }
    catch(error){
      print("Issue updating database");
      return false;
    }
  }

  Stream<List<LocationAlert>>? read(){
    return FirebaseFirestore.instance.collection('alerts').snapshots().map((snapshot) =>
    snapshot.docs.map((doc) => LocationAlert.fromDocumentSnapshot(doc)).toList());
  }

}