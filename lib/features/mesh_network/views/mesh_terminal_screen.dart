import 'package:flutter/material.dart';

class MeshTerminalScreen extends StatefulWidget {
  const MeshTerminalScreen({super.key});

  @override
  State<MeshTerminalScreen> createState() => _MeshTerminalScreenState();
}

class _MeshTerminalScreenState extends State<MeshTerminalScreen> {
  bool _isMeshActive = false;
  final List<String> _logs = [
    "[SYSTEM] BLE Mesh Engine Ready.",
  ];

  void _sendPing(String status) {
    if (!_isMeshActive) return;
    setState(() {
      _logs.insert(0, "[OUTGOING] Ping sent: $status | Hops: 0 | Lat: 12.9716, Lng: 77.5946");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE Mesh Terminal'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: const Color(0xFF1E293B),
              child: SwitchListTile(
                title: const Text('Offline Mesh Mode', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_isMeshActive ? 'Advertising & Relaying Pings' : 'Mesh Disabled'),
                value: _isMeshActive,
                activeColor: const Color(0xFF38BDF8),
                onChanged: (val) => setState(() {
                  _isMeshActive = val;
                  _logs.insert(0, val ? "[SYSTEM] Mesh Service Started." : "[SYSTEM] Mesh Service Stopped.");
                }),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    onPressed: _isMeshActive ? () => _sendPing("SAFE") : null,
                    child: const Text('I AM SAFE'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    onPressed: _isMeshActive ? () => _sendPing("NEED HELP") : null,
                    child: const Text('NEED HELP'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF38BDF8).withAlpha(100)),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      _logs[index],
                      style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
