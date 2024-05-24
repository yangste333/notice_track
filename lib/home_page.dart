import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:notice_track/settings_page.dart';
import 'package:notice_track/widgets/map.dart';
import 'package:notice_track/yaml_readers/yaml_reader.dart';
import 'package:notice_track/database/firestore_service.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  final FirestoreService firestoreService;
  final Box settingsBox;
  final YamlReader settingsReader;
  
  const MyHomePage({super.key, required this.title, required this.firestoreService,
    required this.settingsBox, required this.settingsReader});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int nearbyEventCount = 0;
  String currentPage = "Homepage";

  Widget _showSettingsPage(){
    return Scaffold(
      appBar: _getAppBar(widget.title),
      resizeToAvoidBottomInset: false,
      body: SettingsPage(
        returnToPreviousPage: (){
          setState((){
            currentPage = "Homepage";
          });
        },
        settingsBox: widget.settingsBox,
        settingsReader: widget.settingsReader,
      )
    );
  }
  bool creatingEvent = false;

  @override
  Widget build(BuildContext context) {
    if (currentPage == "Settings") {
      return _showSettingsPage();
    }
    return Scaffold(
      appBar: _getAppBar(widget.title),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          MapWidget(
            creatingEvent: creatingEvent,
            onEventCreationCancelled: cancelEventCreation,
            onEventsNearby: _onEventsNearby,
            firestoreService: widget.firestoreService,
            categoryReader: widget.settingsReader,
          ),
          if (creatingEvent) _eventCreationTooltip(),
          if (nearbyEventCount > 0) _nearbyEventTooltip(),
        ],
      ),
      floatingActionButton: _createEventButton(),
    );
  }

  ////////////////////////////////////////////////////////////////////////////
  //                   _MyHomePageState helper methods                      //
  ////////////////////////////////////////////////////////////////////////////

  AppBar _getAppBar(String title) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(title),
      actions: currentPage == "Settings" ? [] :
        [IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            setState((){
              creatingEvent = false;
              currentPage = "Settings";
            });
          }
        )
      ],
    );
  }
  
  void cancelEventCreation() {
    setState(() {
      creatingEvent = false;
    });
  }

  void toggleEventCreation() {
    setState(() {
      creatingEvent = !creatingEvent;
    });
  }
  
  Widget _createEventButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!creatingEvent)
          FloatingActionButton(
            onPressed: toggleEventCreation,
            tooltip: 'Register Event',
            child: const Icon(Icons.add_location),
          ),
        if (creatingEvent)
          FloatingActionButton(
            onPressed: cancelEventCreation,
            tooltip: 'Cancel',
            backgroundColor: Colors.red,
            child: const Icon(Icons.cancel),
          ),
      ],
    );
  }

  Widget _eventCreationTooltip() {
    return Positioned(
      bottom: 85,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.black.withOpacity(0.5),
        child: const Text(
          'Tap a location to register an event.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }

  void _onEventsNearby(int events) {
    setState(() {
      nearbyEventCount = events;
    });
  }

  Widget _nearbyEventTooltip() {
    return Positioned(
      bottom: 140,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.red[900]!.withOpacity(0.5),
        child: SingleChildScrollView(
          child: Text(
            "There are $nearbyEventCount events within 5km",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
