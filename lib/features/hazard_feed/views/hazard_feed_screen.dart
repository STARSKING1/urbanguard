import 'package:flutter/material.dart';

class HazardFeedScreen extends StatelessWidget {
  const HazardFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hazard Feed')),
      body: const Center(child: Text('Active Hazard Feed')),
    );
  }
}
