import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:skyload/utils/funciones.dart';

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

  @override
  void initState() {
    super.initState();

    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    userId = jwtDecodedToken['_id'];

    getLoads(context);
  }

  Future<void> getLoads(BuildContext context) async {
    try {
      final response = await get_('/loads/$userId');

      List<dynamic> loads = json.decode(response.body);
      print(loads);

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

  double getProgress(String state) {
    switch (state) {
      case "active":
        return 0.2;
      case "picked_up":
        return 0.4;
      case "on_the_way":
        return 0.6;
      case "delivered":
        return 0.8;
      case "completed":
        return 1.0;
      default:
        return 0.0;
    }
  }

  String getStateLabel(String state) {
    switch (state) {
      case "active":
        return "Active";
      case "picked_up":
        return "Picked up";
      case "on_the_way":
        return "On the way";
      case "delivered":
        return "Delivered";
      case "completed":
        return "Completed";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {

    final LoadsFiltradas = loadList.where((c) {
      if (filtroSeleccionado == "active") {
        return c["state"] != "completed";
      } else {
        return c["state"] == "completed";
      }
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 1,
  title: const Text(
    "Loads",
    style: TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
  ),
  centerTitle: false,
  iconTheme: const IconThemeData(color: Colors.black),

  actions: [

    /// NOTIFICATIONS
    Stack(
      children: [

        IconButton(
          icon: const Icon(Icons.notifications_none, size: 28),
          onPressed: () {
            print("Notifications");
          },
        ),

        Positioned(
          right: 10,
          top: 10,
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ),

      ],
    ),

    const SizedBox(width: 8),

    /// PROFILE
    Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          print("Open profile");
        },
        child: const CircleAvatar(
          radius: 18,
          backgroundColor: Colors.blue,
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    ),

  ],
),

      body: Column(
        children: [

          /// FILTRO
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [

                /// Active
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
                        color: filtroSeleccionado == "active"
                            ? Colors.blue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          "Active",
                          style: TextStyle(
                            color: filtroSeleccionado == "active"
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                /// Completed
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
                        color: filtroSeleccionado == "Completed"
                            ? Colors.blue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          "Completed",
                          style: TextStyle(
                            color: filtroSeleccionado == "Completed"
                                ? Colors.white
                                : Colors.black,
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

          /// LISTA DE Loads
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

                        /// EMPRESA ORIGEN
                        Text(
                          carga["companyNamePickUp"] ?? "",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        /// ORIGEN
                        Row(
                          children: [
                            const Icon(Icons.upload_rounded, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "${carga["cityPickUp"]} - ${carga["addressPickup"]}",
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 6),

                        /// DESTINO
                        Row(
                          children: [
                            const Icon(Icons.download_rounded, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "${carga["cityDelivery"]} - ${carga["addressDelivery"]}",
                              ),
                            )
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// FECHAS
                        Text(
                          "Pickup: ${carga["datePickUp"]}",
                          style: const TextStyle(fontSize: 13),
                        ),

                        Text(
                          "Delivery: ${carga["dateDelivery"]}",
                          style: const TextStyle(fontSize: 13),
                        ),

                        const SizedBox(height: 12),

                        /// BOTON
                        if (carga["state"] == "Active")
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {
                                print("Tomar carga");
                              },
                              child: const Text("Tomar carga"),
                            ),
                          ),
                        const SizedBox(height: 10),

                        /// PROGRESS BAR
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "State",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  getStateLabel(carga["state"]),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                )
                              ],
                            ),

                            const SizedBox(height: 6),

                            LinearProgressIndicator(
                              value: getProgress(carga["state"]),
                              minHeight: 6,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),

                          ],
                        ),
                        if (carga["state"] != "completed")
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              updateLoad(carga["_id"]);
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text("Update"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}