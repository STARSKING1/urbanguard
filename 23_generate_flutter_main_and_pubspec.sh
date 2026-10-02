#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%dT%H:%M:%S')] [FLUTTER_CONFIG] $1${NC}"
}

log "Generating 'pubspec.yaml' configuration..."
cat << 'FILE_EOF' > pubspec.yaml
name: urbanguard_resilience
description: UrbanGuard Native Disaster Resilience & Spatial Hazard Map Engine
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6
  flutter_map: ^6.1.0
  latlong2: ^0.9.0
  provider: ^6.1.1
  http: ^1.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
FILE_EOF

log "Generating 'lib/main.dart' application entrypoint..."
cat << 'FILE_EOF' > lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/hazard_api_service.dart';
import 'view_models/hazard_view_model.dart';
import 'views/hazard_map_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UrbanGuardApp());
}

class UrbanGuardApp extends StatelessWidget {
  const UrbanGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<HazardApiService>(
          create: (_) => HazardApiService(),
        ),
        ChangeNotifierProxyProvider<HazardApiService, HazardViewModel>(
          create: (context) => HazardViewModel(
            apiService: context.read<HazardApiService>(),
          ),
          update: (context, apiService, previous) =>
              previous ?? HazardViewModel(apiService: apiService),
        ),
      ],
      child: MaterialApp(
        title: 'UrbanGuard Resilience',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueGrey,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        home: const HazardMapScreen(),
      ),
    );
  }
}
FILE_EOF

echo -e "${GREEN}==========================================================${NC}"
echo -e "${GREEN}  FLUTTER CONFIGURATION & MAIN ENTRYPOINT CREATED CLEANLY  ${NC}"
echo -e "${GREEN}==========================================================${NC}"
