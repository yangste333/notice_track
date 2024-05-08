import 'package:flutter/material.dart';
import 'package:notice_track/settings_page.dart';
import 'package:notice_track/widgets/map.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String currentPage = "Settings";

  Widget _showSettingsPage(){
    return Scaffold(
      appBar: _getAppBar(widget.title),
      resizeToAvoidBottomInset: false,
      body: SettingsPage(
        returnToPreviousPage: (){
          setState((){
            currentPage = "Homepage";
          });
        }
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
          ),
          if (creatingEvent) _eventCreationTooltip(),
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
      actions: [],
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
}
