import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tchaka/app/app.dart';
import 'package:tchaka/core/supabase/supabase_config.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    if (!Supabase.instance.isInitialized) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.publishableKey,
        authOptions: const FlutterAuthClientOptions(
          localStorage: EmptyLocalStorage(),
        ),
      );
    }
  });

  testWidgets(
    'TCHAKA démarre correctement',
    (WidgetTester tester) async {
      await tester.pumpWidget(const TchakaApp());

      await tester.pump();

      expect(find.byType(TchakaApp), findsOneWidget);
    },
  );
}
