import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/providers/app_providers.dart';

class HazardFeedScreen extends ConsumerStatefulWidget {
  const HazardFeedScreen({super.key});

  @override
  ConsumerState<HazardFeedScreen> createState() => _HazardFeedScreenState();
}

class _HazardFeedScreenState extends ConsumerState<HazardFeedScreen> {
  final MapController _mapController = MapController();
  final LatLng _defaultCenter = const LatLng(12.9716, 77.5946);

  @override
  Widget build(BuildContext context) {
    final hazards = ref.watch(hazardListProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Risk Perimeter', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Color(0xFF38BDF8)),
            onPressed: () => _mapController.move(_defaultCenter, 13.0),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 12.8,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.starsking1.urbanguard',
              ),
              CircleLayer(
                circles: hazards.map((h) {
                  final isCritical = h.severity == 'CRITICAL';
                  return CircleMarker(
                    point: h.location,
                    radius: h.radiusMeters,
                    useRadiusInMeter: true,
                    color: isCritical
                        ? Colors.red.withAlpha(80)
                        : Colors.orange.withAlpha(80),
                    borderColor: isCritical ? Colors.red : Colors.orange,
                    borderStrokeWidth: 2.0,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: hazards.map((h) {
                  return Marker(
                    point: h.location,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: h.severity == 'CRITICAL' ? Colors.red : Colors.orange,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        h.category == 'FLOOD'
                            ? Icons.water_damage
                            : h.category == 'GRID'
                                ? Icons.power_off
                                : Icons.local_fire_department,
                        color: h.severity == 'CRITICAL' ? Colors.red : Colors.amber,
                        size: 24,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['ALL', 'FLOOD', 'GRID', 'FIRE'].map((cat) {
                  final isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(cat, style: TextStyle(color: isSelected ? Colors.black : Colors.white)),
                      selectedColor: const Color(0xFF38BDF8),
                      backgroundColor: const Color(0xFF1E293B).withAlpha(230),
                      onSelected: (_) => ref.read(selectedCategoryProvider.notifier).state = cat,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 12,
            right: 12,
            child: SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: hazards.length,
                itemBuilder: (context, index) {
                  final h = hazards[index];
                  return Container(
                    width: 270,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withAlpha(245),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: h.severity == 'CRITICAL' ? Colors.red : Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                h.severity,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                            const Spacer(),
                            Text(h.timestamp, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(h.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Perimeter Radius: ${(h.radiusMeters / 1000).toStringAsFixed(1)} km',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
