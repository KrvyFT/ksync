// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:webdav_sync_tool/main.dart';
import 'package:webdav_sync_tool/presentation/pages/home_page.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We need to provide the BLoC here for the test to work.
    await tester.pumpWidget(const WebDavSyncApp());

    // Verify that the app shows the home page.
    expect(find.byType(HomePage), findsOneWidget);
  });
}
