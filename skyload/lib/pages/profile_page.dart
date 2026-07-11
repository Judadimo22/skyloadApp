import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyload/pages/login_page.dart';
import 'package:skyload/utils/funciones.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

class ProfilePage extends StatefulWidget {
  final String token;
  const ProfilePage({super.key, required this.token});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final String _userId;
  late final String _email;
  late final String _name;
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    final jwt = JwtDecoder.decode(widget.token);
    _userId = jwt['_id'] ?? '';
    _email = jwt['email'] ?? '';
    final fn = (jwt['name'] ?? '').toString().trim();
    final ln = (jwt['lastName'] ?? '').toString().trim();
    _name = [fn, ln].where((s) => s.isNotEmpty).join(' ');
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _biometricAndDelete();
  }

  Future<void> _biometricAndDelete() async {
    try {
      final hasBiometrics = await _localAuth.canCheckBiometrics;

      if (hasBiometrics) {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to confirm account deletion',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (!authenticated || !mounted) return;
      }

      await _deleteAccount();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication error: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    AlertaLoading.show(context);
    try {
      await delete_('/user/$_userId');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _storage.deleteAll();
      AlertaLoading.hide();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      AlertaLoading.hide();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete account. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 36),
              _avatar(),
              const SizedBox(height: 12),
              if (_name.isNotEmpty) ...[
                Text(
                  _name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                _email,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              _infoCard(),
              const SizedBox(height: 40),
              _deleteButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    final initial = _name.isNotEmpty ? _name[0].toUpperCase() : '?';
    return Container(
      width: 84,
      height: 84,
      decoration: const BoxDecoration(
        color: colorPrincipal,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _infoRow(Icons.person_outline, 'Name', _name.isNotEmpty ? _name : '—'),
          const Divider(height: 1),
          _infoRow(Icons.email_outlined, 'Email', _email.isNotEmpty ? _email : '—'),
          const Divider(height: 1),
          _infoRow(Icons.badge_outlined, 'User ID', _userId.isNotEmpty ? _userId : '—'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorPrincipal, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _deleteButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _confirmDeleteAccount,
          icon: const Icon(Icons.delete_outline),
          label: const Text(
            'Delete Account',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
