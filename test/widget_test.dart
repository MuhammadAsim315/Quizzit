// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:quizzit/screens/home_screen.dart';

void main() {
  testWidgets('Quiz app loads home screen', (WidgetTester tester) async {
    // Build just the HomeScreen inside a MaterialApp
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    // Trigger a frame
    await tester.pumpAndSettle();

    // Verify that home screen loads with category selection
    expect(find.text('Quiz Generator'), findsOneWidget);
    expect(find.text('Choose Your Category'), findsOneWidget);
  });
}
