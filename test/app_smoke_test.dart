import 'package:flutter_test/flutter_test.dart';
import 'package:tchaka/app/app.dart';

void main() {
  testWidgets('TCHAKA app starts successfully', (tester) async {
    await tester.pumpWidget(const TchakaApp());

    expect(find.text('TCHAKA'), findsOneWidget);
    expect(find.text('TCHAKA 2.0 Foundation'), findsOneWidget);
  });
}
