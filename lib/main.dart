import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import 'dart:math' as math;

import 'services/sos_service.dart';
import 'services/waypoint_service.dart';

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

  Waypoint? _savedWaypoint;
  double _distanceToWaypoint = 0;
  double _bearingToWaypoint = 0;

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

      _updateWaypointData();
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

    Geolocator.getPositionStream().listen((Position pos) {
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
      });
      _updateWaypointData();
    });
  }

  void _saveCurrentLocationAsWaypoint() {
    if (_currentPosition == null) return;
    setState(() {
      _savedWaypoint = Waypoint(
        name: "موقع الخيمة/السيارة",
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ النقطة المرجعية بنجاح!')),
    );
  }

  void _updateWaypointData() {
    if (_savedWaypoint != null && _currentPosition != null) {
      double dist = WaypointService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _savedWaypoint!.latitude,
        _savedWaypoint!.longitude,
      );

      double bear = WaypointService.calculateBearing(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _savedWaypoint!.latitude,
        _savedWaypoint!.longitude,
      );

      setState(() {
        _distanceToWaypoint = dist;
        _bearingToWaypoint = bear;
      });
    }
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

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        title: Text('My-Compass', style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_add, color: activeColor),
            tooltip: 'حفظ الموقع الحالي',
            onPressed: _saveCurrentLocationAsWaypoint,
          ),
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
                        // إبرة البوصلة الأساسية
                        Transform.rotate(
                          angle: ((_heading ?? 0) * (math.pi / 180) * -1),
                          child: Icon(
                            Icons.navigation,
                            size: 220,
                            color: activeColor,
                          ),
                        ),
                        // مؤشر النقطة المرجعية (سهم أصفر)
                        if (_savedWaypoint != null)
                          Transform.rotate(
                            angle: (((_heading ?? 0) - _bearingToWaypoint) * (math.pi / 180) * -1),
                            child: const Icon(
                              Icons.location_searching,
                              size: 140,
                              color: Colors.amber,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // شريط النقطة المرجعية المعتمد
            if (_savedWaypoint != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _savedWaypoint!.name,
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'المسافة: ${_distanceToWaypoint.toStringAsFixed(0)} متر',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // شريط الإحداثيات
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
