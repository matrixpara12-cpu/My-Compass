import 'package:flutter/material.dart';
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
      title: 'My Compass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const CompassHomeScreen(),
    );
  }
}

class CompassHomeScreen extends StatefulWidget {
  const CompassHomeScreen({super.key});

  @override
  State<CompassHomeScreen> createState() => _CompassHomeScreenState();
}

class _CompassHomeScreenState extends State<CompassHomeScreen> {
  final SosService _sosService = SosService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Compass'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.explore,
              size: 100,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'Tactical Offline Compass',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () async {
                if (_sosService.isRunning) {
                  await _sosService.stopSos();
                } else {
                  _sosService.startSos();
                }
                setState(() {});
              },
              icon: Icon(_sosService.isRunning ? Icons.stop : Icons.flash_on),
              label: Text(_sosService.isRunning ? 'STOP SOS' : 'START SOS SIGNAL'),
            ),
          ],
        ),
      ),
    );
  }
}
