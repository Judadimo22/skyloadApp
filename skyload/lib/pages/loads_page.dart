import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:skyload/pages/login_page.dart';
import 'package:skyload/pages/profile_page.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:skyload/utils/funciones.dart';
import 'package:intl/intl.dart';

class LoadsPage extends StatefulWidget {
  final String token;

  const LoadsPage({
    super.key,
    required this.token,
  });

  @override
  State<LoadsPage> createState() => _LoadsPageState();
}

class _LoadsPageState extends State<LoadsPage> {
  String filtroSeleccionado = "active";
  List<dynamic> loadList = [];
  late String userId;

  StreamSubscription<Position>? positionStream;
  Timer? _locationTimer;
  Position? _lastPosition;
  Timer? _statusPollTimer;

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    userId = jwtDecodedToken['_id'];
    getLoads(context);
    _statusPollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _pollLoads());
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocationTracking());
  }

  @override
  void dispose() {
    _statusPollTimer?.cancel();
    stopLocationTracking();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();

    // If permission was never granted (e.g. biometric login skipped login flow),
    // request whileInUse first before trying to upgrade to always.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      startLocationTracking();
      return;
    }

    // Show prominent disclosure before requesting "Allow all the time".
    if (permission == LocationPermission.whileInUse) {
      if (!mounted) return;
      final accepted = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text('Background Location Access'),
              content: const Text(
                'Fleet Point 360 needs to access your location at all times, '
                'even when the app is closed or running in the background.\n\n'
                'This is used to:\n'
                '• Show your real-time position to dispatchers.\n'
                '• Update your load status during the trip.\n\n'
                'On the next screen, select "Allow all the time" to enable '
                'continuous tracking.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Not now'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ) ??
          false;

      if (accepted) await Geolocator.requestPermission();
    }

    startLocationTracking();
  }

  void startLocationTracking() {
    if (positionStream != null) return;

    final LocationSettings locationSettings = Platform.isIOS
        ? AppleSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            activityType: ActivityType.automotiveNavigation,
            pauseLocationUpdatesAutomatically: false,
            allowBackgroundLocationUpdates: true,
            showBackgroundLocationIndicator: true,
          )
        : AndroidSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            intervalDuration: const Duration(seconds: 10),
            foregroundNotificationConfig: const ForegroundNotificationConfig(
              notificationTitle: 'Fleet Point 360',
              notificationText: 'Tracking your location in the background.',
              enableWakeLock: true,
            ),
          );

    positionStream = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen(
          (Position position) {
            _lastPosition = position;
            sendLocationToBackend(position.latitude, position.longitude, position.speed);
          },
          onError: (_) {
            // Stream error — restart after a short delay
            positionStream?.cancel();
            positionStream = null;
            Future.delayed(const Duration(seconds: 5), startLocationTracking);
          },
        );

    // Fallback timer: send last known position every 20 s even without movement
    _locationTimer ??= Timer.periodic(const Duration(seconds: 20), (_) async {
      if (_lastPosition != null) {
        sendLocationToBackend(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          _lastPosition!.speed,
        );
      } else {
        try {
          final pos = await Geolocator.getLastKnownPosition();
          if (pos != null) {
            sendLocationToBackend(pos.latitude, pos.longitude, pos.speed);
          }
        } catch (_) {}
      }
    });
  }

  Future<void> getLoads(BuildContext context) async {
    try {
      final response = await get_('/loads/$userId');
      List<dynamic> loads = json.decode(response.body);
      setState(() {
        loadList = loads;
      });
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<void> _pollLoads() async {
    if (!mounted) return;
    try {
      final response = await get_('/loads/$userId');
      if (!mounted) return;
      final List<dynamic> loads = json.decode(response.body);
      if (loads.toString() != loadList.toString()) {
        setState(() {
          loadList = loads;
        });
      }
    } catch (_) {}
  }

  Future<void> sendLocationToBackend(double lat, double lon, double speed) async {
    try {
      await put_(
        '/updateLocation/$userId',
        {
          "lat": lat,
          "lon": lon,
          "speed": (speed < 0 ? 0 : speed) * 2.23694
        },
      );
    } catch (e) {
      print("Error sending location: $e");
    }
  }

  void updateLoad(loadId) async {
    AlertaLoading.show(context);
    try {
      await put(
        context,
        '/updateLoad/$loadId',
        {},
        'The upload has been successfully updated',
        () async {
          Navigator.pop(context);
          await getLoads(context);

        },
        () {
          Navigator.of(context).pop();
        },
      );
      AlertaLoading.hide();

    } catch (e) {
      AlertaLoading.hide();
      print('Error: $e');
    }
  }

  void revertLoad(loadId) async {
    AlertaLoading.show(context);
    try {
      await put(
        context,
        '/revertLoad/$loadId',
        {},
        'The load has been successfully reverted',
        () async {
          Navigator.pop(context);
          await getLoads(context);
        },
        () {
          Navigator.of(context).pop();
        },
      );
      AlertaLoading.hide();
    } catch (e) {
      AlertaLoading.hide();
      print('Error: $e');
    }
  }

  double getProgress(String state) {
    switch (state) {
      case "active": return 0.2;
      case "picked_up": return 0.4;
      case "on_the_way": return 0.6;
      case "delivered": return 0.8;
      case "completed": return 1.0;
      default: return 0.0;
    }
  }

  String getStateLabel(String state) {
    switch (state) {
      case "active": return "Active";
      case "picked_up": return "Picked up";
      case "on_the_way": return "On the way";
      case "delivered": return "Delivered";
      case "completed": return "Completed";
      default: return "";
    }
  }

  bool canRevert(String state) {
    return state != "active" && state != "completed";
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ignore: non_constant_identifier_names
    final LoadsFiltradas = loadList.where((c) {
      if (filtroSeleccionado == "active") {
        return c["state"] != "completed";
      } else {
        return c["state"] == "completed";
      }
    }).toList();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showExitConfirmation();
      },
      child: Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: _logout,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.logout, color: Colors.red, size: 18),
                            SizedBox(width: 6),
                            Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const Text(
                      "Loads",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfilePage(token: widget.token),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colorPrincipal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: colorPrincipal,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          filtroSeleccionado = "active";
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: filtroSeleccionado == "active"  ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "Active",
                            style: TextStyle(
                              color: filtroSeleccionado == "active" ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          filtroSeleccionado = "Completed";
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: filtroSeleccionado == "Completed" ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            "Completed",
                            style: TextStyle(
                              color: filtroSeleccionado == "Completed" ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _pollLoads(),
                child: LoadsFiltradas.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                          Icon(
                            filtroSeleccionado == "active"
                                ? Icons.local_shipping_outlined
                                : Icons.check_circle_outline,
                            size: 72,
                            color: Colors.grey[350],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            filtroSeleccionado == "active"
                                ? 'No active loads'
                                : 'No completed loads',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            filtroSeleccionado == "active"
                                ? 'You have no loads assigned at the moment.\nPull down to refresh.'
                                : 'No loads have been completed yet.\nPull down to refresh.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                          ),
                        ],
                      )
                    : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: LoadsFiltradas.length,
                itemBuilder: (context, index) {
                  final carga = LoadsFiltradas[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: empresa + rate
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  "",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withValues(alpha: 0.4),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.attach_money, color: Colors.white, size: 18),
                                    Text(
                                      NumberFormat("#,###").format(carga["rate"]),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
        
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 14),
        
                          // PICKUP
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.upload_rounded, size: 20, color: Colors.blue),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "PICKUP",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "${carga["cityPickUp"]} — ${carga["addressPickup"]}",
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 15, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat("MMM dd, yyyy — HH:mm").format(
                                        DateTime.parse(carga["datePickUp"]).toLocal()
                                      ),
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
        
                          const SizedBox(height: 14),
                          const Divider(height: 1, indent: 4, endIndent: 4),
                          const SizedBox(height: 14),
        
                          // DELIVERY
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.download_rounded, size: 20, color: Colors.orange),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "DELIVERY",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.location_on_outlined, size: 15, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "${carga["cityDelivery"]} — ${carga["addressDelivery"]}",
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 15, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat("MMM dd, yyyy — HH:mm").format(
                                        DateTime.parse(carga["dateDelivery"]).toLocal()
                                      ),
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
        
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
        
                          // Estado + progreso
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Status", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text(
                                getStateLabel(carga["state"]),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: getProgress(carga["state"]),
                            minHeight: 6,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ),
            )
          ],
        ),
      ),
      ),
    );
  }

  void stopLocationTracking() {
    positionStream?.cancel();
    positionStream = null;
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  void _showExitConfirmation() {
    mostrarAlerta(
      context,
      '',
      'Are you sure you want to exit the application?',
      AlertType.none,
      () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginPage()),
          (route) => false,
        );
      },
      true,
      () => Navigator.pop(context),
      'Accept',
    );
  }
}