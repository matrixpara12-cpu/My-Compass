import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyCompassApp());
}

class MyCompassApp extends StatelessWidget {
  const MyCompassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'بوصلة التوجيه',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4DB6AC),
          surface: Color(0xFF1E1E1E),
        ),
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
  final TextEditingController _singleInputController = TextEditingController(
    text: '34°38\'36.1"N 3°10\'24.3"E',
  );

  Position? _currentPosition;
  double? _targetLat = 34.643361;
  double? _targetLng = 3.173417;

  double _heading = 0;
  double _distanceKm = 0;
  double _bearing = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initLocationAndCompass();
    _parseAndSetCoordinates(_singleInputController.text);
  }

  void _initLocationAndCompass() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _errorMessage = 'يرجى تفعيل خدمة الموقع (GPS)');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _errorMessage = 'تم رفض الإذن للوصول للموقع');
        return;
      }
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position pos) {
      setState(() {
        _currentPosition = pos;
        _recalculate();
      });
    });

    FlutterCompass.events?.listen((CompassEvent event) {
      if (event.heading != null) {
        setState(() {
          _heading = event.heading!;
        });
      }
    });
  }

  void _parseAndSetCoordinates(String input) {
    try {
      final parsed = _parseCoordinates(input);
      if (parsed != null) {
        setState(() {
          _targetLat = parsed[0];
          _targetLng = parsed[1];
          _errorMessage = '';
          _recalculate();
        });
      } else {
        setState(() {
          _errorMessage = 'صيغة الإحداثيات غير صحيحة';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'تعذر تحليل الإحداثيات المدخلة';
      });
    }
  }

  List<double>? _parseCoordinates(String text) {
    String cleanText = text.trim();
    if (cleanText.isEmpty) return null;

    final dmsRegex = RegExp(
      r'(\d+)°\s*(\d+)[\x27\u2019\u2032]\s*([\d.]+)"?\s*([NSns])\s*[, ]*\s*(\d+)°\s*(\d+)[\x27\u2019\u2032]\s*([\d.]+)"?\s*([EWew])',
    );
    final match = dmsRegex.firstMatch(cleanText);

    if (match != null) {
      double latDeg = double.parse(match.group(1)!);
      double latMin = double.parse(match.group(2)!);
      double latSec = double.parse(match.group(3)!);
      String latDir = match.group(4)!.toUpperCase();

      double lngDeg = double.parse(match.group(5)!);
      double lngMin = double.parse(match.group(6)!);
      double lngSec = double.parse(match.group(7)!);
      String lngDir = match.group(8)!.toUpperCase();

      double lat = latDeg + (latMin / 60.0) + (latSec / 3600.0);
      if (latDir == 'S') lat = -lat;

      double lng = lngDeg + (lngMin / 60.0) + (lngSec / 3600.0);
      if (lngDir == 'W') lng = -lng;

      return [lat, lng];
    }

    final decRegex = RegExp(r'^\s*([+-]?\d+\.?\d*)\s*[, ]\s*([+-]?\d+\.?\d*)\s*$');
    final decMatch = decRegex.firstMatch(cleanText);
    if (decMatch != null) {
      double lat = double.parse(decMatch.group(1)!);
      double lng = double.parse(decMatch.group(2)!);
      return [lat, lng];
    }

    return null;
  }

  void _recalculate() {
    if (_currentPosition == null || _targetLat == null || _targetLng == null) return;

    double distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _targetLat!,
      _targetLng!,
    );

    _distanceKm = distanceInMeters / 1000.0;

    double startLat = _degreesToRadians(_currentPosition!.latitude);
    double startLng = _degreesToRadians(_currentPosition!.longitude);
    double endLat = _degreesToRadians(_targetLat!);
    double endLng = _degreesToRadians(_targetLng!);

    double dLng = endLng - startLng;
    double y = math.sin(dLng) * math.cos(endLat);
    double x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    double bearingRad = math.atan2(y, x);
    _bearing = (_radiansToDegrees(bearingRad) + 360) % 360;
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;
  double _radiansToDegrees(double radians) => radians * 180.0 / math.pi;

  @override
  Widget build(BuildContext context) {
    double arrowRotation = ((_bearing - _heading) + 360) % 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text('بوصلة التوجيه', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              _distanceKm.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4DB6AC),
              ),
            ),
            const Text(
              'كم',
              style: TextStyle(fontSize: 20, color: Color(0xFF4DB6AC)),
            ),
            const Text(
              'المسافة المتبقية للهدف',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),

            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.redAccent)),
              ),

            // البوصلة مع قرص التدرجات والأرقام
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // قرص الدرجات يدور مع اتجاه الهاتف
                      Transform.rotate(
                        angle: (-_heading * math.pi / 180),
                        child: CustomPaint(
                          size: const Size(280, 280),
                          painter: CompassDialPainter(),
                        ),
                      ),
                      // سهم الاتجاه نحو الهدف
                      Transform.rotate(
                        angle: (arrowRotation * math.pi / 180),
                        child: const Icon(
                          Icons.navigation,
                          size: 110,
                          color: Color(0xFF4DB6AC),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // إدخال الإحداثيات
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'تحديد إحداثيات الهدف',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _singleInputController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'مثال: 34°38\'36.1"N 3°10\'24.3"E',
                      hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                      filled: true,
                      fillColor: Colors.black26,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4DB6AC)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _parseAndSetCoordinates(_singleInputController.text);
                      FocusScope.of(context).unfocus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DB6AC),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'حفظ وتوجيه',
                      style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
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

// رسم تدرجات وأرقام قرص البوصلة
class CompassDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Offset center = Offset(radius, radius);

    final Paint circlePaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint tickPaint = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1.5;

    final Paint mainTickPaint = Paint()
      ..color = const Color(0xFF4DB6AC)
      ..strokeWidth = 3.0;

    canvas.drawCircle(center, radius - 4, circlePaint);

    for (int i = 0; i < 360; i += 5) {
      final double angle = i * math.pi / 180;
      final bool isMain = (i % 30 == 0);
      final double tickLength = isMain ? 12.0 : 6.0;

      final Offset start = Offset(
        center.dx + (radius - 10) * math.sin(angle),
        center.dy - (radius - 10) * math.cos(angle),
      );
      final Offset end = Offset(
        center.dx + (radius - 10 - tickLength) * math.sin(angle),
        center.dy - (radius - 10 - tickLength) * math.cos(angle),
      );

      canvas.drawLine(start, end, isMain ? mainTickPaint : tickPaint);

      if (i % 30 == 0) {
        String label = '$i';
        Color color = Colors.white70;

        if (i == 0) {
          label = 'N';
          color = Colors.redAccent;
        } else if (i == 90) {
          label = 'E';
        } else if (i == 180) {
          label = 'S';
        } else if (i == 270) {
          label = 'W';
        }

        final TextSpan span = TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: isMain && (i % 90 == 0) ? 14 : 10,
            fontWeight: FontWeight.bold,
          ),
        );

        final TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );

        tp.layout();

        final Offset textOffset = Offset(
          center.dx + (radius - 32) * math.sin(angle) - (tp.width / 2),
          center.dy - (radius - 32) * math.cos(angle) - (tp.height / 2),
        );

        tp.paint(canvas, textOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
