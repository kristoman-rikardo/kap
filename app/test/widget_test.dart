import 'package:flutter_test/flutter_test.dart';

import 'package:kap/main.dart';

void main() {
  testWidgets('app shows the KAP title on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const KapApp());

    expect(find.text('KAP'), findsOneWidget);
  });
}
