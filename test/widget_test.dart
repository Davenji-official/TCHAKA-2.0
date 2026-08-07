import 'package:flutter_test/flutter_test.dart';

import 'package:tchaka/app/app.dart';
void main() {
  testWidgets('TCHAKA app boots', (WidgetTester tester) async {
    await tester.pumpWidget(const TchakaApp());
    await tester.pump();

    expect(find.byType(TchakaApp), findsOneWidget);
  });
}
