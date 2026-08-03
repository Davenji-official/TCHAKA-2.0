import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tchaka/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TCHAKA app starts successfully', (tester) async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );

    await tester.pumpWidget(const TchakaApp());
    await tester.pump();

    expect(find.text('TCHAKA'), findsOneWidget);
  });
}
