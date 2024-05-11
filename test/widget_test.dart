import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/mockito.dart';
import 'package:notice_track/app.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:notice_track/database/firestore_service.dart';
import 'package:notice_track/home_page.dart';
import 'package:notice_track/settings_page.dart';
import 'package:notice_track/widgets/map.dart';

class MockFirebaseService extends Mock implements FirestoreService{
  List<MarkerData> markers = [MarkerData(position: const LatLng(1.0, 2.0), label: 'Example', description: 'Example', )];

  @override
  Stream<List<MarkerData>> pullMarkers() {

    return Stream.fromIterable([
      markers
    ]);
  }

  @override
  Future<void> pushMarker(LatLng position, String label, String description){
    markers.add(MarkerData(position: position, label: label, description: description));
    return Future.value();
  }
}


void main() {
  group('User Interface', () {
    testWidgets(
        'Event creation button toggles correctly', (WidgetTester tester) async {
      // Build app and trigger a frame

      MockFirebaseService mockFirebase = MockFirebaseService();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase));

      await tester.pumpAndSettle();

      // Verify that the create event button is present
      expect(find.byIcon(Icons.add_location), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);

      // Tap the create event button
      await tester.tap(find.byIcon(Icons.add_location));
      await tester.pumpAndSettle();

      // Now cancel should be visible
      expect(find.byIcon(Icons.cancel), findsOneWidget);
      expect(find.byIcon(Icons.add_location), findsNothing);

      // Tap on cancel
      await tester.tap(find.byIcon(Icons.cancel));
      await tester.pumpAndSettle();

      // Should revert to initial state
      expect(find.byIcon(Icons.add_location), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('Tapping map during event creation triggers a dialog', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      // Open event creation mode
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase,));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simulate map tap
      await tester.tap(find.byType(FlutterMap));
      await tester.pumpAndSettle();

      // Expect dialog to open with label and description field
      expect(find.text('Register Event'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Marker gets added on map after event registration', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      // Initial setup
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simulate map tap
      await tester.tap(find.byType(FlutterMap));
      await tester.pumpAndSettle();

      // Fill out the form
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter event type here'),
          'Test Event');
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter description here'),
          'Test Description');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Check if the marker is displayed
      // expect(find.descendant(of: find.byType(FlutterMap), matching: find.widgetWithText(Container, 'Test Event')), findsOneWidget);

      // Check if text related to 'Test Event' exists and is visible on the marker
      expect(find.descendant(of: find.byType(FlutterMap),
          matching: find.widgetWithText(Container, 'Test Event')),
          findsOneWidget);
    });

    testWidgets('Pressing submit with empty fields should not add a marker', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      // Open event creation mode
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase,));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simulate map tap
      await tester.tap(find.byType(FlutterMap));
      await tester.pumpAndSettle();

      // Don't fill out the form, just press submit
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Check no marker is displayed
      expect(find.descendant(of: find.byType(FlutterMap),
          matching: find.widgetWithText(Container, '')),
          findsNothing);
    });

    testWidgets(
        'Pressing cancel during event creation should not add a marker', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      // Open event creation mode
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase,));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simulate map tap
      await tester.tap(find.byType(FlutterMap));
      await tester.pumpAndSettle();

      // Fill out the form but press cancel
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter event type here'),
          'Test Event');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Check no marker is displayed
      expect(find.descendant(of: find.byType(FlutterMap),
          matching: find.widgetWithText(Container, 'Test Event')),
          findsNothing);
    });

    testWidgets('Markers display label on map without interaction', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      // Open event creation mode
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase,));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simulate map tap
      await tester.tap(find.byType(FlutterMap));
      await tester.pumpAndSettle();

      // Input the test event
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter event type here'),
          'Test Event');
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter description here'), '');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Check if the marker with label 'Test Event' is displayed on the map
      expect(find.descendant(of: find.byType(FlutterMap),
          matching: find.widgetWithText(Container, 'Test Event')),
          findsOneWidget);
    });

    testWidgets(
        'Markers retain correct label and description upon dialog interaction', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      // Open event creation mode
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase,));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simulate map tap
      await tester.tap(find.byType(FlutterMap));
      await tester.pumpAndSettle();

      // Input label and description then submit
      String testLabel = 'Test Event';
      String testDescription = 'Test event description.';
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter event type here'), testLabel);
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter description here'),
          testDescription);
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Simulate tapping on the added marker to show event info
      await tester.tap(find.descendant(of: find.byType(FlutterMap),
          matching: find.widgetWithText(Container, 'Test Event')));
      await tester.pumpAndSettle();

      // Verify correct labels and descriptions are shown in the dialog
      expect(find.text(testLabel), findsNWidgets(2));
      expect(find.text(testDescription), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('Consecutive event registrations generate all markers', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      // Open event creation mode
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase,));

      // Repeat the logic to add three distinct markers
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Simulate map tap
        await tester.tap(find.byType(FlutterMap));
        await tester.pumpAndSettle();

        // Input label and description, vary each iteration
        await tester.enterText(
            find.widgetWithText(TextField, 'Enter event type here'),
            'Test Event $i');
        await tester.enterText(
            find.widgetWithText(TextField, 'Enter description here'),
            'Test description $i');
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();
      }

      // Verify all markers are added
      for (var i = 0; i < 3; i++) {
        expect(find.descendant(of: find.byType(FlutterMap),
            matching: find.widgetWithText(Container, 'Test Event $i')),
            findsOneWidget);
      }
    });

    testWidgets('Event creation mode is disabled upon event creation', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      // Enable event creation mode
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase,));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Confirm event is being created
      expect(find.byIcon(Icons.cancel), findsOneWidget);

      // Submit event creation
      await tester.tap(find.byType(FlutterMap)); // Simulate map tap for dialog
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter event type here'),
          'City Parade');
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter description here'),
          'Annual city parade');
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Verify event creation mode is disabled
      expect(find.byIcon(Icons.add_location), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('Event creation mode is disabled when user presses cancel', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      // Open event creation mode
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase,));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simulate map tap
      await tester.tap(find.byType(FlutterMap));
      await tester.pumpAndSettle();

      // Press cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify event creation mode is disabled
      expect(find.byIcon(Icons.add_location), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets(
        'Multiple toggles of event creation button does not add markers', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase,));

      // Toggle event creation on and off multiple times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.add_location));
        await tester.pumpAndSettle(); // Opens event creation mode
        expect(find.byIcon(Icons.cancel), findsOneWidget);

        await tester.tap(find.byIcon(Icons.cancel));
        await tester.pumpAndSettle(); // Closes event creation mode
        expect(find.byIcon(Icons.add_location), findsOneWidget);
      }
    });

    testWidgets('Consecutive cancellations does not add markers', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase,));

      // Press create event, then cancel consecutively without adding any marker
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.cancel));
        await tester.pumpAndSettle();
      }

      // Ensure no markers are added
      expect(find.descendant(of: find.byType(FlutterMap),
          matching: find.widgetWithText(Container, 'Test Event')),
          findsNothing);
    });
  });
  group('Settings Page', () {
    testWidgets('Settings page is exited correctly with back button', (WidgetTester tester) async {

      bool _backCalled = false;
      exampleCallBack(){
        _backCalled = true;
      }
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SettingsPage(returnToPreviousPage: exampleCallBack))));

      tester.tap(find.byWidget(const Text("Back")));
      expect(_backCalled, true);
    });
    testWidgets('Settings page saves current settings', (WidgetTester tester) async {
      bool _backCalled = false;
      exampleCallBack(){
        _backCalled = true;
      }
      await tester.pumpWidget(Scaffold(body: SettingsPage(returnToPreviousPage: exampleCallBack,)));

      Finder finder = find.byType(Checkbox);
      print(finder.allCandidates);
    });
  });
}
