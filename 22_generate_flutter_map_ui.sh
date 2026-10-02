#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%dT%H:%M:%S')] [FLUTTER_GEN] $1${NC}"
}

log "Creating Flutter directory structure under lib/..."
mkdir -p lib/models lib/services lib/view_models lib/views

# 1. lib/models/hazard_model.dart
log "Writing Data Model to 'lib/models/hazard_model.dart'..."
cat << 'FILE_EOF' > lib/models/hazard_model.dart
import 'package:flutter/material.dart';

enum HazardSeverity { low, medium, high, critical }

class HazardModel {
  final String id;
  final String title;
  final String category;
  final double latitude;
  final double longitude;
  final double radiusKm;
  final double distanceKm;
  final HazardSeverity severity;
  final DateTime timestamp;

  HazardModel({
    required this.id,
    required this.title,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
    required this.distanceKm,
    required this.severity,
    required this.timestamp,
  });

  factory HazardModel.fromJson(Map<String, dynamic> json) {
    return HazardModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unknown Hazard',
      category: json['category'] ?? 'General',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusKm: (json['radius_km'] as num? ?? 1.0).toDouble(),
      distanceKm: (json['distance_km'] as num? ?? 0.0).toDouble(),
      severity: _parseSeverity(json['severity']),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  static HazardSeverity _parseSeverity(String? value) {
    switch (value?.toLowerCase()) {
      case 'critical':
        return HazardSeverity.critical;
      case 'high':
        return HazardSeverity.high;
      case 'medium':
        return HazardSeverity.medium;
      case 'low':
      default:
        return HazardSeverity.low;
    }
  }

  Color get color {
    switch (severity) {
      case HazardSeverity.critical:
        return const Color(0xFFD32F2F);
      case HazardSeverity.high:
        return const Color(0xFFF57C00);
      case HazardSeverity.medium:
        return const Color(0xFFFBC02D);
      case HazardSeverity.low:
        return const Color(0xFF388E3C);
    }
  }

  IconData get icon {
    switch (category.toLowerCase()) {
      case 'flood':
        return Icons.water_damage;
      case 'chemical':
        return Icons.warning_amber_rounded;
      case 'infrastructure':
        return Icons.business_sharp;
      default:
        return Icons.location_on;
    }
  }
}
FILE_EOF

# 2. lib/services/hazard_api_service.dart
log "Writing API Service to 'lib/services/hazard_api_service.dart'..."
cat << 'FILE_EOF' > lib/services/hazard_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hazard_model.dart';

class HazardApiService {
  static const String _baseUrl = 'http://127.0.0.1:8080';
  final http.Client _client;

  HazardApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<HazardModel>> fetchNearbyHazards({
    required double latitude,
    required double longitude,
    double radiusKm = 25.0,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/hazards?lat=$latitude&lng=$longitude&radius=$radiusKm',
    );

    try {
      final response = await _client.get(uri).timeout(
            const Duration(seconds: 3),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => HazardModel.fromJson(item)).toList();
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to local Termux Spatial Engine: $e');
    }
  }
}
FILE_EOF

# 3. lib/view_models/hazard_view_model.dart
log "Writing View Model to 'lib/view_models/hazard_view_model.dart'..."
cat << 'FILE_EOF' > lib/view_models/hazard_view_model.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/hazard_model.dart';
import '../services/hazard_api_service.dart';

enum ViewState { idle, loading, success, error }

class HazardViewModel extends ChangeNotifier {
  final HazardApiService _apiService;
  
  ViewState _state = ViewState.idle;
  List<HazardModel> _hazards = [];
  String _errorMessage = '';
  Timer? _pollingTimer;

  double _currentLat = 12.9716;
  double _currentLng = 77.5946;
  double _filterRadiusKm = 25.0;

  HazardViewModel({HazardApiService? apiService})
      : _apiService = apiService ?? HazardApiService();

  ViewState get state => _state;
  List<HazardModel> get hazards => _hazards;
  String get errorMessage => _errorMessage;
  double get currentLat => _currentLat;
  double get currentLng => _currentLng;
  double get filterRadiusKm => _filterRadiusKm;

  void startPolling({int intervalSeconds = 3}) {
    _pollingTimer?.cancel();
    fetchHazards();
    _pollingTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (_) => fetchHazards(silent: true),
    );
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  void updateLocation(double lat, double lng) {
    _currentLat = lat;
    _currentLng = lng;
    fetchHazards();
  }

  void updateRadius(double newRadiusKm) {
    _filterRadiusKm = newRadiusKm;
    fetchHazards();
  }

  Future<void> fetchHazards({bool silent = false}) async {
    if (!silent) {
      _state = ViewState.loading;
      notifyListeners();
    }

    try {
      _hazards = await _apiService.fetchNearbyHazards(
        latitude: _currentLat,
        longitude: _currentLng,
        radiusKm: _filterRadiusKm,
      );
      _state = ViewState.success;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString();
      _state = ViewState.error;
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
FILE_EOF

# 4. lib/views/hazard_map_screen.dart
log "Writing Map UI View Screen to 'lib/views/hazard_map_screen.dart'..."
cat << 'FILE_EOF' > lib/views/hazard_map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/hazard_model.dart';
import '../view_models/hazard_view_model.dart';

class HazardMapScreen extends StatefulWidget {
  const HazardMapScreen({super.key});

  @override
  State<HazardMapScreen> createState() => _HazardMapScreenState();
}

class _HazardMapScreenState extends State<HazardMapScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HazardViewModel>().startPolling();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HazardViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('UrbanGuard Live Hazard Map'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => viewModel.fetchHazards(),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(viewModel.currentLat, viewModel.currentLng),
              initialZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.urbanguard.resilience',
              ),
              CircleLayer(
                circles: viewModel.hazards.map((hazard) {
                  return CircleMarker(
                    point: LatLng(hazard.latitude, hazard.longitude),
                    color: hazard.color.withOpacity(0.2),
                    borderColor: hazard.color,
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                    radius: hazard.radiusKm * 1000,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: viewModel.hazards.map((hazard) {
                  return Marker(
                    point: LatLng(hazard.latitude, hazard.longitude),
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _showHazardBottomSheet(context, hazard),
                      child: Container(
                        decoration: BoxDecoration(
                          color: hazard.color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          hazard.icon,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          if (viewModel.state == ViewState.error)
            Positioned(
              top: 10,
              left: 15,
              right: 15,
              child: Card(
                color: Colors.redAccent,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Termux API Offline: ${viewModel.errorMessage}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showHazardBottomSheet(BuildContext context, HazardModel hazard) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(hazard.icon, color: hazard.color, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hazard.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text('Category: ${hazard.category}'),
              Text('Severity: ${hazard.severity.name.toUpperCase()}'),
              Text('Impact Radius: ${hazard.radiusKm} km'),
              Text('Distance: ${hazard.distanceKm} km away'),
              Text('Timestamp: ${hazard.timestamp.toLocal()}'),
            ],
          ),
        );
      },
    );
  }
}
FILE_EOF

echo -e "${GREEN}==========================================================${NC}"
echo -e "${GREEN}  FLUTTER MAP UI STACK GENERATED CLEANLY IN lib/          ${NC}"
echo -e "${GREEN}==========================================================${NC}"
