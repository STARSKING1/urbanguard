import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';

class MeshTerminalScreen extends ConsumerWidget {
  const MeshTerminalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meshState = ref.watch(meshProvider);
    final meshNotifier = ref.read(meshProvider.notifier);

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(
                      meshState.isActive ? Icons.hub : Icons.portable_wifi_off,
                      color: meshState.isActive ? const Color(0xFF38BDF8) : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meshState.isActive ? 'Mesh Active (${meshState.activePeers} Nodes)' : 'Mesh Standby',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          meshState.isActive ? 'Advertising & Relaying Pings' : 'Toggle switch to initialize local radio',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Switch(
                      value: meshState.isActive,
                      activeThumbColor: const Color(0xFF38BDF8),
                      onChanged: (val) => meshNotifier.toggleMesh(val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('I AM SAFE', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: meshState.isActive ? () => meshNotifier.broadcastSignal('SAFE') : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.warning_amber),
                    label: const Text('NEED HELP', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: meshState.isActive ? () => meshNotifier.broadcastSignal('DISTRESS') : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF38BDF8).withAlpha(100)),
                ),
                child: ListView.builder(
                  itemCount: meshState.terminalLogs.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Text(
                      meshState.terminalLogs[index],
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
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
