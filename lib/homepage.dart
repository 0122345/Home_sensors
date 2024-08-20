import 'package:flutter/material.dart';
import 'package:homesensors/components/app_bar.dart';
import 'package:homesensors/components/light_sensor_screen.dart';
import 'package:homesensors/components/location_tracker.dart';
import 'package:homesensors/components/motion_detector_screen.dart';
import 'package:homesensors/utils/motion_detector_func.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:video_player/video_player.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/videos/working.mp4')
      ..initialize().then((_) {
        _controller.setLooping(true);
        _controller.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Change Theme',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.blue[300],
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text('Light theme'),
                leading: Radio(
                  value: AdaptiveThemeMode.light,
                  groupValue: AdaptiveTheme.of(context).mode,
                  onChanged: (AdaptiveThemeMode? mode) {
                    AdaptiveTheme.of(context).setThemeMode(mode!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Dark theme'),
                leading: Radio(
                  value: AdaptiveThemeMode.dark,
                  groupValue: AdaptiveTheme.of(context).mode,
                  onChanged: (AdaptiveThemeMode? mode) {
                    AdaptiveTheme.of(context).setThemeMode(mode!);
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('System theme'),
                leading: Radio(
                  value: AdaptiveThemeMode.system,
                  groupValue: AdaptiveTheme.of(context).mode,
                  onChanged: (AdaptiveThemeMode? mode) {
                    AdaptiveTheme.of(context).setThemeMode(mode!);
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBarNav(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            FloatingActionButton(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 10,
              shape: const CircleBorder(),
              mini: true,
              tooltip: 'Change the current theme',
              onPressed: () => _showThemeDialog(context),
              child: Icon(
                AdaptiveTheme.of(context).mode == AdaptiveThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.grey[900],
              child: ListTile(
                leading:
                    Icon(Icons.flash_on, color: Theme.of(context).primaryColor),
                title: const Text('84.8 kWh',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Electricity usage of this room',
                    style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Linked Sensors',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildDeviceCard('Motion Detector', 'android phone',
                      '2 m/s/s', _controller, context),
                  _buildDeviceCard('Location', 'Geo location', '1 user',
                      'assets/images/location.png', context),
                  _buildDeviceCard('Light', 'Working Room', '1',
                      'assets/images/lamp.png', context),
                  _buildDeviceCard('Google Nest', 'Working Room',
                      'blank for now', Icons.device_hub, context),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            IconButton(
                icon: const Icon(Icons.directions_walk),
                onPressed: () => _navigateToPage(context, 'Motion Detector')),
            IconButton(
              onPressed: () => _navigateToPage(context, 'Location'),
              icon: const Icon(Icons.location_searching_rounded),
            ),
            IconButton(
                onPressed: () => _navigateToPage(context, 'Light'),
                icon: const Icon(Icons.lightbulb_outline)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(String title, String location, String status,
      dynamic icon, BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToPage(context, title),
      child: Card(
        color: const Color.fromARGB(255, 44, 62, 63),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (icon is IconData)
                    Icon(
                      icon,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    )
                  else if (icon is String)
                    Center(
                      child: Image.asset(icon, width: 45, height: 47),
                    )
                  else if (icon is VideoPlayerController)
                    Center(
                      child: SizedBox(
                        width: 45,
                        height: 47,
                        child: AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                  Text(status,
                      style: TextStyle(color: Theme.of(context).primaryColor)),
                ],
              ),
              const Spacer(),
              Text(title,
                  style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold)),
              Text(location, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(BuildContext context, String title) {
    switch (title) {
      case 'Motion Detector':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MotionDetectorScreen(
              detector: MotionDetector(),
            ),
          ),
        );
        break;
      case 'Location':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LocationTracker(),
          ),
        );
        break;
      case 'Light':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LightSensorPage(),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
        break;
    }
  }
}
