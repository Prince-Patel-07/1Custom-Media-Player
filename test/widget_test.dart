import 'package:custom_media_player/app/app.dart';
import 'package:custom_media_player/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders core tabs and title', (WidgetTester tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(() => database.close());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: const CustomMediaPlayerApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Custom Media Player'), findsOneWidget);
    expect(find.text('Local Library'), findsOneWidget);
    expect(find.text('Online Samples'), findsOneWidget);
    expect(find.text('Your Setup'), findsOneWidget);
  });
}
