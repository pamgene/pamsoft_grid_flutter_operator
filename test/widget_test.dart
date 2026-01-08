// Basic Flutter widget test for Pamsoft Grid Checker

import 'package:flutter_test/flutter_test.dart';

import 'package:pamsoft_grid_flutter_operator/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PamsoftGridCheckerApp());

    // Verify that the app title is displayed
    expect(find.text('Pamsoft Grid Checker'), findsOneWidget);
  });
}
