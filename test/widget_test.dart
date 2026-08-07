import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tchaka/app/app.dart';
import 'package:tchaka/core/supabase/supabase_config.dart';

void main() {
  // AuthGate reads Supabase.instance as soon as it builds. main() normally
  // sets that up before runApp(), but a widget test pumps TchakaApp()
  // directly and never calls main() — so without this, the very first
  // frame throws ("You must initialize the supabase instance...") and the
  // whole CI job goes red before the build jobs even start.
  //
  // EmptyLocalStorage skips native session-persistence plugins (no
  // platform channel is registered in a plain `flutter test` sandbox),
  // so this stays a pure in-memory init with no real network requirement.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.publishableKey,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
      ),
    );
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
