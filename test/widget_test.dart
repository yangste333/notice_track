import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:latlong2/latlong.dart';
import 'package:mockito/mockito.dart';
import 'package:notice_track/app.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:notice_track/background/background_location.dart';
import 'package:notice_track/background/geolocation_service.dart';
import 'package:notice_track/background/notification_service.dart';
import 'package:notice_track/database/firestore_service.dart';
import 'package:notice_track/settings_page.dart';
import 'package:notice_track/user_settings.dart';
import 'package:notice_track/widgets/map.dart';
import 'package:notice_track/yaml_readers/yaml_reader.dart';


class MockFirebaseService extends Mock implements FirestoreService{
  List<MarkerData> markers = [MarkerData(position: const LatLng(1.0, 2.0), label: 'Example', description: 'Example', category: 'Example 1', )];

  @override
  Stream<List<MarkerData>> pullMarkers() {

    return Stream.fromIterable([
      markers
    ]);
  }

  @override
  Future<void> pushMarker(LatLng position, String label, String description, String category){
    markers.add(MarkerData(position: position, label: label, description: description, category: category));
    return Future.value();
  }
}

class MockHiveDatabase extends Mock implements Box<UserSettings>{
  UserSettings settings = UserSettings(true, {}, "Example");

  @override
  Future<void> put(dynamic key, UserSettings value) async {
    settings = value;
  }

  @override
  UserSettings get(dynamic key, {UserSettings? defaultValue}){
    return settings;
  }
}

class MockYamlReader extends Mock implements YamlReader{
  List<dynamic> currentList;

  MockYamlReader({this.currentList = const ["Category 1"]});

  updateList(List<dynamic> list){
    currentList = list;
  }

  @override
  Future<void> initializeReader() async {
    // do nothing
  }

  @override
  List<dynamic> getCategories(){

    return [currentList];
  }
}


