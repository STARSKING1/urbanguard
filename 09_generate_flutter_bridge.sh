#!/usr/bin/env bash
set -euo pipefail

KOTLIN_DIR="android/app/src/main/kotlin/com/urbanguard/resilience"
DART_DIR="lib/services"

mkdir -p "$KOTLIN_DIR" "$DART_DIR"

cat << 'KOTLIN_EOF' > "$KOTLIN_DIR/NativeMeshBridge.kt"
package com.urbanguard.resilience

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress

class NativeMeshBridge(flutterEngine: FlutterEngine) {
    private val CHANNEL = "com.urbanguard.resilience/mesh"

    init {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "broadcastMeshPacket" -> {
                    val payload = call.argument<String>("payload")
                    if (payload != null) {
                        val success = sendUdpBroadcast(payload)
                        result.success(success)
                    } else {
                        result.error("INVALID_PAYLOAD", "Payload cannot be null", null)
                    }
                }
                "checkServerStatus" -> {
                    val isRunning = checkLocalPort(8080)
                    result.success(isRunning)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun sendUdpBroadcast(payload: String): Boolean {
        return try {
            val socket = DatagramSocket()
            socket.broadcast = true
            val bytes = payload.toByteArray(Charsets.UTF_8)
            val packet = DatagramPacket(
                bytes,
                bytes.size,
                InetAddress.getByName("255.255.255.255"),
                9090
            )
            socket.send(packet)
            socket.close()
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    private fun checkLocalPort(port: Int): Boolean {
        return try {
            val socket = java.net.Socket("127.0.0.1", port)
            socket.close()
            true
        } catch (e: Exception) {
            false
        }
    }
}
KOTLIN_EOF

cat << 'DART_EOF' > "$DART_DIR/native_mesh_bridge.dart"
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
DART_EOF

echo "[SUCCESS] Flutter Native Bridges generated in android/ and lib/"
