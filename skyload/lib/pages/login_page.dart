import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyload/pages/admin/home_page_admin.dart';
import 'package:skyload/pages/loads_page.dart';
import 'package:skyload/utils/funciones.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  late SharedPreferences prefs;

  StreamSubscription<Position>? positionStream;

  bool _obscurePassword = true;
  bool isLoading = false;
  bool _isAdminMode = false;

  @override
  void initState() {
    super.initState();
    initSharedPref();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  /// PERMISOS DE UBICACIÓN
  Future<bool> requestLocationPermissions() async {

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      mostrarAlerta(
        context,
        "Location disabled",
        "Please enable location services",
        AlertType.none,
        () { Navigator.pop(context); },
        false,
        () {},
        "OK"
      );
      return false;
    }

    PermissionStatus permission = await Permission.location.request();

    if (permission.isDenied) {
      mostrarAlerta(
        context,
        "Permission required",
        "Location permission is required for tracking loads",
        AlertType.none,
        () { Navigator.pop(context); },
        false,
        () {},
        "OK"
      );
      return false;
    }

    PermissionStatus backgroundPermission = await Permission.locationAlways.request();

    if (backgroundPermission.isDenied) {
      mostrarAlerta(
        context,
        "Background location",
        "Background location is required to track deliveries",
        AlertType.none,
        () { Navigator.pop(context); },
        false,
        () {},
        "OK"
      );
      return false;
    }

    return true;
  }

  /// PERMISOS DE NOTIFICACIONES + TOKEN
  Future<String?> requestNotificationPermissionsAndToken() async {

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print("Permiso de notificaciones denegado");
      return null;
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional) {

      String? token = await messaging.getToken();
      return token;
    }

    return null;
  }

  /// LOGIN
  void loginUser() async {
    AlertaLoading.show(context);
    String? fcmToken = await requestNotificationPermissionsAndToken();

    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      var reqBody = {
        "email": emailController.text,
        "password": passwordController.text,
        "fcmToken": fcmToken
      };
      var response = await http.post(
        Uri.parse('${backendBaseUrl}/loginUser'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status']) {
        setState(() {
          emailController.text = "";
          passwordController.text = "";
        });
        var myToken = jsonResponse['token'];
        prefs.setString('token', myToken);
        Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(myToken);
        prefs.setString('correoUsuario', jwtDecodedToken['email']);
        bool permissionGranted = await requestLocationPermissions();
        if (!permissionGranted) {
          AlertaLoading.hide();
          return;
        }
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          await sendLocationToBackend(
            position.latitude,
            position.longitude,
            jwtDecodedToken['_id'],
          );
        } catch (e) {
          print("Error obteniendo ubicación: $e");
        }
        AlertaLoading.hide();
        Navigator.push(context, MaterialPageRoute(builder: (context) => LoadsPage(token: myToken)));

      } else {
        AlertaLoading.hide();
        mostrarAlerta(context, "Error en el inicio de sesión", "Please check your email and password and try again", AlertType.none,() {Navigator.of(context).pop();},false,() {Navigator.of(context).pop();},'Accept');
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> sendLocationToBackend(double lat, double lon, String userId) async {
    try {
      await put_(
        '/updateLocation/$userId',
        {
          "lat": lat,
          "lon": lon
        },
      );
    } catch (e) {
      print("Error sending location: $e");
    }
  }

  void loginAdmin() async {
    AlertaLoading.show(context);
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      var reqBody = {
        "email": emailController.text,
        "password": passwordController.text,
      };
      var response = await http.post(
        Uri.parse('${backendBaseUrl}/loginAdmin'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reqBody),
      );
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status']) {
        setState(() {
          emailController.text = "";
          passwordController.text = "";
        });
        var myToken = jsonResponse['token'];
        prefs.setString('token', myToken);
        Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(myToken);
        prefs.setString('correoUsuario', jwtDecodedToken['email']);
        AlertaLoading.hide();
        Navigator.push(context, MaterialPageRoute(builder: (context) => HomePageAdmin(token: myToken))
        );

      } else {
        AlertaLoading.hide();
        mostrarAlerta(
          context,
          "Error en el inicio de sesión",
          "Please check your email and password and try again",
          AlertType.none,
          () {
            Navigator.of(context).pop();
          },
          false,
          () {
            Navigator.of(context).pop();
          },
          'Accept'
        );
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF2563EB),
              Color(0xFF3B82F6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Image.asset("assets/logo.png", width: 140),
                const SizedBox(height: 20),
                const Text(
                  "Welcome back",
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Sign in to continue",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Login",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Sign in as",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAdminMode = false),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: !_isAdminMode ? const Color(0xFF2563EB) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 18,
                                      color: !_isAdminMode  ? Colors.white : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "User",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: !_isAdminMode ? Colors.white : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isAdminMode = true),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _isAdminMode ? const Color(0xFF1E3A8A) : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.shield_outlined,
                                      size: 18,
                                      color: _isAdminMode ? Colors.white : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Admin",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _isAdminMode ? Colors.white : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (_isAdminMode)
                      AnimatedOpacity(
                        opacity: _isAdminMode ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, 
                            vertical: 10
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFBFDBFE),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16, 
                                color: Color(0xFF1D4ED8)
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Admin access requires authorized credentials",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Text(
                        "Email",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.email_outlined),
                            hintText: "Enter your email",
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Password",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            hintText: "Enter your password",
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                              mostrarAlerta(
                                context,
                                'Complete the fields',
                                'Please enter email and password',
                                AlertType.none,
                                () { Navigator.pop(context); },
                                false,
                                () {},
                                'Accept',
                              );
                            } else {
                              _isAdminMode ? loginAdmin() : loginUser();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isAdminMode ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 6,
                          ),
                          child: const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}