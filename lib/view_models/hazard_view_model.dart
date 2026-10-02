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
