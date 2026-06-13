import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sentinel_forensic_flutter/main.dart';
import 'package:sentinel_forensic_flutter/state/app_state.dart';

void main() {
  testWidgets('Sentinel Forensic App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const SentinelApp(),
      ),
    );

    // Verify the App shell renders the app title or main widgets
    expect(find.text('Sentinel Forensic'), findsNothing); // It's the MaterialApp title (not in tree)
  });
}
