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
