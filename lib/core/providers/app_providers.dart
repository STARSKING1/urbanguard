import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../services/revenuecat_service.dart';

// --- Entitlement State ---
final proStatusProvider = StateNotifierProvider<ProStatusNotifier, bool>((ref) {
  return ProStatusNotifier();
});

class ProStatusNotifier extends StateNotifier<bool> {
  ProStatusNotifier() : super(false) {
    checkStatus();
  }

  Future<void> checkStatus() async {
    state = await RevenueCatService.isProUser();
  }

  void setMockPro(bool value) {
    state = value;
  }
}

// --- Hazard Model & Provider ---
class HazardModel {
  final String id;
  final String title;
  final String category;
  final String severity;
  final LatLng location;
  final double radiusMeters;
  final String timestamp;

  HazardModel({
    required this.id,
    required this.title,
    required this.category,
    required this.severity,
    required this.location,
    required this.radiusMeters,
    required this.timestamp,
  });
}

final selectedCategoryProvider = StateProvider<String>((ref) => 'ALL');

final hazardListProvider = Provider<List<HazardModel>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final allHazards = [
    HazardModel(
      id: 'h1',
      title: 'Urban Flash Flood Watch',
      category: 'FLOOD',
      severity: 'HIGH',
      location: const LatLng(12.9780, 77.5900),
      radiusMeters: 1400.0,
      timestamp: '5m ago',
    ),
    HazardModel(
      id: 'h2',
      title: 'Major Power Grid Outage',
      category: 'GRID',
      severity: 'CRITICAL',
      location: const LatLng(12.9620, 77.6010),
      radiusMeters: 900.0,
      timestamp: '18m ago',
    ),
    HazardModel(
      id: 'h3',
      title: 'Substation Transformer Fire',
      category: 'FIRE',
      severity: 'HIGH',
      location: const LatLng(12.9850, 77.6050),
      radiusMeters: 600.0,
      timestamp: '32m ago',
    ),
  ];

  if (category == 'ALL') return allHazards;
  return allHazards.where((h) => h.category == category).toList();
});

// --- Mesh Network State ---
class MeshState {
  final bool isActive;
  final int activePeers;
  final List<String> terminalLogs;

  MeshState({
    required this.isActive,
    required this.activePeers,
    required this.terminalLogs,
  });

  MeshState copyWith({
    bool? isActive,
    int? activePeers,
    List<String>? terminalLogs,
  }) {
    return MeshState(
      isActive: isActive ?? this.isActive,
      activePeers: activePeers ?? this.activePeers,
      terminalLogs: terminalLogs ?? this.terminalLogs,
    );
  }
}

final meshProvider = StateNotifierProvider<MeshNotifier, MeshState>((ref) {
  return MeshNotifier();
});

class MeshNotifier extends StateNotifier<MeshState> {
  MeshNotifier()
      : super(MeshState(
          isActive: false,
          activePeers: 0,
          terminalLogs: ['[SYSTEM] BLE Mesh Engine Initialized.'],
        ));

  void toggleMesh(bool active) {
    if (active) {
      state = state.copyWith(
        isActive: true,
        activePeers: 4,
        terminalLogs: [
          '[BLE] Advertising service UUID 0xFD6F...',
          '[PEERS] Discovered Node 0x9A4F (RSSI -64dBm)',
          '[PEERS] Discovered Node 0x3C1E (RSSI -72dBm)',
          ...state.terminalLogs,
        ],
      );
    } else {
      state = state.copyWith(
        isActive: false,
        activePeers: 0,
        terminalLogs: [
          '[SYSTEM] BLE Radio Powered Down.',
          ...state.terminalLogs,
        ],
      );
    }
  }

  void broadcastSignal(String status) {
    if (!state.isActive) return;
    final log =
        '[TX] BROADCAST SOS ($status) | Hops: 0 | TTL: 7 | Lat: 12.9716, Lng: 77.5946';
    state = state.copyWith(
      terminalLogs: [log, ...state.terminalLogs],
    );
  }
}
