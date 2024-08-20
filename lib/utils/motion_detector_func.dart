import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:io' show Platform;

class MockAccelerometer {
  Stream<AccelerometerEvent> get events {
    return Stream.periodic(const Duration(milliseconds: 100), (_) {
      return AccelerometerEvent(
          math.Random().nextDouble() * 2 - 1,
          math.Random().nextDouble() * 2 - 1,
          math.Random().nextDouble() * 2 - 1,
          DateTime.now());
    });
  }
}

class MotionDetector extends ChangeNotifier {
  List<double> _accelerometerValues = [0, 0, 0];
  bool _motionDetected = false;
  double _threshold = 1.5;
  DateTime _lastUpdate = DateTime.now();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  MotionDetector() {
    _initAccelerometer();
    _initNotifications();
  }

  void _initAccelerometer() {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        _accelerometerSubscription =
            accelerometerEvents.listen(_handleAccelerometerEvent);
      } else {
        // Use mock data on non-mobile platforms
        _accelerometerSubscription =
            MockAccelerometer().events.listen(_handleAccelerometerEvent);
      }
    } catch (e) {
      print("Error initializing accelerometer: $e");
    }
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    final now = DateTime.now();
    if (now.difference(_lastUpdate) > const Duration(milliseconds: 100)) {
      _lastUpdate = now;
      _accelerometerValues = [event.x, event.y, event.z];
      print("Accelerometer values: $_accelerometerValues"); // Debug print
      _checkMotion();
      notifyListeners();
    }
  }

  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'motion_detector_channel',
        'Motion Detector Notifications',
        importance: Importance.max,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _initNotifications() async {
    if (Platform.isAndroid || Platform.isIOS) {
      var initializationSettingsAndroid =
          const AndroidInitializationSettings('@mipmap/ic_launcher');
      var initializationSettingsIOS = const DarwinInitializationSettings();
      var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      await _createNotificationChannel();
    } else {
      print("Notifications are not supported on this platform");
    }
  }

  void _checkMotion() {
      double magnitude =
          _accelerometerValues.map((v) => v * v).reduce((a, b) => a + b);
      if (magnitude > _threshold * _threshold) {
        _motionDetected = true;
        _sendNotification();
      } else {
        _motionDetected = false;
      }
 
  }

  Future<void> _sendNotification() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
          'motion_detector_channel',
          'Motion Detector Notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
        var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
        var platformChannelSpecifics = NotificationDetails(
          android: androidPlatformChannelSpecifics,
          iOS: iOSPlatformChannelSpecifics,
        );
        await flutterLocalNotificationsPlugin.show(
          0,
          'Motion Detected',
          'Significant motion has been detected!',
          platformChannelSpecifics,
        );
      } catch (e) {
        print("Error sending notification: $e");
      }
    } else {
      print("Motion detected! (Notification simulated on non-mobile platform)");
    }
  }

  List<double> get accelerometerValues => _accelerometerValues;
  bool get motionDetected => _motionDetected;

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    super.dispose();
  }
}
