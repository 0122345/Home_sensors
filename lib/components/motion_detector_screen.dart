import 'package:flutter/material.dart';
import 'package:homesensors/utils/motion_detector_func.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AccelerometerData {
  AccelerometerData(this.time, this.x, this.y, this.z);
  final DateTime time;
  final double x;
  final double y;
  final double z;
}

class MotionDetectorScreen extends StatefulWidget {
  final MotionDetector detector;

  const MotionDetectorScreen({super.key, required this.detector});
  @override
  _MotionDetectorScreenState createState() => _MotionDetectorScreenState();
}

class _MotionDetectorScreenState extends State<MotionDetectorScreen> with SingleTickerProviderStateMixin {
  List<AccelerometerData> chartData = [];
  late MotionDetector _detector;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _detector = Provider.of<MotionDetector>(context, listen: false);
    _detector.addListener(_updateChartData);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _detector.removeListener(_updateChartData);
    _animationController.dispose();
    super.dispose();
  }

  void _updateChartData() {
    setState(() {
      if (chartData.length >= 50) {
        chartData.removeAt(0);
      }
      chartData.add(AccelerometerData(
        DateTime.now(),
        _detector.accelerometerValues[0],
        _detector.accelerometerValues[1],
        _detector.accelerometerValues[2],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Motion Detector')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMotionStatusCard(),
                const SizedBox(height: 20),
                _buildChartCard(),
                const SizedBox(height: 20),
                _buildAccelerometerValuesCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMotionStatusCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AnimatedIcon(
              icon: AnimatedIcons.play_pause,
              progress: _animationController,
              size: 50,
              color: widget.detector.motionDetected ? Colors.red : Colors.green,
            ),
            const SizedBox(height: 10),
            Text(
              widget.detector.motionDetected ? 'Motion Detected!' : 'No Motion',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Accelerometer Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(),
                primaryYAxis: NumericAxis(minimum: -20, maximum: 20),
                legend: Legend(isVisible: true),
                series: <ChartSeries>[
                  LineSeries<AccelerometerData, DateTime>(
                    name: 'X',
                    dataSource: chartData,
                    xValueMapper: (AccelerometerData data, _) => data.time,
                    yValueMapper: (AccelerometerData data, _) => data.x,
                    color: Colors.red,
                  ),
                  LineSeries<AccelerometerData, DateTime>(
                    name: 'Y',
                    dataSource: chartData,
                    xValueMapper: (AccelerometerData data, _) => data.time,
                    yValueMapper: (AccelerometerData data, _) => data.y,
                    color: Colors.green,
                  ),
                  LineSeries<AccelerometerData, DateTime>(
                    name: 'Z',
                    dataSource: chartData,
                    xValueMapper: (AccelerometerData data, _) => data.time,
                    yValueMapper: (AccelerometerData data, _) => data.z,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccelerometerValuesCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Current Values', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              'X: ${widget.detector.accelerometerValues[0].toStringAsFixed(2)}\n'
              'Y: ${widget.detector.accelerometerValues[1].toStringAsFixed(2)}\n'
              'Z: ${widget.detector.accelerometerValues[2].toStringAsFixed(2)}\n',
              style: TextStyle(
                fontSize: 18,
                color: _getColorForAxis(widget.detector.accelerometerValues),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForAxis(List<double> accelerometerValues) {
    if (accelerometerValues[0].abs() > accelerometerValues[1].abs() && accelerometerValues[0].abs() > accelerometerValues[2].abs()) {
      return Colors.red;
    } else if (accelerometerValues[1].abs() > accelerometerValues[0].abs() && accelerometerValues[1].abs() > accelerometerValues[2].abs()) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }
}

