import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tchaka/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TCHAKA app starts successfully', (tester) async {
    await Supabase.initialize(
      url: 'http://127.0.0.1:54321',
      publishableKey: 'test-publishable-key',
    );

    await tester.pumpWidget(const TchakaApp());
    await tester.pump();

    expect(find.text('Bienvenue sur TCHAKA'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
  });
}
