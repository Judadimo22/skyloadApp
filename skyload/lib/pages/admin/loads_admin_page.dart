import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:latlong2/latlong.dart';
import 'package:skyload/utils/funciones.dart';
import 'package:intl/intl.dart';

class LoadsAdminPage extends StatefulWidget {
  final String token;

  const LoadsAdminPage({
    super.key,
    required this.token,
  });

  @override
  State<LoadsAdminPage> createState() => _LoadsPageState();
}

class _LoadsPageState extends State<LoadsAdminPage> {
  String filtroSeleccionado = "active";
  List<dynamic> loadList = [];
  late String userId;
  String searchText = "";
  TextEditingController searchController = TextEditingController();

  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    userId = jwtDecodedToken['_id'];
    getLoads(context);
  }

  @override
  void dispose() {
    super.dispose();
  }



  Future<void> getLoads(BuildContext context) async {
    try {
      final response = await get_('/loads');
      List<dynamic> loads = json.decode(response.body);
      setState(() {
        loadList = loads;
      });


    } catch (error) {
      print('Error: $error');
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

  void cancelLoad(loadId) async {
    AlertaLoading.show(context);
    try {
      await put(
        context,
        '/cancelLoad/$loadId',
        {},
        'The load has been successfully cancelled',
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

  void deleteLoad(loadId) async {
    AlertaLoading.show(context);
    try {
      await put(
        context,
        '/deleteLoad/$loadId',
        {},
        'The load has been successfully deleted',
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
      case "cancelled" : return "Cancelled";
      default: return "";
    }
  }

  bool canRevert(String state) {
    return state != "active" && state != "completed";
  }

  List<String> estados = [
    "all",
    "active",
    "picked_up",
    "on_the_way",
    "delivered",
    "completed",
    "cancelled"
  ];

  @override
  Widget build(BuildContext context) {
    // ignore: non_constant_identifier_names
    final LoadsFiltradas = loadList.where((c) {
      final stateMatch = filtroSeleccionado == "all"
          ? true
          : c["state"] == filtroSeleccionado;

      final unitNumber = (c["user"]?["unitNumber"] ?? "")
          .toString()
          .toLowerCase();

      final searchMatch = unitNumber.contains(searchText);

      return stateMatch && searchMatch;
    }).toList();
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase();
                  });
                },
                decoration: const InputDecoration(
                  icon: Icon(Icons.search),
                  hintText: "Search by unit number...",
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: estados.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final estado = estados[index];
                  final isSelected = filtroSeleccionado == estado;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        filtroSeleccionado = estado;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? Colors.blue : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: Center(
                        child: Text(
                          estado == "all"
                              ? "All"
                              : getStateLabel(estado),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
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
                                  "${carga['user']['name']} ${carga['user']['lastName']} (${carga['user']['unitNumber'] ?? ''})",
                                  style: const TextStyle(
                                    fontSize: 16,
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
                                      color: Colors.green.withOpacity(0.4),
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
                                  color: Colors.blue.withOpacity(0.1),
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
                                  color: Colors.orange.withOpacity(0.1),
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
        
                          // Botones
                          if (carga["state"] != "cancelled")
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if(carga['state'] != 'completed')
                                if (canRevert(carga["state"]))
                                  OutlinedButton.icon(
                                    onPressed: () => revertLoad(carga["_id"]),
                                    icon: const Icon(Icons.arrow_back),
                                    label: const Text("Revert"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.orange,
                                      side: const BorderSide(color: Colors.orange),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => updateLoad(carga["_id"]),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text("Update"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                if(carga['state'] != 'cancelled')
                                  OutlinedButton.icon(
                                    onPressed: () => cancelLoad(carga["_id"]),
                                    icon: const Icon(Icons.cancel),
                                    label: const Text("Cancel"),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => deleteLoad(carga["_id"]),
                                  icon: const Icon(Icons.delete),
                                  label: const Text("Delete"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                    _buildMiniMap(carga['user']),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
  
  void stopLocationTracking() {
    positionStream?.cancel();
    positionStream = null;
  }

  double _parseCoord(dynamic value) => double.parse(value.toString());

  Widget _buildMiniMap(dynamic user) {
    final lat = user['lat'];
    final lon = user['lon'];
    if (lat == null || lon == null) return const SizedBox.shrink();
    return _MiniMapWidget(user: user);
  }
}

// ── Standalone minimap widget with its own MapController ──────────────────────
class _MiniMapWidget extends StatefulWidget {
  final dynamic user;
  const _MiniMapWidget({required this.user});

  @override
  State<_MiniMapWidget> createState() => _MiniMapWidgetState();
}

class _MiniMapWidgetState extends State<_MiniMapWidget> {
  final MapController _ctrl = MapController();

  double _parseCoord(dynamic v) => double.parse(v.toString());

  void _zoom(double delta) {
    _ctrl.move(
      _ctrl.camera.center,
      (_ctrl.camera.zoom + delta).clamp(2.0, 19.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(
      _parseCoord(widget.user['lat']),
      _parseCoord(widget.user['lon']),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: const [
            Icon(Icons.my_location, size: 15, color: Colors.blue),
            SizedBox(width: 6),
            Text(
              "DRIVER LOCATION",
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
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _ctrl,
                  options: MapOptions(
                    initialCenter: point,
                    initialZoom: 13,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom |
                          InteractiveFlag.drag |
                          InteractiveFlag.doubleTapZoom,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.skyload.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 44,
                          height: 52,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.blue,
                                child: Text(
                                  widget.user['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down,
                                  color: Colors.blue, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Zoom buttons
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _zoomBtn(Icons.add, () => _zoom(1)),
                        Container(
                            height: 1,
                            width: 28,
                            color: Colors.grey[200]),
                        _zoomBtn(Icons.remove, () => _zoom(-1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _zoomBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 36,
        height: 36,
        child: Icon(icon, size: 18, color: Colors.blue),
      ),
    );
  }
}