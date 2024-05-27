import 'dart:io';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';

import 'package:notice_track/yaml_readers/yaml_reader.dart';

class EventCreationDialog extends StatefulWidget {
  final LatLng latlng;
  final VoidCallback onCancel;
  final Function(String, String, String, List<XFile>) onSubmit;
  final YamlReader categoryReader;

  const EventCreationDialog({
    super.key,
    required this.latlng,
    required this.onCancel,
    required this.onSubmit,
    required this.categoryReader
  });

  @override
  State<EventCreationDialog> createState() => _EventCreationDialogState();
}

class _EventCreationDialogState extends State<EventCreationDialog> {
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Register Event'),
      content: _creationDialogContent(),
      actions: _creationDialogActions(context),
    );
  }

  Widget _creationDialogContent() {
    return SingleChildScrollView(
      child: ListBody(
        children: [
          TextField(
            controller: _labelController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Enter event type here'),
            textInputAction: TextInputAction.next,
          ),
          DropdownMenu<String>(
            dropdownMenuEntries: widget.categoryReader.getCategories()[0].map<DropdownMenuEntry<String>>((dynamic s) {
              return DropdownMenuEntry<String>(label: s as String, value: s);
            }).toList(),
            controller: _categoryController,
            requestFocusOnTap: true,
            label: const Text('Category'),
          ),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(hintText: 'Enter description here'),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _pickImages,
            child: const Text('Pick Images'),
          ),
          const SizedBox(height: 10),
          _pickedImages.isNotEmpty ? Wrap(
            children: _pickedImages
                .map((img) => Image.file(File(img.path), width: 80, height: 80))
                .toList(),
          ) : const Text('No images selected'),
        ],
      ),
    );
  }

  List<Widget> _creationDialogActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () {
          widget.onCancel();
          Navigator.of(context).pop();
        },
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () {
          if (_labelController.text.isNotEmpty) {
            widget.onSubmit(
              _labelController.text,
              _descriptionController.text,
              _categoryController.text,
              _pickedImages,
            );
            Navigator.of(context).pop();
          }
        },
        child: const Text('Submit'),
      ),
    ];
  }

  void _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(images);
      });
    }
  }
}
