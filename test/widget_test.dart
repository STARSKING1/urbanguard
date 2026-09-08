import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:urbanguard/main.dart';

void main() {
  testWidgets('UrbanGuard app Smoke Test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: UrbanGuardApp()));
    expect(find.byType(UrbanGuardApp), findsOneWidget);
  });
}
