import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyload/pages/admin/home_page_admin.dart';
import 'package:skyload/pages/loads_page.dart';
import 'package:skyload/pages/register_page.dart';
import 'package:skyload/utils/funciones.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();

  late SharedPreferences prefs;
  StreamSubscription<Position>? positionStream;

  bool _obscurePassword = true;
  bool _isAdminMode = false;

  // Session
  String? _savedEmail;
  String? _savedName;
  String? _savedToken;
  bool _savedIsAdmin = false;
  bool _hasSavedSession = false;
  bool _biometricsAvailable = false;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    prefs = await SharedPreferences.getInstance();

    final token = await _storage.read(key: 'saved_token');
    final email = await _storage.read(key: 'saved_email');
    final name  = await _storage.read(key: 'saved_name');
    final mode  = await _storage.read(key: 'saved_mode');

    bool sessionValid = false;
    if (token != null && email != null) {
      try {
        sessionValid = !JwtDecoder.isExpired(token);
      } catch (_) {}
    }

    if (sessionValid) {
      emailController.text = email!;
      final displayName = (name != null && name.isNotEmpty)
          ? name
          : email.split('@')[0];
      setState(() {
        _savedEmail    = email;
        _savedName     = displayName;
        _savedToken    = token;
        _savedIsAdmin  = mode == 'admin';
        _isAdminMode   = _savedIsAdmin;
        _hasSavedSession = true;
      });
    } else {
      await _clearStoredSession();
    }

    try {
      final canCheck    = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      setState(() => _biometricsAvailable = (canCheck || isSupported) && sessionValid);
    } catch (_) {}

    setState(() => _checkingSession = false);
  }

  Future<void> _clearStoredSession() async {
    await _storage.delete(key: 'saved_token');
    await _storage.delete(key: 'saved_email');
    await _storage.delete(key: 'saved_name');
    await _storage.delete(key: 'saved_mode');
  }

  void _clearSession() async {
    await _clearStoredSession();
    setState(() {
      _savedEmail      = null;
      _savedName       = null;
      _savedToken      = null;
      _savedIsAdmin    = false;
      _hasSavedSession = false;
      _biometricsAvailable = false;
      emailController.clear();
      passwordController.clear();
    });
  }

  String _extractName(Map<String, dynamic> response, Map<String, dynamic> jwt, String emailFallback) {
    // 1. Respuesta directa del endpoint
    final fn = (response['name'] ?? response['firstName'] ?? jwt['name'] ?? '').toString().trim();
    final ln = (response['lastName'] ?? jwt['lastName'] ?? '').toString().trim();
    final full = '$fn $ln'.trim();
    if (full.isNotEmpty) return full;

    // 2. Objeto anidado { user: { name, lastName } }
    final nested = response['user'];
    if (nested is Map) {
      final nfn = (nested['name'] ?? nested['firstName'] ?? '').toString().trim();
      final nln = (nested['lastName'] ?? '').toString().trim();
      final nfull = '$nfn $nln'.trim();
      if (nfull.isNotEmpty) return nfull;
    }

    return emailFallback.split('@')[0];
  }

  Future<void> _saveSession(String token, String email, String name, bool isAdmin) async {
    await _storage.write(key: 'saved_token', value: token);
    await _storage.write(key: 'saved_email', value: email);
    await _storage.write(key: 'saved_name',  value: name);
    await _storage.write(key: 'saved_mode',  value: isAdmin ? 'admin' : 'user');
  }

  Future<void> _biometricLogin() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sign in to your account',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!authenticated || !mounted) return;
      _navigateHome(_savedToken!, _savedIsAdmin);
    } on PlatformException catch (e) {
      if (!mounted) return;
      mostrarAlerta(
        context,
        '',
        'Biometric authentication is not available. ${e.message ?? ''}',
        AlertType.none,
        () => Navigator.pop(context),
        false,
        () {},
        'Accept',
      );
    }
  }

  void _navigateHome(String token, bool isAdmin) {
    if (isAdmin) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomePageAdmin(token: token)),
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoadsPage(token: token)),
        (route) => false,
      );
    }
  }

  // ── PERMISOS ──────────────────────────────────────────────────────────────

  Future<bool> requestLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    if (Platform.isAndroid && permission != LocationPermission.always) {
      await Geolocator.requestPermission();
    }
    return true;
  }

  Future<String?> requestNotificationPermissionsAndToken() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.denied) return null;
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      return await messaging.getToken();
    }
    return null;
  }

  // ── LOGIN ─────────────────────────────────────────────────────────────────

  void loginUser() async {
    AlertaLoading.show(context);
    final String? fcmToken = await requestNotificationPermissionsAndToken();
    final email = emailController.text;
    final password = passwordController.text;

    if (email.isNotEmpty && password.isNotEmpty) {
      final response = await http.post(
        Uri.parse('${backendBaseUrl}/loginUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'fcmToken': fcmToken}),
      );
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status']) {
        final myToken = jsonResponse['token'] as String;
        prefs.setString('token', myToken);
        final jwt = JwtDecoder.decode(myToken);
        prefs.setString('correoUsuario', jwt['email'] ?? '');

        final name = _extractName(jsonResponse, jwt, email);
        await _saveSession(myToken, jwt['email'] ?? email, name, false);

        final permissionGranted = await requestLocationPermissions();
        if (permissionGranted) {
          try {
            final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
            await put_('/updateLocation/${jwt['_id']}', {'lat': pos.latitude, 'lon': pos.longitude});
          } catch (_) {}
        }

        AlertaLoading.hide();
        if (mounted) _navigateHome(myToken, false);
      } else {
        AlertaLoading.hide();
        if (mounted) {
          mostrarAlerta(context, '', 'Please check your email and password and try again.',
              AlertType.none, () => Navigator.pop(context), false, () {}, 'Accept');
        }
      }
    }
  }

  void loginAdmin() async {
    AlertaLoading.show(context);
    final email = emailController.text;
    final password = passwordController.text;

    if (email.isNotEmpty && password.isNotEmpty) {
      final response = await http.post(
        Uri.parse('${backendBaseUrl}/loginAdmin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse['status']) {
        final myToken = jsonResponse['token'] as String;
        prefs.setString('token', myToken);
        final jwt = JwtDecoder.decode(myToken);
        prefs.setString('correoUsuario', jwt['email'] ?? '');

        final name = _extractName(jsonResponse, jwt, email);
        await _saveSession(myToken, jwt['email'] ?? email, name, true);

        AlertaLoading.hide();
        if (mounted) _navigateHome(myToken, true);
      } else {
        AlertaLoading.hide();
        if (mounted) {
          mostrarAlerta(context, '', 'Please check your email and password and try again.',
              AlertType.none, () => Navigator.pop(context), false, () {}, 'Accept');
        }
      }
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF3B82F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _checkingSession
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Image.asset('assets/logo.png', width: 140),
                const SizedBox(height: 20),
                const Text(
                  'Welcome back',
                  style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue',
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
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                      ),
                      const SizedBox(height: 20),

                      if (_hasSavedSession) ...[
                        // ── SESSION VIEW ──────────────────────────────────
                        _greetingSection(),
                        const SizedBox(height: 24),
                        _passwordField(),
                        const SizedBox(height: 24),
                        _continueButton(),
                        if (_biometricsAvailable) ...[
                          const SizedBox(height: 14),
                          _biometricButton(),
                        ],
                        const SizedBox(height: 16),
                        _changeUserLink(),
                      ] else ...[
                        // ── FULL FORM ─────────────────────────────────────
                        _modeSelector(),
                        const SizedBox(height: 20),
                        if (_isAdminMode) _adminBanner(),
                        _fieldLabel('Email'),
                        const SizedBox(height: 8),
                        _emailField(),
                        const SizedBox(height: 20),
                        _passwordLabel(),
                        const SizedBox(height: 8),
                        _passwordField(),
                        const SizedBox(height: 30),
                        _continueButton(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Create one',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
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

  // ── WIDGETS ───────────────────────────────────────────────────────────────

  Widget _greetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $_savedName!',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 4),
        Text(
          _savedEmail ?? '',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        _passwordLabel(),
      ],
    );
  }

  Widget _modeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sign in as', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _modeButton(label: 'User', icon: Icons.person_outline, selected: !_isAdminMode, onTap: () => setState(() => _isAdminMode = false))),
            const SizedBox(width: 10),
            Expanded(child: _modeButton(label: 'Admin', icon: Icons.shield_outlined, selected: _isAdminMode, onTap: () => setState(() => _isAdminMode = true))),
          ],
        ),
      ],
    );
  }

  Widget _modeButton({required String label, required IconData icon, required bool selected, required VoidCallback onTap}) {
    final color = label == 'Admin' ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _adminBanner() {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Color(0xFF1D4ED8)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Admin access requires authorized credentials',
                style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87));
  }

  Widget _passwordLabel() {
    return const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87));
  }

  Widget _emailField() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.email_outlined),
          hintText: 'Enter your email',
          contentPadding: EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
      child: TextField(
        controller: passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          hintText: 'Enter your password',
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _continueButton() {
    final color = _isAdminMode ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          final email = emailController.text;
          final password = passwordController.text;
          if (email.isEmpty || password.isEmpty) {
            mostrarAlerta(context, '', 'Please enter email and password.',
                AlertType.none, () => Navigator.pop(context), false, () {}, 'Accept');
          } else {
            _isAdminMode ? loginAdmin() : loginUser();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 6,
        ),
        child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _biometricButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _biometricLogin,
        icon: const Icon(Icons.fingerprint, size: 22),
        label: const Text('Sign in with biometrics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2563EB),
          side: const BorderSide(color: Color(0xFF2563EB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _changeUserLink() {
    return Center(
      child: GestureDetector(
        onTap: _clearSession,
        child: const Text(
          'Change user',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
