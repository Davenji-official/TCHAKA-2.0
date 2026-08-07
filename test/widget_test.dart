import 'package:flutter_test/flutter_test.dart';
import 'package:tchaka/app/app.dart';

void main() {
  testWidgets(
    'TCHAKA démarre correctement',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TchakaApp());

      await tester.pumpAndSettle();

      expect(find.byType(TchakaApp), findsOneWidget);
    },
  );
}
