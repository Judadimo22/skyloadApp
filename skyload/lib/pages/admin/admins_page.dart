import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyload/pages/admin/home_page_admin.dart';
import 'package:skyload/utils/funciones.dart';


class AdminsPage extends StatefulWidget {
  final String token;
  const AdminsPage({
    super.key,
    required this.token,
  });

  @override
  AdminsPageState createState() => AdminsPageState();
}

class AdminsPageState extends State<AdminsPage> {
  late SharedPreferences prefs;

  bool isLoading = true;
  List<dynamic> adminsList = [];

  bool isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    initSharedPref();
    getAdmins();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  Future<void> getAdmins() async {
    try {
      final response = await get_('/admins');
      List<dynamic> admins = json.decode(response.body);

      setState(() {
        adminsList = admins;
        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);
    }
  }

  void deleteAdmin(adminId) async {
    AlertaLoading.show(context);
    try {
      await post(
        context,
        '/deleteAdmin/$adminId',
        {},
        'The admin has been successfully deleted',
        () async {
          Navigator.pop(context);
          await getAdmins();
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

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateAdmin() {
    final email = TextEditingController();
    final password = TextEditingController();
    final name = TextEditingController();
    final lastName = TextEditingController();

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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      AlertaLoading.show(context);
                      try {
                        await post(
                          context,
                          '/admin',
                          {
                            "name": name.text,
                            "lastName": lastName.text,
                            "email": email.text,
                            "password": password.text,
                          },
                          'The admin has created succesfull',
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
                      "Create Admin",
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
                "Admins",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateAdmin(),
                icon: const Icon(Icons.add),
                label: const Text("Create Admin"),
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
            itemCount: adminsList.length,
            itemBuilder: (context, index) {
              final user = adminsList[index];

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
                          icon: Icons.delete,
                          color: Colors.red,
                          onTap: () => deleteAdmin(user["_id"]),
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
      body: isLoading ? const Center(child: CircularProgressIndicator()) : adminsList.isEmpty ? const Center(child: Text("No users found")) : _usersList(),
    );
  }
}