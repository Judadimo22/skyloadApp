import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:skyload/pages/login_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:skyload/services/notification_service.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.init();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      NotificationService.showNotification(
        message.notification!.title ?? "",
        message.notification!.body ?? "",
      );
    }
  });
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  String? nombreUsuario = prefs.getString('nombreUsuario');
  String? correoUsuario = prefs.getString('correoUsuario');
  runApp(
    MyApp(
      token: token,
      correoUsuario: correoUsuario,
      nombreUsuario: nombreUsuario,
    ),
  );
}


class MyApp extends StatefulWidget {

  final String? token;
  final String? nombreUsuario;
  final String? correoUsuario;

  const MyApp({
    required this.token,
    this.nombreUsuario,
    this.correoUsuario,
    super.key,
  });  

  @override
  State<MyApp> createState() => _MyAppState();
}



class _MyAppState extends State<MyApp> {

  @override
  void initState() {
    super.initState();
    initFirebaseMessaging();
  }

  /// Inicializar Firebase Messaging
  void initFirebaseMessaging() async {

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    /// Solicitar permisos (iOS / Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print("Permiso notificaciones: ${settings.authorizationStatus}");

    /// Obtener token del dispositivo
    String? token = await messaging.getToken();

    print("FCM TOKEN:");
    print(token);

    /// Escuchar cuando llega notificación con app abierta
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {

      print("Notificación recibida en FOREGROUND");

      if (message.notification != null) {

        print("TITLE: ${message.notification!.title}");
        print("BODY: ${message.notification!.body}");

      }

      print("DATA: ${message.data}");

    });

    /// Cuando el usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {

      print("Usuario abrió la notificación");

      print("DATA: ${message.data}");

      /// Aquí puedes navegar a una pantalla
      /// Navigator.push(...)

    });

    /// Cuando el token cambia
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {

      print("TOKEN ACTUALIZADO:");
      print(newToken);

      /// Aquí deberías enviarlo al backend
      /// updateFcmToken(newToken);

    });

  }



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkyLoad',
      debugShowCheckedModeBanner: true,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue, 
        ),
        primaryColor: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
      ),
      home: const LoginPage(),
    );

  }
}