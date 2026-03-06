import 'package:flutter/material.dart';

class LoadsPage extends StatefulWidget {
  final String token;

  const LoadsPage({super.key, required this.token});

  @override
  State<LoadsPage> createState() => _LoadsPageState();
}

class _LoadsPageState extends State<LoadsPage> {

  String filtroSeleccionado = "activas";

  final List<Map<String, dynamic>> cargas = [
    {
      "nombre": "Carga de alimentos",
      "descripcion": "Alimentos refrigerados",
      "origen": "Bogotá",
      "destino": "Medellín",
      "valor": 1200000,
      "estado": "activas"
    },
    {
      "nombre": "Electrodomésticos",
      "descripcion": "Neveras y lavadoras",
      "origen": "Cali",
      "destino": "Barranquilla",
      "valor": 1800000,
      "estado": "activas"
    },
    {
      "nombre": "Material construcción",
      "descripcion": "Cemento y varillas",
      "origen": "Tunja",
      "destino": "Bogotá",
      "valor": 900000,
      "estado": "finalizadas"
    },
  ];

  @override
  Widget build(BuildContext context) {

    final cargasFiltradas =
        cargas.where((c) => c["estado"] == filtroSeleccionado).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Cargas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: CircleAvatar(
              child: Icon(Icons.person),
            ),
          )
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

                /// ACTIVAS
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        filtroSeleccionado = "activas";
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: filtroSeleccionado == "activas"
                            ? Colors.blue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          "Activas",
                          style: TextStyle(
                            color: filtroSeleccionado == "activas"
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                /// FINALIZADAS
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        filtroSeleccionado = "finalizadas";
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: filtroSeleccionado == "finalizadas"
                            ? Colors.blue
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          "Finalizadas",
                          style: TextStyle(
                            color: filtroSeleccionado == "finalizadas"
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

          /// LISTA DE CARGAS
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: cargasFiltradas.length,
              itemBuilder: (context, index) {

                final carga = cargasFiltradas[index];

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

                        Text(
                          carga["nombre"],
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 6),

                        Text(carga["descripcion"]),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 18),
                            const SizedBox(width: 5),
                            Text("Origen: ${carga["origen"]}")
                          ],
                        ),

                        Row(
                          children: [
                            const Icon(Icons.flag, size: 18),
                            const SizedBox(width: 5),
                            Text("Destino: ${carga["destino"]}")
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [

                            Text(
                              "\$${carga["valor"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),

                            if (carga["estado"] == "activas")
                              ElevatedButton(
                                onPressed: () {},
                                child: const Text("Tomar carga"),
                              )
                          ],
                        )
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