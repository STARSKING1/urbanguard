#!/usr/bin/env bash
set -euo pipefail
export PATH="/data/data/com.termux/files/usr/bin:$PATH"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

printf "${BLUE}[SETUP] Initializing Flutter entrypoint and project dependencies...${NC}\n"

# Ensure lib directory exists
mkdir -p lib

# 1. Write lib/main.dart
printf "${BLUE}[1/2] Writing 'lib/main.dart'...${NC}\n"
cat << 'MAIN_EOF' > lib/main.dart
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
        title: 'UrbanGuard Resilience Engine',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF38BDF8),
            secondary: Color(0xFFF59E0B),
            surface: Color(0xFF1E293B),
            error: Color(0xFFEF4444),
            onPrimary: Colors.black,
            onSurface: Color(0xFFF8FAFC),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E293B),
            elevation: 0,
            centerTitle: false,
            titleTextStyle: TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          cardTheme: CardTheme(
            color: const Color(0xFF1E293B),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF334155), width: 1),
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF1E293B),
            modalBackgroundColor: Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
        ),
        home: const HazardMapScreen(),
      ),
    );
  }
}
MAIN_EOF

# 2. Write pubspec.yaml
printf "${BLUE}[2/2] Writing 'pubspec.yaml'...${NC}\n"
cat << 'PUBSPEC_EOF' > pubspec.yaml
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
PUBSPEC_EOF

printf "${GREEN}[SUCCESS] Created lib/main.dart and pubspec.yaml.${NC}\n"

# 3. Resolve dependencies if Flutter binary is accessible
if command -v flutter >/dev/null 2>&1; then
  printf "${BLUE}[FETCH] Resolving packages via 'flutter pub get'...${NC}\n"
  flutter pub get
else
  printf "${BLUE}[INFO] Flutter CLI not detected in PATH. Run 'flutter pub get' once your environment is configured.${NC}\n"
fi
