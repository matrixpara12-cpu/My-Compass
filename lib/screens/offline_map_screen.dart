import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class OfflineMapScreen extends StatefulWidget {
  final Position? currentPosition;
  final bool isRedMode;

  const OfflineMapScreen({
    super.key,
    required this.currentPosition,
    required this.isRedMode,
  });

  @override
  State<OfflineMapScreen> createState() => _OfflineMapScreenState();
}

class _OfflineMapScreenState extends State<OfflineMapScreen> {
  final List<LatLng> _tracklog = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.currentPosition != null) {
      _tracklog.add(LatLng(
        widget.currentPosition!.latitude,
        widget.currentPosition!.longitude,
      ));
    }
    _startTracking();
  }

  void _startTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position pos) {
      if (!mounted) return;
      setState(() {
        _tracklog.add(LatLng(pos.latitude, pos.longitude));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isRedMode ? Colors.red : const Color(0xFF00FFC8);
    final initialCenter = widget.currentPosition != null
        ? LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude)
        : const LatLng(36.7538, 3.0588);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('الخريطة وتتبع الأثر', style: TextStyle(color: activeColor)),
        iconTheme: IconThemeData(color: activeColor),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: _tracklog,
                strokeWidth: 4.0,
                color: activeColor,
              ),
            ],
          ),
          if (widget.currentPosition != null)
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(
                    widget.currentPosition!.latitude,
                    widget.currentPosition!.longitude,
                  ),
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.my_location,
                    color: activeColor,
                    size: 30,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: Icon(Icons.center_focus_strong, color: activeColor),
        onPressed: () {
          if (widget.currentPosition != null) {
            _mapController.move(
              LatLng(widget.currentPosition!.latitude, widget.currentPosition!.longitude),
              16.0,
            );
          }
        },
      ),
    );
  }
}
