import 'package:flutter/material.dart';

class EventCreationButton extends StatelessWidget {
  final bool creatingEvent;
  final VoidCallback onToggleEventCreation;
  final VoidCallback onCancelEventCreation;

  const EventCreationButton({
    super.key,
    required this.creatingEvent,
    required this.onToggleEventCreation,
    required this.onCancelEventCreation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!creatingEvent)
          FloatingActionButton(
            onPressed: onToggleEventCreation,
            tooltip: 'Register Event',
            child: const Icon(Icons.add_location),
          ),
        if (creatingEvent)
          FloatingActionButton(
            onPressed: onCancelEventCreation,
            tooltip: 'Cancel',
            backgroundColor: Colors.red,
            child: const Icon(Icons.cancel),
          ),
      ],
    );
  }
}
