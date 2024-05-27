import 'dart:io';
import 'package:flutter/material.dart';

class PhotoTile extends StatelessWidget {
  final File photo;
  final VoidCallback onRemove;

  PhotoTile({required this.photo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Image.file(photo),
        IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: onRemove,
        ),
      ],
    );
  }
}
