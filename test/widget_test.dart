import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urbanguard/main.dart';

final Uint8List _transparentImage = Uint8List.fromList(<int>[
  0x47, 0x49, 0x46, 0x38, 0x39, 0x61, 0x01, 0x00, 0x01, 0x00,
  0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x21,
  0xF9, 0x04, 0x01, 0x00, 0x00, 0x00, 0x00, 0x2C, 0x00, 0x00,
  0x00, 0x00, 0x01, 0x00, 0x01, 0x00, 0x00, 0x02, 0x02, 0x44,
  0x01, 0x00, 0x3B,
]);

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => _transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<Uint8List>.value(_transparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();

    // Mock Purchases/RevenueCat MethodChannel responses for test environment
    const MethodChannel channel = MethodChannel('purchases_flutter');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'setupPurchases' ||
          methodCall.method == 'setLogLevel') {
        return null;
      }
      if (methodCall.method == 'getCustomerInfo') {
        return {
          'entitlements': {'all': {}},
          'activeSubscriptions': [],
          'allPurchasedProductIdentifiers': [],
          'latestExpirationDate': null,
          'firstSeen': '2026-01-01T00:00:00Z',
          'originalAppUserId': 'test_user',
          'requestDate': '2026-01-01T00:00:00Z',
        };
      }
      return null;
    });
  });

  testWidgets('UrbanGuard app Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: UrbanGuardApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Live Risk Perimeter'), findsOneWidget);
    expect(find.byIcon(Icons.radar), findsOneWidget);
    expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
  });
}
