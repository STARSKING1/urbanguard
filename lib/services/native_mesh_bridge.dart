import 'dart:convert';
import 'package:flutter/services.dart';

class NativeMeshBridge {
  static const MethodChannel _channel = MethodChannel('com.urbanguard.resilience/mesh');

  static Future<bool> broadcastHazardAlert({
    required String id,
    required String title,
    required double latitude,
    required double longitude,
    required String severity,
  }) async {
    try {
      final payloadMap = {
        'id': id,
        'type': 'HAZARD_ALERT',
        'title': title,
        'latitude': latitude,
        'longitude': longitude,
        'severity': severity,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final bool success = await _channel.invokeMethod('broadcastMeshPacket', {
        'payload': jsonEncode(payloadMap),
      });

      return success;
    } on PlatformException catch (_) {
      return false;
    }
  }

  static Future<bool> isLocalServerActive() async {
    try {
      final bool isActive = await _channel.invokeMethod('checkServerStatus');
      return isActive;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
