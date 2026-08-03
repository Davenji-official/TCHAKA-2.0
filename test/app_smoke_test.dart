import 'package:flutter_test/flutter_test.dart';
import 'package:tchaka/app/app.dart';

void main() {
  testWidgets('TCHAKA app starts successfully', (tester) async {
    await tester.pumpWidget(const TchakaApp());

    await tester.pump();

    expect(find.text('Bienvenue sur TCHAKA'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
  });
}
