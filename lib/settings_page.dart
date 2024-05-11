import 'package:flutter/material.dart';
import 'package:notice_track/yaml_readers/yaml_reader.dart';
import 'package:hive/hive.dart';
import 'user_settings.dart';

class SettingsPage extends StatefulWidget {
  final Box settingsBox;
  final YamlReader settingsReader;
  final Function() returnToPreviousPage;
  const SettingsPage({super.key, required this.returnToPreviousPage, required this.settingsBox, required this.settingsReader});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  late bool _notificationState;
  late Map<String, bool> _activeNotifications;
  late String _screenName;
  late Future<void> _setUpDatabaseFuture;

  Future<void> _setUpDatabase() async {
    final UserSettings? settings = widget.settingsBox.get('user_settings');
    _notificationState = (settings != null) ? settings.getNotifications : true;
    _activeNotifications = (settings != null) ? settings.notificationTypes : _createNotificationMap();
    if (widget.settingsReader.getCategories()[0].length != _activeNotifications.keys.length){
      _activeNotifications = _createNotificationMap();
    }
    _screenName = (settings != null) ? settings.screenName : "Stephen";
  }

  Map<String, bool> _createNotificationMap(){
    List notificationList = widget.settingsReader.getCategories();
    Map<String, bool> toReturn = {};
    for (String s in notificationList[0]){
      toReturn[s] = true;
    }
    return toReturn;
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
                  widget.settingsBox.put('user_settings', putIn);
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

