import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyload/utils/funciones.dart';
import 'package:skyload/widgets/buttons/boton_principal.dart';
import 'package:skyload/widgets/inputs/input_password.dart';
import 'package:skyload/widgets/inputs/input_principal.dart';
import 'package:skyload/widgets/texts/texto_manrope.dart';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:jwt_decoder/jwt_decoder.dart';


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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initSharedPref();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }
  
  void loginUser() async {
    AlertaCargando.show(context); 
    if (emailController.text.isNotEmpty && passwordController.text.isNotEmpty) {
      var reqBody = {
        "email": emailController.text,
        "password": passwordController.text,
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
        prefs.setString('correoUsuario', jwtDecodedToken['correo'] );
        prefs.setString('nombreUsuario', jwtDecodedToken['nombre'] );
        // Navigator.push(context,MaterialPageRoute(builder: (context) => DashBoard(token: myToken)));
        AlertaCargando.hide(); 
      } else {
        AlertaCargando.hide(); 
        mostrarAlerta(
          context,
          "Error en el inicio de sesión",
          "Por favor revisa el correo electrónico y la contraseña y vuelve a intentarlo.",
          AlertType.none,
          () {
            Navigator.of(context).pop();
          }, 
          false, 
          () {
            Navigator.of(context).pop();
          }, 
          'Aceptar'
        );
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  // Future<void> solicitarPermisoNotificaciones() async {
  //   NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
  //     alert: true,
  //     badge: true,
  //     sound: true
  //   );
  //   if(settings.authorizationStatus == AuthorizationStatus.denied) {
  //     print('Permiso de notificaciones denegado');
  //   }
  //   else if (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional) {
  //     print('Permiso de notificaciones concedido');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          padding: EdgeInsets.only(
            left: MediaQuery.of(context).size.width * 0.15,
            right: MediaQuery.of(context).size.width * 0.15 
          ),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF044B7F), 
                Color(0xFF107E7D),
                Color(0xFFD8E214)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextoManrope(
                  text: 'BIENVENIDO A',
                  fontSize: MediaQuery.of(context).size.width * 0.055,
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.12,
                    bottom: MediaQuery.of(context).size.height * 0.015,
                  ),
                  textColor: Colors.white,
                  fontWeight: FontWeight.bold,
                  alignment: Alignment.center,
                ),
                Center(
                  child: Container(
                    margin: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * 0.02,
                    ),
                    width: MediaQuery.of(context).size.width * 0.6,
                    child: Image.asset(
                      'assets/logo_white.png',
                    ),
                  ),
                ),
                TextoManrope(
                  text: 'Iniciar sesión',
                  fontSize: MediaQuery.of(context).size.width * 0.06,
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.03,
                  ),
                  textColor: Colors.white,
                  fontWeight: FontWeight.bold,
                  alignment: Alignment.centerLeft,
                ),
                Container(
                  margin: EdgeInsets.zero,
                  child: Row(
                    children: [
                      TextoManrope(
                        text: '¿No tienes una cuenta?',
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        margin: EdgeInsets.zero,
                        textColor: Colors.white,
                        fontWeight: FontWeight.w400,
                        alignment: Alignment.centerLeft,
                      ),
                    ],
                  ),
                ),
                TextoManrope(
                  text: 'Correo electrónico',
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.03,
                    bottom: MediaQuery.of(context).size.height * 0.005,
                  ),
                  textColor: Colors.white,
                  fontWeight: FontWeight.bold,
                  alignment: Alignment.centerLeft,
                ),
                InputPrincipal(
                  controller: emailController, 
                  keyboardType: TextInputType.text, 
                  margin: EdgeInsets.zero, 
                  textColor: Colors.grey[700], 
                  colorInput: Colors.white
                ),
                TextoManrope(
                  text: 'Contraseña',
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.02,
                    bottom: MediaQuery.of(context).size.height * 0.005,
                  ),
                  textColor: Colors.white,
                  fontWeight: FontWeight.bold,
                  alignment: Alignment.centerLeft,
                ),
                InputPassword(
                  controller: passwordController, 
                  keyboardType: TextInputType.text, 
                  margin: EdgeInsets.zero, 
                  textColor: Colors.grey[700] , 
                  colorInput: Colors.white
                ),
                Container(
                  margin: EdgeInsets.zero,
                  child: BotonPrincipal(
                    margin: EdgeInsets.zero,
                    buttonText: 'INGRESAR',
                    onPressed: () async {
                      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                        mostrarAlerta(context,'Diligencia los campos','Por favor diligencia los campos para poder ingresar',AlertType.none, () {Navigator.of(context).pop();}, false, () {}, 'Aceptar');
                      } else {
                        loginUser();
                      }
                    },
                    alignment: Alignment.center,
                    textColor: Colors.white,
                    fontSize: MediaQuery.of(context).size.height * 0.020,
                    fontWeight: FontWeight.bold,
                    backgroundColor: colorSecundario,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
