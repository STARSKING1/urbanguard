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
