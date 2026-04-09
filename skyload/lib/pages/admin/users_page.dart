import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyload/pages/admin/home_page_admin.dart';
import 'package:skyload/utils/funciones.dart';


class UsersPage extends StatefulWidget {
  final String token;
  const UsersPage({
    super.key,
    required this.token,
  });

  @override
  UsersPageState createState() => UsersPageState();
}

class UsersPageState extends State<UsersPage> {
  late SharedPreferences prefs;

  bool isLoading = true;
  List<dynamic> usersList = [];

  bool isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    initSharedPref();
    getUsers();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> getUsers() async {
    try {
      final response = await get_('/users');
      List<dynamic> users = json.decode(response.body);

      setState(() {
        usersList = users;
        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);
    }
  }

  

  /// 🔵 USER DETAIL POPUP
  void _showUserDetail(dynamic user) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xff3B5BFE),
                child: Text(
                  user['name'][0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                "${user['name']} ${user['lastName']}",
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(user['email'] ?? ""),
              Text('Vehicle: ${user['vehicle']}' ?? ""),
              Text('Vehicle dimensions: ${user['vehicleDimension']}' ?? ""),
              Text('Unit number: ${user['unitNumber']}' ?? ""),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCreateLoad(user['_id']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff3B5BFE),
                      ),
                      child: const Text(
                        "Assign Load",
                        style: TextStyle(
                          color: Colors.white
                        ),
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateUser() {
    final email = TextEditingController();
    final password = TextEditingController();
    final name = TextEditingController();
    final lastName = TextEditingController();

    final vehicle = TextEditingController();
    final vehicleDimension = TextEditingController();
    final unitNumber = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      onTap: (){
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.close
                      ),
                    ),
                  ),
                  const Text(
                    "Create Load",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle("User Info"),
                  _input(name, "Name"),
                  _input(lastName, "Last Name"),
                  _input(email, "Email"),
                  StatefulBuilder(
                    builder: (context, setStateModal) {
                      return _inputPassword(
                        password,
                        "Password",
                        isPasswordHidden,
                        () {
                          setStateModal(() {
                            isPasswordHidden = !isPasswordHidden;
                          });
                        },
                      );
                    },
                  ),
                  _input(vehicle, "Vehicle"),
                  _input(vehicleDimension, "Vehicle Dimension"),
                  _input(unitNumber, "Unit Number"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      AlertaLoading.show(context);
                      try {
                        await post(
                          context,
                          '/user',
                          {
                            "name": name.text,
                            "lastName": lastName.text,
                            "email": email.text,
                            "password": password.text,
                            "vehicle": vehicle.text,
                            "vehicleDimension": vehicleDimension.text,
                            "unitNumber": unitNumber.text,
                          },
                          'The user has created succesfull',
                          (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => HomePageAdmin(token: widget.token )));
                          },
                          (){Navigator.of(context).pop();}
                        );
                      } catch (e) {
                        print("Error creando usuario: $e");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff3B5BFE),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "Create User",
                      style: TextStyle(
                        color: Colors.white
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 🟣 CREATE LOAD FORM
  void _showCreateLoad(String userId) {
    final pickupCompany = TextEditingController();
    final pickupAddress = TextEditingController();
    final pickupCity = TextEditingController();
    final pickupNote = TextEditingController();

    final deliveryCompany = TextEditingController();
    final deliveryAddress = TextEditingController();
    final deliveryCity = TextEditingController();
    final deliveryNote = TextEditingController();

    final rateController = TextEditingController();

    DateTime? pickupDate;
    DateTime? deliveryDate;

    Future<void> pickDate(bool isPickup) async {
      DateTime now = DateTime.now();

      final date = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now,
        lastDate: DateTime(2100),
      );

      if (date == null) return;

      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time == null) return;

      final finalDate = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);

      if (isPickup) {
        pickupDate = finalDate;
      } else {
        deliveryDate = finalDate;
      }
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      onTap: (){
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.close
                      ),
                    ),
                  ),
                  const Text(
                    "Create Admin",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle("Pickup Info"),
                  _input(pickupCompany, "Company"),
                  _input(pickupAddress, "Address"),
                  _input(pickupCity, "City"),
                  _input(pickupNote, "Note"),
                  _dateButton("Pickup Date", pickupDate, () async {
                    await pickDate(true);
                    setStateDialog(() {});
                  }),
                  const SizedBox(height: 20),
                  _sectionTitle("Delivery Info"),
                  _input(deliveryCompany, "Company"),
                  _input(deliveryAddress, "Address"),
                  _input(deliveryCity, "City"),
                  _input(deliveryNote, "Note"),

                  _dateButton("Delivery Date", deliveryDate, () async {
                    await pickDate(false);
                    setStateDialog(() {});
                  }),

                  const SizedBox(height: 20),

                  /// RATE
                  _input(rateController, "Rate", isNumber: true),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      AlertaLoading.show(context);
                      try {
                        await post(
                          context,
                          '/asignLoad',
                          {
                            "datePickUp": pickupDate?.toIso8601String(),
                            "companyNamePickUp": pickupCompany.text,
                            "addressPickup": pickupAddress.text,
                            "cityPickUp": pickupCity.text,
                            "notePickUp": pickupNote.text,
                            "dateDelivery": deliveryDate?.toIso8601String(),
                            "companyDelivery": deliveryCompany.text,
                            "addressDelivery": deliveryAddress.text,
                            "cityDelivery": deliveryCity.text,
                            "noteDelivery": deliveryNote.text,
                            "user": userId,
                            "rate": rateController.text
                          },
                          'The load has created succesfull',
                          (){
                            Navigator.push(context, MaterialPageRoute(builder: (context) => HomePageAdmin(token: widget.token )));
                          },
                          (){Navigator.of(context).pop();}
                        );
                      } catch (e) {
                        print("Error creando carga: $e");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff3B5BFE),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      "Create Load",
                      style: TextStyle(
                        color: Colors.white
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// UI HELPERS
  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _input(TextEditingController controller, String hint, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xffF1F3F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _inputPassword(
    TextEditingController controller,
    String hint,
    bool isObscure,
    VoidCallback toggleVisibility,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xffF1F3F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isObscure ? Icons.visibility_off : Icons.visibility,
            ),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }

  Widget _dateButton(
      String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xffF1F3F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date == null
                ? label
                : DateFormat("yyyy-MM-dd HH:mm").format(date)),
            const Icon(Icons.calendar_today, size: 18)
          ],
        ),
      ),
    );
  }

  /// USERS LIST
  Widget _usersList() {
  return Container(
    child: Column(
      children: [

        /// 🔵 HEADER + BOTÓN CREAR USUARIO
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Users",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateUser(), // 👈 crea esta función
                icon: const Icon(Icons.add),
                label: const Text("Create User"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff3B5BFE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// 🔵 LISTA (IMPORTANTE: usar Expanded)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: usersList.length,
            itemBuilder: (context, index) {
              final user = usersList[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    /// 👤 AVATAR
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xff3B5BFE),
                      child: Text(
                        user['name'] != null
                            ? user['name'][0].toUpperCase()
                            : "U",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(width: 16),

                    /// 🧾 USER INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${user['name'] ?? ""} ${user['lastName'] ?? ""}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),

                    /// ⚡ ACTIONS
                    Row(
                      children: [
                        _actionButton(
                          icon: Icons.visibility_outlined,
                          color: Colors.grey[700]!,
                          onTap: () => _showUserDetail(user),
                        ),
                        const SizedBox(width: 8),
                        _actionButton(
                          icon: Icons.local_shipping_outlined,
                          color: const Color(0xff3B5BFE),
                          onTap: () => _showCreateLoad(user['_id']),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

Widget _actionButton({
  required IconData icon,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: isLoading ? const Center(child: CircularProgressIndicator()) : usersList.isEmpty ? const Center(child: Text("No users found")) : _usersList(),
    );
  }
}