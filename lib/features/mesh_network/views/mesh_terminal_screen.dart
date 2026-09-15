import 'package:flutter/material.dart';

class MeshTerminalScreen extends StatelessWidget {
  const MeshTerminalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mesh Terminal')),
      body: const Center(child: Text('Offline Mesh Network Active')),
    );
  }
}
