import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kap/main.dart';
import 'package:kap/services/api_client.dart';

/// Fake client so the widget test is deterministic and does no real networking.
class _FakeApiClient extends ApiClient {
  @override
  Future<String> health() async => 'ok';
}

void main() {
  test('ApiClient applies the dev base URL', () {
    // Guards the constructor wiring: a regression here is why the app once
    // connected to a random port instead of :8000.
    expect(ApiClient().baseUrl, 'http://127.0.0.1:8000');
  });

  testWidgets('shows the KAP title and the API status', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(apiClient: _FakeApiClient())),
    );

    // Title is present immediately.
    expect(find.text('KAP'), findsOneWidget);

    // Let the (fake) health future resolve, then the status should render.
    await tester.pumpAndSettle();
    expect(find.text('ok'), findsOneWidget);
  });
}
