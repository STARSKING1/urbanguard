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
