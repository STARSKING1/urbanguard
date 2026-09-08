import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HazardFeedScreen extends StatefulWidget {
  const HazardFeedScreen({super.key});

  @override
  State<HazardFeedScreen> createState() => _HazardFeedScreenState();
}

class _HazardFeedScreenState extends State<HazardFeedScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialCenter = const LatLng(12.9716, 77.5946);

  final List<Map<String, dynamic>> _hazards = [
    {
      'title': 'Urban Flood Watch',
      'severity': 'HIGH',
      'location': const LatLng(12.9780, 77.5900),
      'radius': 1200.0,
      'time': '10 mins ago',
    },
    {
      'title': 'Power Grid Outage Zone',
      'severity': 'MEDIUM',
      'location': const LatLng(12.9620, 77.6010),
      'radius': 800.0,
      'time': '25 mins ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Hazard Feed'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () => _mapController.move(_initialCenter, 13.0),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 12.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.starsking1.urbanguard',
              ),
              CircleLayer(
                circles: _hazards.map((hazard) {
                  final isHigh = hazard['severity'] == 'HIGH';
                  return CircleMarker(
                    point: hazard['location'] as LatLng,
                    radius: hazard['radius'] as double,
                    useRadiusInMeter: true,
                    color: isHigh
                        ? Colors.red.withOpacity(0.35)
                        : Colors.orange.withOpacity(0.35),
                    borderColor: isHigh ? Colors.red : Colors.orange,
                    borderStrokeWidth: 2.0,
                  );
                }).toList(),
              ),
              MarkerLayer(
                markers: _hazards.map((hazard) {
                  return Marker(
                    point: hazard['location'] as LatLng,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: hazard['severity'] == 'HIGH' ? Colors.red : Colors.amber,
                      size: 32,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _hazards.length,
                itemBuilder: (context, index) {
                  final item = _hazards[index];
                  return Container(
                    width: 260,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item['severity'] == 'HIGH' ? Colors.red : Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['severity'],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                            const Spacer(),
                            Text(item['time'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
