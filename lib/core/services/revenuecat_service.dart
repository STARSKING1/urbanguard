import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const _apiKeyIOS = 'goog_revenuecat_ios_api_key_here';
  static const _apiKeyAndroid = 'goog_revenuecat_android_api_key_here';

  static Future<void> init() async {
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
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['pro_access']?.isActive ?? false;
    } catch (e) {
      debugPrint('Error fetching RevenueCat entitlement: $e');
      return false;
    }
  }
}
