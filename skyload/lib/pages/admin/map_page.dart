import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:skyload/utils/funciones.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<dynamic> usersList = [];
  bool isLoading = true;
  bool _mapReady = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await get_('/users');
      final List<dynamic> users = json.decode(response.body);
      setState(() {
        usersList = users;
        isLoading = false;
      });
      if (_mapReady) _fitAll();
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  double _parseCoord(dynamic value) => double.parse(value.toString());

  List<dynamic> get _usersWithLocation =>
      usersList.where((u) => u['lat'] != null && u['lon'] != null).toList();

  void _fitAll() {
    final located = _usersWithLocation;
    if (located.isEmpty) return;
    if (located.length == 1) {
      _mapController.move(
        LatLng(_parseCoord(located[0]['lat']), _parseCoord(located[0]['lon'])),
        13,
      );
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: located
            .map((u) => LatLng(_parseCoord(u['lat']), _parseCoord(u['lon'])))
            .toList(),
        padding: const EdgeInsets.fromLTRB(48, 80, 48, 140),
      ),
    );
  }

  void _centerOnUser(dynamic user) {
    _mapController.move(
      LatLng(_parseCoord(user['lat']), _parseCoord(user['lon'])),
      14,
    );
  }

  void _zoom(double delta) {
    _mapController.move(
      _mapController.camera.center,
      (_mapController.camera.zoom + delta).clamp(2.0, 19.0),
    );
  }

  void _showUserInfo(dynamic user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xff3B5BFE),
              child: Text(
                user['name'][0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "${user['name']} ${user['lastName']}",
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (user['unitNumber'] != null)
              _infoRow(Icons.tag, "Unit ${user['unitNumber']}"),
            if (user['vehicle'] != null)
              _infoRow(Icons.local_shipping_outlined, user['vehicle']),
            const SizedBox(height: 8),
            _infoRow(
              Icons.location_on_outlined,
              "${_parseCoord(user['lat']).toStringAsFixed(5)}, "
              "${_parseCoord(user['lon']).toStringAsFixed(5)}",
              small: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool small = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: small ? 13 : 16, color: Colors.grey[500]),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: small ? Colors.grey[400] : Colors.grey[600],
              fontSize: small ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final located = _usersWithLocation;
    final LatLng initialCenter = located.isNotEmpty
        ? LatLng(_parseCoord(located[0]['lat']), _parseCoord(located[0]['lon']))
        : const LatLng(4.7110, -74.0721);

    return Stack(
      children: [
        // ── MAP ──────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 10,
            onMapReady: () {
              _mapReady = true;
              _fitAll();
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.skyload.app',
            ),
            MarkerLayer(
              markers: located.map((user) {
                return Marker(
                  point: LatLng(
                      _parseCoord(user['lat']), _parseCoord(user['lon'])),
                  width: 44,
                  height: 52,
                  child: GestureDetector(
                    onTap: () => _showUserInfo(user),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xff3B5BFE),
                          child: Text(
                            user['name'][0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 13),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: Color(0xff3B5BFE), size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // ── RIGHT CONTROLS (zoom + refresh + fit all) ────────
        Positioned(
          top: 16,
          right: 14,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              children: [
                _mapButton(
                  icon: Icons.add,
                  tooltip: 'Zoom in',
                  onTap: () => _zoom(1),
                ),
                _divider(),
                _mapButton(
                  icon: Icons.remove,
                  tooltip: 'Zoom out',
                  onTap: () => _zoom(-1),
                ),
                _divider(),
                _mapButton(
                  icon: Icons.fit_screen_outlined,
                  tooltip: 'Fit all',
                  onTap: _fitAll,
                ),
                _divider(),
                _mapButton(
                  icon: Icons.refresh,
                  tooltip: 'Refresh',
                  onTap: _loadUsers,
                ),
              ],
            ),
          ),
        ),

        // ── BOTTOM USERS PANEL ───────────────────────────────
        if (located.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 12,
            right: 12,
            child: Container(
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                itemCount: located.length,
                itemBuilder: (_, i) {
                  final user = located[i];
                  return GestureDetector(
                    onTap: () => _centerOnUser(user),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xffF1F3F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xff3B5BFE),
                            child: Text(
                              user['name'][0].toUpperCase(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${user['name']} ${user['lastName']}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12),
                              ),
                              if (user['unitNumber'] != null)
                                Text(
                                  "# ${user['unitNumber']}",
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

        if (located.isEmpty)
          Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8)
                ],
              ),
              child: const Text(
                "No users with location available",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }

  Widget _mapButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: const Color(0xff3B5BFE)),
        ),
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 1,
        indent: 10,
        endIndent: 10,
        color: Colors.grey[100],
      );
}
