import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:latlong2/latlong.dart';
import 'package:geofence_service/geofence_service.dart';

class LocationTracker extends StatefulWidget {
  const LocationTracker({Key? key}) : super(key: key);

  @override
  _LocationTrackerState createState() => _LocationTrackerState();
}

class _LocationTrackerState extends State<LocationTracker> {
  late final GeofenceService _geofenceService;
  final List<Geofence> _geofenceList = _buildGeofences();
  final List<CircleMarker> _geofenceCircles = [];
  final MapController _mapController = MapController();
  LatLng _currentPosition = LatLng(30.1015482, -1.9559369);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeGeofenceService();
    _initGeofenceCircles();
    _checkLocationPermission();
  }

  void _initializeGeofenceService() {
    _geofenceService = GeofenceService.instance.setup(
      interval: 5000,
      accuracy: 100,
      loiteringDelayMs: 60000,
      statusChangeDelayMs: 10000,
      useActivityRecognition: true,
      allowMockLocations: false,
      printDevLog: true,
      geofenceRadiusSortType: GeofenceRadiusSortType.DESC,
    );
  }

  static List<Geofence> _buildGeofences() {
    return [
      Geofence(
        id: 'home',
        latitude: 30.1015482,
        longitude: -1.9559369,
        radius: [
          GeofenceRadius(id: 'radius1', length: 100),
          GeofenceRadius(id: 'radius2', length: 200),
          GeofenceRadius(id: 'radius3', length: 300),
        ],
      ),
      Geofence(
        id: 'work',
        latitude: 37.4219,
        longitude: -122.0840,
        radius: [
          GeofenceRadius(id: 'radius1', length: 100),
          GeofenceRadius(id: 'radius2', length: 200),
          GeofenceRadius(id: 'radius3', length: 300),
        ],
      ),
    ];
  }

  void _initGeofenceCircles() {
    _geofenceCircles.addAll(_geofenceList.map((geofence) {
      return CircleMarker(
        point: LatLng(geofence.latitude, geofence.longitude),
        color: Colors.blue.withOpacity(0.3),
        borderColor: Colors.blue,
        borderStrokeWidth: 2,
        radius: geofence.radius[0].length.toDouble(),
      );
    }).toList());
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    geolocator.LocationPermission permission;

    try {
      serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await geolocator.Geolocator.checkPermission();
      if (permission == geolocator.LocationPermission.denied) {
        permission = await geolocator.Geolocator.requestPermission();
        if (permission == geolocator.LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == geolocator.LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      await _startGeofenceService();
      await _updateCurrentLocation();
    } catch (e) {
      _showNotification(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentPosition, 15.0);
    } catch (e) {
      _showNotification('Failed to get current location: ${e.toString()}');
    }
  }

  Future<void> _startGeofenceService() async {
    _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);
    _geofenceService.addLocationChangeListener(_onLocationChanged);
    _geofenceService.addLocationServicesStatusChangeListener(
        _onLocationServicesStatusChanged);
    _geofenceService.addActivityChangeListener(_onActivityChanged);
    _geofenceService.addStreamErrorListener(_onError);

    try {
      await _geofenceService.start(_geofenceList);
    } catch (error) {
      _onError(error);
    }
  }

  Future<void> _onGeofenceStatusChanged(
      Geofence geofence,
      GeofenceRadius geofenceRadius,
      GeofenceStatus geofenceStatus,
      Location location) async {
    print('Geofence Status: $geofenceStatus for ${geofence.id}');
    if (geofenceStatus == GeofenceStatus.ENTER) {
      _showNotification('Entered ${geofence.id}');
    } else if (geofenceStatus == GeofenceStatus.EXIT) {
      _showNotification('Exited ${geofence.id}');
    }
  }

  void _onLocationChanged(Location location) {
    print('Location Changed: ${location.latitude}, ${location.longitude}');
    setState(() {
      _currentPosition = LatLng(location.latitude, location.longitude);
    });
    _mapController.move(_currentPosition, 15.0);
  }

  void _onLocationServicesStatusChanged(bool status) {
    print('Location Services Status Changed: $status');
    if (!status) {
      _showNotification('Location services are disabled');
    }
  }

  void _onActivityChanged(Activity prevActivity, Activity currActivity) {
    print('Activity Changed: ${currActivity.type}');
  }

  void _onError(dynamic error) {
    print('Error: $error');
    _showNotification('An error occurred: ${error.toString()}');
  }

  void _showNotification(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<String> _getAddressFromCoordinates(LatLng position) async {
    // Implement reverse geocoding here
    await Future.delayed(Duration(seconds: 1)); // Simulating network delay
    return "123 Main St, Kigali City, Rwanda";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Tracker'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildMapStack(),
    );
  }

  Widget _buildMapStack() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentPosition,
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            CircleLayer(circles: _geofenceCircles),
            MarkerLayer(
              markers: [
                Marker(
                  point: _currentPosition,
                  width: 80.0,
                  height: 80.0,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: _buildInfoCard(),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current Location',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Lat: ${_currentPosition.latitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Lon: ${_currentPosition.longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _getAddressFromCoordinates(_currentPosition),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                return Text(
                  snapshot.data ?? 'Address not available',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _mapController.move(_currentPosition, 15.0),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Center Map'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _geofenceService.stop();
    super.dispose();
  }
}
