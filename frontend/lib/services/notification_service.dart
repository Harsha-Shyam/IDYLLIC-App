import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleAlarms(String frequency) async {
    // In a real app we would use timezone and scheduled notifications, 
    // but for demo purposes we will trigger one loud notification quickly 
    // to show it works, then periodically.
    
    await requestPermissions();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'idyllic_urgent_reminders', 
            'Urgent Reminders',
            channelDescription: 'Loud notifications for medication and wellbeing',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            ticker: 'ticker'
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    // Trigger an immediate demo notification
    await flutterLocalNotificationsPlugin.show(
      0,
      'Wellbeing Reminder',
      'It is time to drink water and check your routines!',
      platformChannelSpecifics,
    );

    // Note: To truly schedule repeating alarms, we'd use zonedSchedule with flutter_timezone.
    // For this hackathon, we trigger the immediate alarm above.
  }
}
