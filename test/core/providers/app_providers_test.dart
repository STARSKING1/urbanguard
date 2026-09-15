import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urbanguard/core/providers/app_providers.dart';

void main() {
  group('MeshNotifier Tests', () {
    test('Initial mesh state should be inactive with 0 peers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(meshProvider);
      expect(state.isActive, false);
      expect(state.activePeers, 0);
    });

    test('Toggling mesh ON updates state and peer count', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(meshProvider.notifier);
      notifier.toggleMesh(true);

      final state = container.read(meshProvider);
      expect(state.isActive, true);
      expect(state.activePeers, 4);
      expect(state.terminalLogs.first.contains('[BLE]'), true);
    });

    test('Broadcasting signal appends log when active', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(meshProvider.notifier);
      notifier.toggleMesh(true);
      notifier.broadcastSignal('SAFE');

      final state = container.read(meshProvider);
      expect(state.terminalLogs.first.contains('BROADCAST SOS (SAFE)'), true);
    });
  });

  group('HazardListProvider Tests', () {
    test('Filtering by category returns subset of hazards', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedCategoryProvider.notifier).state = 'FLOOD';
      final hazards = container.read(hazardListProvider);

      expect(hazards.length, 1);
      expect(hazards.first.category, 'FLOOD');
    });
  });
}
