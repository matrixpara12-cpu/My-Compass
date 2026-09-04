import 'package:torch_light/torch_light.dart';

class SosService {
  bool _isSosRunning = false;

  bool get isRunning => _isSosRunning;

  Future<void> startSos() async {
    _isSosRunning = true;

    while (_isSosRunning) {
      await _flashSequence([200, 200, 200], 200);
      if (!_isSosRunning) break;
      await Future.delayed(const Duration(milliseconds: 600));

      await _flashSequence([600, 600, 600], 200);
      if (!_isSosRunning) break;
      await Future.delayed(const Duration(milliseconds: 600));

      await _flashSequence([200, 200, 200], 200);
      if (!_isSosRunning) break;

      await Future.delayed(const Duration(milliseconds: 2000));
    }
  }

  Future<void> stopSos() async {
    _isSosRunning = false;
    try {
      await TorchLight.disableTorch();
    } catch (_) {}
  }

  Future<void> _flashSequence(List<int> durations, int pauseBetween) async {
    for (int duration in durations) {
      if (!_isSosRunning) break;
      try {
        await TorchLight.enableTorch();
        await Future.delayed(Duration(milliseconds: duration));
        await TorchLight.disableTorch();
        await Future.delayed(Duration(milliseconds: pauseBetween));
      } catch (e) {
        _isSosRunning = false;
        break;
      }
    }
  }

  static String generateSosSmsText(double lat, double lon) {
    return "Emergency SOS! My location coordinates: Lat $lat, Lon $lon. Maps: https://maps.google.com/?q=$lat,$lon";
  }
}
