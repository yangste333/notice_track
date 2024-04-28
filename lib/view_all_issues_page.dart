import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_write.dart';
import 'package:flutter/material.dart';

// for the page that lists all of the current things: you create the page once then update it later
// so a "stateless widget" seems appropriate

class ShowCurrentIssues extends StatelessWidget {
  final FirebaseDriver database;
  const ShowCurrentIssues({super.key, required this.database});

  Widget _readAndMake(){
    print("making");
    return Scaffold(
        body: StreamBuilder(
            stream: database.read(),
            builder: (context, snapshot){
              print(snapshot.connectionState);
              print(snapshot.data);
              if (snapshot.connectionState == ConnectionState.waiting){
                print("waiting");
                return const Center(child: CircularProgressIndicator());
              }else if (snapshot.hasError){
                return const Center(child: Text('Error'));
              }
              else{
                print("done");
                final data = snapshot.data!;
                return ListView.builder(
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final document = data[index];
                      return ListTile(
                        title: Text(document.title),
                        subtitle: Text(document.category.toString()),
                        leading: Text("${document.latitude}, ${document.longitude}"),
                        trailing: Text(document.description),
                      );
                    }
                );
              }
            }
        )
    );

  }

  @override
  Widget build(BuildContext context) {
    return _readAndMake();
  }
}
