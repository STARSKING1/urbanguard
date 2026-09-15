import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const _apiKeyAndroid = 'entl9b27e83c00';
  static const _apiKeyIOS = 'entl9b27e83c00';

  static Future<void> init() async {
    // Avoid platform channel calls during automated unit/widget testing
    if (kTestMode) return;

    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKeyAndroid);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKeyIOS);
    } else {
      return;
    }

    await Purchases.configure(configuration);
  }

  static Future<bool> isProUser() async {
    if (kTestMode) return false;

    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['pro_access']?.isActive ?? false;
    } catch (e) {
      if (kDebugMode) print("RevenueCat status error: $e");
      return false;
    }
  }

  static bool get kTestMode =>
      num.parse(Platform.environment['FLUTTER_TEST'] ?? '0') == 1 ||
      Platform.environment.containsKey('FLUTTER_TEST');
}
