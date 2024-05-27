import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import 'package:notice_track/widgets/settings_page.dart';
import 'package:notice_track/widgets/map.dart';
import 'package:notice_track/widgets/main_scaffold.dart';
import 'package:notice_track/widgets/proximity_notification_tooltip.dart';
import 'package:notice_track/widgets/create_event_button.dart';
import 'package:notice_track/yaml_readers/yaml_reader.dart';
import 'package:notice_track/database/firestore_service.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  final FirestoreService firestoreService;
  final Box settingsBox;
  final YamlReader settingsReader;

  const MyHomePage(
      {super.key,
        required this.title,
        required this.firestoreService,
        required this.settingsBox,
        required this.settingsReader});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int nearbyEventCount = 0;
  String currentPage = "Homepage";
  bool creatingEvent = false;

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: widget.title,
      currentPage: currentPage,
      onSettingsPressed: () {
        setState(() {
          creatingEvent = false;
          currentPage = "Settings";
        });
      },
      onBackPressed: currentPage == "Settings" ? () {
        setState(() {
          currentPage = "Homepage";
        });
      }
          : null,
      body: currentPage == "Settings" ? SettingsPage(
        returnToPreviousPage: () {
          setState(() {
            currentPage = "Homepage";
          });
        },
        settingsBox: widget.settingsBox,
        settingsReader: widget.settingsReader,
      )
          : Stack(
        children: [
          MapWidget(
            creatingEvent: creatingEvent,
            onEventCreationCancelled: _cancelEventCreation,
            onEventsNearby: _onEventsNearby,
            firestoreService: widget.firestoreService,
            categoryReader: widget.settingsReader,
          ),
          if (creatingEvent) _eventCreationTooltip(),
          if (nearbyEventCount > 0)
            ProximityNotificationTooltip(nearbyEventCount: nearbyEventCount),
        ],
      ),
      floatingActionButton: currentPage == "Homepage" ? EventCreationButton(
        creatingEvent: creatingEvent,
        onToggleEventCreation: _toggleEventCreation,
        onCancelEventCreation: _cancelEventCreation,
      ) : null,
    );
  }

  ////////////////////////////////////////////////////////////////////////////
  //                   _MyHomePageState helper methods                      //
  ////////////////////////////////////////////////////////////////////////////

  void _cancelEventCreation() {
    setState(() {
      creatingEvent = false;
    });
  }

  void _toggleEventCreation() {
    setState(() {
      creatingEvent = !creatingEvent;
    });
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
}
