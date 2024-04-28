import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:location_tracker/firebase_options.dart';
import 'package:location_tracker/firebase_write.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';
import 'package:stream_test/stream_test.dart';

import 'package:location_tracker/main.dart';
import 'package:location_tracker/view_all_issues_page.dart';

class MockDatabaseReference extends Mock implements FirebaseDriver{}


void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final mockDatabaseReference = MockDatabaseReference();
    final testData = [LocationAlert(latitude: 1.001, longitude: 2.024, title: 'Example', category: Category.Other, description: 'Test')];

    // testData = 1;
    when (mockDatabaseReference.read()).thenAnswer((_) => Stream.value(testData));



    print("okay");

    await tester.pumpWidget(ShowCurrentIssues(database: mockDatabaseReference));



    expect(find.text('Example'), findsAtLeast(1));
    expect(find.text('Other'), findsAtLeast(1));
    expect(find.text('Test'), findsAtLeast(1));

    expect(find.text('1.001'), findsAtLeast(1));
    expect(find.text('2.024'), findsAtLeast(1));


  });


}
