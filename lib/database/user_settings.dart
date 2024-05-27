import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 0)
class UserSettings extends HiveObject{
  @HiveField(0)
  bool getNotifications;
  @HiveField(1)
  Map<String, bool> notificationTypes;
  @HiveField(2)
  String screenName;

  UserSettings(this.getNotifications, this.notificationTypes, this.screenName);
}
