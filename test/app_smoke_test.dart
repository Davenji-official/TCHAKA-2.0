import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tchaka/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('Login screen renders successfully', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.pump();

    expect(find.text('Bienvenue sur TCHAKA'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });
}
