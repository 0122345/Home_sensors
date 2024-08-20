import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:math';

class LightSensorPage extends StatefulWidget {
  const LightSensorPage({Key? key}) : super(key: key);

  @override
  _LightSensorPageState createState() => _LightSensorPageState();
}

class _LightSensorPageState extends State<LightSensorPage>
    with SingleTickerProviderStateMixin {
  int _luxLevel = 0;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late AnimationController _animationController;
  bool _isDarkMode = false;
  Timer? _measurementTimer;
  CameraController? _cameraController;
  bool _isCameraAvailable = false;

  @override
  void initState() {
    super.initState();
    initNotifications();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras[0], ResolutionPreset.low);
        await _cameraController!.initialize();
        setState(() {
          _isCameraAvailable = true;
        });
        _startLightMeasurement();
      } else {
        throw Exception('No cameras available');
      }
    } catch (e) {
      print('Failed to initialize camera: $e');
      _startLightSimulation();
    }
  }

  void _startLightMeasurement() {
    _measurementTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final image = await _cameraController!.takePicture();
        final luxLevel = await _calculateLuxFromImage(image);
        onLightData(luxLevel);
      }
    });
  }

  Future<int> _calculateLuxFromImage(XFile image) async {
    // This is a placeholder implementation. In a real-world scenario,
    // you'd process the image to calculate an estimated lux value.
    return Random().nextInt(1500);
  }

  void _startLightSimulation() {
    _measurementTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final random = Random();
      int newLuxLevel = random.nextInt(1500);
      onLightData(newLuxLevel);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _measurementTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  void initNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void onLightData(int luxLevel) {
    setState(() {
      _luxLevel = luxLevel;
    });
    adjustSmartLights(luxLevel);
    notifyUserIfNeeded(luxLevel);
  }

  void adjustSmartLights(int luxLevel) {
    if (luxLevel < 50) {
      print('Turning on smart lights');
    } else if (luxLevel > 200) {
      print('Turning off smart lights');
    }
  }

  void notifyUserIfNeeded(int luxLevel) {
    if (luxLevel < 10) {
      showNotification(
          'Low Light', 'The room is too dark. Consider turning on lights.');
    } else if (luxLevel > 1000) {
      showNotification('Bright Light',
          'The room is very bright. Consider closing curtains.');
    }
  }

  Future<void> showNotification(String title, String body) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'light_sensor_channel',
      'Light Sensor Notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'light_sensor_notification',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isCameraAvailable ? 'Light Sensor' : 'Light Sensor Simulation'),
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isDarkMode
                ? [Colors.grey[900]!, Colors.grey[800]!]
                : [Colors.blue[100]!, Colors.blue[50]!],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.lightbulb,
                  size: 64,
                  color: _isDarkMode ? Colors.yellow : Colors.orange,
                ),
                const SizedBox(height: 20),
                Text(
                  _isCameraAvailable
                      ? 'Using Camera'
                      : 'Simulating Light Levels',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Text(
                    '$_luxLevel lux',
                    key: ValueKey<int>(_luxLevel),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildLightIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLightIndicator() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: _luxLevel.toDouble()),
      duration: const Duration(milliseconds: 500),
      builder: (context, double value, child) {
        return Column(
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CustomPaint(
                painter: LightLevelPainter(
                  level: value,
                  isDarkMode: _isDarkMode,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _getLightLabel(),
              style: TextStyle(
                fontSize: 20,
                color: _isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ],
        );
      },
    );
  }

  String _getLightLabel() {
    if (_luxLevel < 50) return 'Dark';
    if (_luxLevel < 200) return 'Normal';
    return 'Bright';
  }
}

class LightLevelPainter extends CustomPainter {
  final double level;
  final bool isDarkMode;

  LightLevelPainter({required this.level, required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = isDarkMode ? Colors.grey[700]! : Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;

    final fgPaint = Paint()
      ..color = isDarkMode ? Colors.yellow : Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final sweepAngle = (level / 1500) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      fgPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${level.toInt()} lux',
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
