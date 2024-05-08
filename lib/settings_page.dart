import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'user_settings.dart';

class SettingsPage extends StatefulWidget {
  final Function() returnToPreviousPage;
  const SettingsPage({super.key, required this.returnToPreviousPage});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  late Box _settingsBox;
  late bool _notificationState;
  late Map<String, bool> _activeNotifications;
  late String _screenName;
  late Future<void> _setUpDatabaseFuture;

  Future<void> _setUpDatabase() async {
    _settingsBox = await Hive.openBox<UserSettings>('user_settings');
    final UserSettings? settings = _settingsBox.get('user_settings');
    _notificationState = (settings != null) ? settings.getNotifications : true;
    _activeNotifications = (settings != null) ? settings.notificationTypes : {"Dangers": true}; // once we have a list of "notifications", it shouldn't be that bad
    _screenName = (settings != null) ? settings.screenName : "Stephen";
  }

  @override
  void initState(){
    super.initState();
    _setUpDatabaseFuture = _setUpDatabase();
  }

  @override
  Widget build(BuildContext context) {
    Widget toReturn = FutureBuilder(
      future: _setUpDatabaseFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting){
          return const Text("Loading...");
        }else if (snapshot.hasError) {
          return const Text("Issue reading settings on phone. Please try again.");
        }else{
          return SingleChildScrollView(
            child: ListView(
              shrinkWrap: true,
              children: [
                ElevatedButton(onPressed: widget.returnToPreviousPage,
                    child: const Text("Back")),
                ListTile(
                leading: Checkbox(
                  value: _notificationState,
                  onChanged: (newValue){
                    setState(() {
                      _notificationState = newValue!;
                    });
                  }
                ),
                title: const Text("Notifications")
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _activeNotifications.length,
                itemBuilder: (BuildContext context, int index){
                  final MapEntry<String, bool> entry = _activeNotifications.entries.elementAt(index);
                  final String notificationName = entry.key;
                  final bool isActive = entry.value;

                  return ListTile(
                    leading: Checkbox(
                      value: isActive,
                      onChanged: (newValue){
                        setState(() {
                          _activeNotifications[notificationName] = newValue!;
                        });
                      }
                    ),
                    title: Text(notificationName)
                  );
                }
              ),
              ListTile(
                title: const Text("Username"),
                subtitle: TextFormField(
                  initialValue: _screenName,
                  onChanged: (newValue){
                    setState((){
                      _screenName = newValue;
                    });
                  }
                )
              ),
              ElevatedButton(
                onPressed: (){
                  UserSettings putIn = UserSettings(_notificationState, _activeNotifications, _screenName);
                  _settingsBox.put('user_settings', putIn);
                  widget.returnToPreviousPage();
                },
                child: const Text("Submit")
              )
            ]
            )
          );
        }
      }
    );
    return toReturn;
  }

}

