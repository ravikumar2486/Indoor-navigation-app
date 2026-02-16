// lib/widgets/current_location_button.dart
import 'package:flutter/material.dart';

class CurrentLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CurrentLocationButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: Color(0xFF0D00A3),
      onPressed: onPressed,
      tooltip: 'Current Location',
      child: const Icon(Icons.my_location),
    );
  }
}
