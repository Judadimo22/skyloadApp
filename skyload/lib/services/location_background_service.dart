import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

const _kUserId = 'bg_service_userId';
const _kBaseUrl = 'bg_service_baseUrl';

// ── Android background service callbacks (must be top-level) ─────────────────

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async => true;

@pragma('vm:entry-point')
void _onStart(ServiceInstance service) async {
  final prefs = await SharedPreferences.getInstance();

  service.on('stopService').listen((_) => service.stopSelf());

  service.on('setUser').listen((data) async {
    if (data == null) return;
    await prefs.setString(_kUserId, data['userId'] as String? ?? '');
    await prefs.setString(_kBaseUrl, data['baseUrl'] as String? ?? '');
  });

  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    ),
  ).listen(
    (Position position) async {
      final userId = prefs.getString(_kUserId) ?? '';
      final baseUrl = prefs.getString(_kBaseUrl) ?? '';
      if (userId.isEmpty || baseUrl.isEmpty) return;
      try {
        await http.put(
          Uri.parse('$baseUrl/updateLocation/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'lat': position.latitude,
            'lon': position.longitude,
            'speed': (position.speed < 0 ? 0 : position.speed) * 2.23694,
          }),
        );
      } catch (_) {}
    },
    onError: (_) {},
  );
}

// ── LocationManager singleton: Android → background service, iOS → stream ────

class LocationManager {
  LocationManager._();
  static final LocationManager instance = LocationManager._();

  StreamSubscription<Position>? _positionStream;
  Timer? _fallbackTimer;
  Position? _lastPosition;
  String? _userId;
  String? _baseUrl;

  /// Call once at app startup (main.dart).
  Future<void> init() async {
    await FlutterBackgroundService().configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'fleet_point_location',
        initialNotificationTitle: 'Fleet Point 360',
        initialNotificationContent: 'Tracking your location in the background.',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  Future<void> start({required String userId, required String baseUrl}) async {
    _userId = userId;
    _baseUrl = baseUrl;

    if (Platform.isAndroid) {
      await _startAndroid();
    } else {
      _startIos();
    }
  }

  Future<void> stop() async {
    if (Platform.isAndroid) {
      FlutterBackgroundService().invoke('stopService');
    } else {
      _positionStream?.cancel();
      _positionStream = null;
      _fallbackTimer?.cancel();
      _fallbackTimer = null;
    }
  }

  // ── Android ────────────────────────────────────────────────────────────────

  Future<void> _startAndroid() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, _userId!);
    await prefs.setString(_kBaseUrl, _baseUrl!);

    final service = FlutterBackgroundService();
    if (!await service.isRunning()) await service.startService();
    service.invoke('setUser', {'userId': _userId, 'baseUrl': _baseUrl});
  }

  // ── iOS ───────────────────────────────────────────────────────────────────
  // On iOS, geolocator with allowBackgroundLocationUpdates keeps the stream
  // alive while the app is backgrounded. Force-kill stops tracking — this is
  // an OS restriction that applies to ALL iOS apps.

  void _startIos() {
    if (_positionStream != null) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      ),
    ).listen(
      (Position position) {
        _lastPosition = position;
        _send(position.latitude, position.longitude, position.speed);
      },
      onError: (_) {
        _positionStream?.cancel();
        _positionStream = null;
        Future.delayed(const Duration(seconds: 5), _startIos);
      },
    );

    _fallbackTimer ??= Timer.periodic(const Duration(seconds: 20), (_) async {
      if (_lastPosition != null) {
        _send(_lastPosition!.latitude, _lastPosition!.longitude, _lastPosition!.speed);
      } else {
        try {
          final pos = await Geolocator.getLastKnownPosition();
          if (pos != null) _send(pos.latitude, pos.longitude, pos.speed);
        } catch (_) {}
      }
    });
  }

  Future<void> _send(double lat, double lon, double speed) async {
    final userId = _userId ?? '';
    final baseUrl = _baseUrl ?? '';
    if (userId.isEmpty || baseUrl.isEmpty) return;
    try {
      await http.put(
        Uri.parse('$baseUrl/updateLocation/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': lat,
          'lon': lon,
          'speed': (speed < 0 ? 0 : speed) * 2.23694,
        }),
      );
    } catch (_) {}
  }
}

// ── Public API ────────────────────────────────────────────────────────────────

Future<void> initLocationBackgroundService() =>
    LocationManager.instance.init();

Future<void> startLocationService({
  required String userId,
  required String baseUrl,
}) =>
    LocationManager.instance.start(userId: userId, baseUrl: baseUrl);

Future<void> stopLocationService() => LocationManager.instance.stop();
