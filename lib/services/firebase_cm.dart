import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:companio/api/access_token.dart';

Future<void> handleBg(RemoteMessage message) async {
  print('Incoming message: $message');
}

class FirebaseCM {
  final firebaseMessaging = FirebaseMessaging.instance;

  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'notification',
    'notification',
    importance: Importance.max,
    playSound: true,
    showBadge: true,
  );

  final localNotification = FlutterLocalNotificationsPlugin();

  Future<void> iniNotification() async {
    NotificationSettings settings = await firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('User has denied permissions');
    }
    final fcmToken = await firebaseMessaging.getToken();
    print('FCM TOKEN: $fcmToken');

    FirebaseMessaging.onBackgroundMessage(handleBg);
    initPushNotification();
    initLocalNotification();
  }

  Future<void> initLocalNotification() async {
    var androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    var platformDetails = NotificationDetails(android: androidDetails);

    await localNotification.initialize(
      InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  Future<void> initPushNotification() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.instance.getInitialMessage().then(function);
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
    FirebaseMessaging.onMessage.listen(handleForegroundMessage);
  }

  FutureOr function(RemoteMessage? value) {
    print(value);
  }

  void handleMessage(RemoteMessage message) {
    print('App opened from background with message: $message');
  }

  void handleForegroundMessage(RemoteMessage message) async {
    print('Message received in foreground: ${message.notification?.title}');

    // Extract sender name from the message data
    String senderName = message.data['senderName'] ?? message.notification?.title ?? "Unknown Sender";

    // Show local notification when app is in the foreground
    _showLocalNotification(message, senderName);
  }

  Future<void> _showLocalNotification(RemoteMessage message, String senderName) async {
    var androidDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );
    var platformDetails = NotificationDetails(android: androidDetails);

    await localNotification.show(
      0,
      'Message from $senderName',  // Display sender's name in the notification title
      message.notification?.body,  // The message content
      platformDetails,
    );
  }

  void subscribeToTopic() {
    FirebaseMessaging.instance.subscribeToTopic('notification');
  }

  static Future<void> sendTokenNotification(
      String token, String title, String message, String senderName) async {
    try {
      final body = {
        'message': {
          'token': token,
          'notification': {
            'body': message,
            'title': 'Message from $senderName',
          },
          'data': {
            'senderName': senderName,
          },
        }
      };

      String url = 'https://fcm.googleapis.com/v1/projects/fir-auth-a9119/messages:send';

      String accessKey = await AccessToken().getAccessToken();

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessKey',  // Use the access token here
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully!');
      } else {
        print('Failed to send notification: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  static Future<bool> isTokenExpired(String token) async {
    // Placeholder function, implement token expiration check if needed
    return false;
  }
}
