
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:skyload/pages/login_page.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? nombreUsuario = prefs.getString('nombreUsuario');
  String? correoUsuario = prefs.getString('correoUsuario');
  runApp(MyApp(token: token, correoUsuario: correoUsuario, nombreUsuario: nombreUsuario,));
}

class MyApp extends StatelessWidget {
  final String? token;
  final String? nombreUsuario;
  final String? correoUsuario;

  const MyApp({
    required this.token,
    this.nombreUsuario,
    this.correoUsuario,
    Key? key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyLoad',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        primaryColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginPage(),
    );
  }
}