void main() {
  group('User Interface', () {
    testWidgets(
        'Event creation button toggles correctly', (WidgetTester tester) async {
      // Build app and trigger a frame

      MockFirebaseService mockFirebase = MockFirebaseService();
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));

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
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simulate map tap
      await tester.tap(find.byType(FlutterMap));
      await tester.pumpAndSettle();

      // Expect dialog to open with label and description field
      expect(find.text('Register Event'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('Marker gets added on map after event registration', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));

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
      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.tap(find.text("Category 1").last);
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Check if the marker is displayed
      expect(find.descendant(of: find.byType(FlutterMap), matching: find.widgetWithText(Container, 'Test Event')), findsOneWidget);

      // Check if text related to 'Test Event' exists and is visible on the marker
      expect(find.descendant(of: find.byType(FlutterMap),
          matching: find.widgetWithText(Container, 'Test Event')),
          findsOneWidget);
    });

    testWidgets('Pressing submit with empty fields should not add a marker', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));

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
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));

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
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Simulate map tap
      await tester.tap(find.byType(FlutterMap));
      await tester.pumpAndSettle();

      // Input the test event
      await tester.enterText(
          find.widgetWithText(TextField, 'Enter event type here'),
          'Test Event');
      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.tap(find.text("Category 1").last);
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
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader(currentList: ["Category", "Test", "Final"]);

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));

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
      await tester.tap(find.byType(DropdownMenu<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text("Final").last);

      await tester.enterText(
          find.widgetWithText(TextField, 'Enter description here'),
          testDescription);
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      List<List<MarkerData>> markers = await mockFirebase.pullMarkers().toList();

      expect(markers[0][1].category, "Final");
      expect(markers[0][1].description, testDescription);
      expect(markers[0][1].label, testLabel);

      // Verify correct labels and descriptions are shown in the dialog

    });

    testWidgets('Shows the widget information correctly', (WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      mockFirebase.markers = [MarkerData(position: const LatLng(40.7128, -74.0060),
          label: "Unique Label", description: "Unique description", category: "Category")];

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader));

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.location_on_sharp), findsOneWidget);

      await tester.tap(find.byIcon(Icons.location_on_sharp));
      await tester.pumpAndSettle();

      expect(find.text("Unique Label"), findsNWidgets(2));
      expect(find.text("Category"), findsOneWidget);
      expect(find.text("Unique description"), findsOneWidget);
    });

    testWidgets('Consecutive event registrations generate all markers', (
        WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));


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
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));

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
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));

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
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));


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
      MockHiveDatabase mockSettings = MockHiveDatabase();
      MockYamlReader mockReader = MockYamlReader();

      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockSettings, settingsReader: mockReader,));


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
    testWidgets('Settings page comes up when tapping settings button', (WidgetTester tester) async {
      MockFirebaseService mockFirebase = MockFirebaseService();
      MockHiveDatabase mockHiveDatabase = MockHiveDatabase();
      MockYamlReader mockYamlReader = MockYamlReader();
      await tester.pumpWidget(MyApp(firestoreService: mockFirebase, settingsBox: mockHiveDatabase, settingsReader: mockYamlReader,));

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.settings));

      await tester.pumpAndSettle();

      expect(find.byType(MapWidget), findsNothing);
      expect(find.byType(SettingsPage), findsOneWidget);

      await tester.tap(find.text("Back"));

      await tester.pumpAndSettle();

      expect(find.byType(MapWidget), findsOneWidget);
      expect(find.byType(SettingsPage), findsNothing);
    });
  });
  group('Settings Page', () {
    testWidgets('Settings page is exited correctly with back button', (WidgetTester tester) async {
      MockHiveDatabase settings = MockHiveDatabase();
      MockYamlReader reader = MockYamlReader();
      bool _backCalled = false;
      exampleCallBack(){
        _backCalled = true;
      }
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SettingsPage(
        returnToPreviousPage: exampleCallBack, settingsBox: settings,
        settingsReader: reader,
      ))));
      expect(find.text("Loading..."), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text("Back"), findsOneWidget);

      await tester.tap(find.text("Back"));
      expect(_backCalled, true);
    });
    testWidgets('Settings page saves settings for base notification and screen name changes', (WidgetTester tester) async {
      MockHiveDatabase settings = MockHiveDatabase();
      MockYamlReader reader = MockYamlReader(currentList: ["Test 1", "Test 2"]);
      bool _backCalled = false;
      exampleCallBack(){
        _backCalled = true;
      }
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SettingsPage(
        returnToPreviousPage: exampleCallBack, settingsBox: settings,
        settingsReader: reader,
      ))));

      await tester.pumpAndSettle();

      final tileFinder = find.widgetWithText(ListTile, "Notifications");
      expect(tileFinder, findsOneWidget);
      final checkboxFinder = find.descendant(of: tileFinder, matching: find.byType(Checkbox));
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);

      final textFinder = find.byType(TextFormField);
      expect(textFinder, findsOneWidget);
      await tester.enterText(textFinder, "OtherScreenName");

      await tester.tap(find.text("Submit"));
      expect(_backCalled, true);
      expect(settings.settings.getNotifications, false);
      expect(settings.settings.notificationTypes, {"Test 1": true, "Test 2": true});
      expect(settings.settings.screenName, "OtherScreenName");
    });
    testWidgets('Settings page saves settings for notification statuses', (WidgetTester tester) async {
      MockHiveDatabase settings = MockHiveDatabase();
      MockYamlReader reader = MockYamlReader(currentList: ["Test 1", "Test 2"]);
      bool _backCalled = false;
      exampleCallBack(){
        _backCalled = true;
      }
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: SettingsPage(
        returnToPreviousPage: exampleCallBack, settingsBox: settings,
        settingsReader: reader,
      ))));

      await tester.pumpAndSettle();

      final tileFinder = find.widgetWithText(ListTile, "Test 1");
      expect(tileFinder, findsOneWidget);
      final checkboxFinder = find.descendant(of: tileFinder, matching: find.byType(Checkbox));
      expect(checkboxFinder, findsOneWidget);
      await tester.tap(checkboxFinder);

      await tester.tap(find.text("Submit"));
      expect(_backCalled, true);
      expect(settings.settings.getNotifications, true);
      expect(settings.settings.notificationTypes, {"Test 1": false, "Test 2": true});
      expect(settings.settings.screenName, "Example");
    });
  });
  group("File Reading", () {
    test("Reads the notification_categories.yaml file properly", () async{
      YamlReader reader = YamlReader(filename: 'lib/assets/notification_categories.yaml');
      await reader.initializeReader();
      List<dynamic> getStuff = reader.getCategories();
      expect(getStuff[0], ["Dangers", "Events", "Nature", "Other"]);
    });
    test("Does not get file that does not exist", () async{
      YamlReader reader = YamlReader(filename: "doesnotexist");
      await reader.initializeReader();
      List<dynamic> getStuff = reader.getCategories();
      expect(getStuff, []);
    });
  });
  // notifications and geolocation probably need to be through an integration test
}
