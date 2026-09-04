
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' as math;

import 'services/sos_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyCompassApp());
}

class MyCompassApp extends StatelessWidget {
  const MyCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My-Compass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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
  bool _isRedMode = false;
  Position? _currentPosition;
  double _magStrength = 0;
  bool _hasVibrator = false;

  final SosService _sosService = SosService();
  bool _isSosActive = false;

  @override
  void initState() {
    super.initState();
    _initCompass();
    _initSensors();
    _fetchLocation();
    _checkVibrator();
  }

  void _checkVibrator() async {
    bool? hasVib = await Vibration.hasVibrator();
    setState(() => _hasVibrator = hasVib ?? false);
  }

  void _initCompass() {
    FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      setState(() {
        _heading = event.heading;
      });

      if (_heading != null && (_heading!.abs() < 1 || _heading!.abs() > 359)) {
        if (_hasVibrator) {
          Vibration.vibrate(duration: 40);
        }
      }
    });
  }

  void _initSensors() {
    magnetometerEventStream().listen((MagnetometerEvent event) {
      if (!mounted) return;
      double strength = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      setState(() {
        _magStrength = strength;
      });
    });
  }

  Future<void> _fetchLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() => _currentPosition = pos);
  }

  void _toggleSos() async {
    if (_isSosActive) {
      await _sosService.stopSos();
      setState(() => _isSosActive = false);
    } else {
      setState(() => _isSosActive = true);
      _sosService.startSos();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = _isRedMode ? Colors.red : const Color(0xFF00FFC8);
    final Color bgColor = Colors.black;
    bool isMagInterference = _magStrength > 65 || (_magStrength < 25 && _magStrength > 0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('My-Compass', style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSosActive ? Icons.flash_on : Icons.flash_off, color: _isSosActive ? Colors.red : activeColor),
            tooltip: 'إشارة SOS للطوارئ',
            onPressed: _toggleSos,
          ),
          IconButton(
            icon: Icon(Icons.nights_stay, color: activeColor),
            tooltip: 'الوضع الأحمر الليلي',
            onPressed: () => setState(() => _isRedMode = !_isRedMode),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            if (isMagInterference)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: Colors.red.withOpacity(0.2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'تداخل مغناطيسي (${_magStrength.toStringAsFixed(1)} µT)',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_heading?.round() ?? 0}°',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: activeColor,
                      ),
                    ),
                    const SizedBox(height: 30),

                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.rotate(
                          angle: ((_heading ?? 0) * (math.pi / 180) * -1),
                          child: Icon(
                            Icons.navigation,
                            size: 220,
                            color: activeColor,
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: activeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: activeColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('خط العرض:', style: TextStyle(color: activeColor)),
                      Text(
                        _currentPosition != null ? _currentPosition!.latitude.toStringAsFixed(5) : 'جاري التحميل...',
                        style: TextStyle(color: activeColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('خط الطول:', style: TextStyle(color: activeColor)),
                      Text(
                        _currentPosition != null ? _currentPosition!.longitude.toStringAsFixed(5) : 'جاري التحميل...',
                        style: TextStyle(color: activeColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
