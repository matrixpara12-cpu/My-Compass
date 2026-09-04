import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

void main() => runApp(const CompassApp());

class CompassApp extends StatelessWidget {
  const CompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.tealAccent,
      ),
      home: const CompassScreen(),
    );
  }
}

class CompassScreen extends StatefulWidget {
  const CompassScreen({super.key});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  double? _heading = 0;
  Position? _currentPosition;

  final TextEditingController _latController = TextEditingController(text: "36.7538");
  final TextEditingController _lngController = TextEditingController(text: "3.0588");

  double targetLat = 36.7538;
  double targetLng = 3.0588;

  @override
  void initState() {
    super.initState();
    _initLocationAndCompass();
  }

  void _initLocationAndCompass() async {
    await Geolocator.requestPermission();
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
    ).listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });

    FlutterCompass.events?.listen((event) {
      if (mounted) setState(() => _heading = event.heading);
    });
  }

  double _calculateBearing() {
    if (_currentPosition == null) return 0;
    
    double lat1 = _currentPosition!.latitude * pi / 180;
    double lon1 = _currentPosition!.longitude * pi / 180;
    double lat2 = targetLat * pi / 180;
    double lon2 = targetLng * pi / 180;

    double dLon = lon2 - lon1;
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    
    double bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  double _calculateDistance() {
    if (_currentPosition == null) return 0;
    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLat,
      targetLng,
    );
  }

  void _updateTarget() {
    setState(() {
      targetLat = double.tryParse(_latController.text) ?? targetLat;
      targetLng = double.tryParse(_lngController.text) ?? targetLng;
    });
    Navigator.pop(context);
  }

  void _showTargetDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          top: 20, left: 20, right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("تحديد إحداثيات الهدف", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: _latController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: "خط العرض (Latitude)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _lngController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: "خط الطول (Longitude)", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.tealAccent, foregroundColor: Colors.black),
              onPressed: _updateTarget,
              child: const Text("حفظ وتوجيه"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double bearing = _calculateBearing();
    double targetAngle = (bearing - (_heading ?? 0)) * (pi / 180);
    double distance = _calculateDistance();

    return Scaffold(
      appBar: AppBar(
        title: const Text('بوصلة التوجيه'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_location_alt, color: Colors.tealAccent),
            onPressed: _showTargetDialog,
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                Text(
                  distance > 1000 
                      ? '${(distance / 1000).toStringAsFixed(2)} كم' 
                      : '${distance.toStringAsFixed(0)} متر',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.tealAccent),
                ),
                const Text('المسافة المتبقية للهدف', style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    color: Colors.white.withOpacity(0.03),
                  ),
                ),
                Transform.rotate(
                  angle: targetAngle,
                  child: const Icon(
                    Icons.navigation,
                    size: 140,
                    color: Colors.tealAccent,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text('الهدف الحالي: $targetLat , $targetLng', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text('زاوية الاتجاه: ${bearing.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
