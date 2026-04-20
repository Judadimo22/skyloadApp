import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:skyload/pages/admin/admins_page.dart';
import 'package:skyload/pages/admin/loads_admin_page.dart';
import 'package:skyload/pages/admin/map_page.dart';
import 'package:skyload/pages/admin/users_page.dart';
import 'package:skyload/pages/loads_page.dart';
import 'package:skyload/pages/login_page.dart';

class HomePageAdmin extends StatefulWidget {
  final String token;

  const HomePageAdmin({
    super.key,
    required this.token,
  });

  @override
  State<HomePageAdmin> createState() => _HomePageAdminState();
}

class _HomePageAdminState extends State<HomePageAdmin> {
  late String userId;
  late String adminRol;
  int selectedIndex = 0;

  final List<String> menuItems = [
    "Users",
    "Loads",
    "Map",
  ];

  final List<String> menuItemsSuperAdmin = [
    "Users",
    "Admins",
    "Loads",
    "Map",
  ];

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
    userId = jwtDecodedToken['_id'];
    adminRol = jwtDecodedToken['rol'];
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: SafeArea(
        child: Column(
          children: [
            /// 🔝 TOP BAR
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
                        color: Colors.red.withOpacity(0.1),
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
                    "Admin Panel",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            /// 🔘 NAVIGATION BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: List.generate(adminRol == 'superAdmin' ? menuItemsSuperAdmin.length : menuItems.length, (index) {
                  bool isSelected = selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xff3B5BFE)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                          ],
                        ),
                        
                        child: Center(
                          child: Text(
                            adminRol == 'superAdmin' ? menuItemsSuperAdmin[index] : menuItems[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: adminRol == 'superAdmin' ? _buildContentSuperAdmin() : _buildContent(),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// 🎯 CONTENT SWITCH
  Widget _buildContent() {
    switch (selectedIndex) {
      case 0: return UsersPage(token: widget.token);
      case 1: return LoadsAdminPage(token: widget.token);
      case 2: return const MapPage();
      default: return UsersPage(token: widget.token);
    }
  }

  Widget _buildContentSuperAdmin() {
    switch (selectedIndex) {
      case 0: return UsersPage(token: widget.token);
      case 1: return AdminsPage(token: widget.token);
      case 2: return LoadsAdminPage(token: widget.token);
      case 3: return const MapPage();
      default: return UsersPage(token: widget.token);
    }
  }




  Widget _placeholder(String title) {
    return Center(
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }


}