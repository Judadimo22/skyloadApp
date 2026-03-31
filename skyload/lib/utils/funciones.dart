import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skyload/widgets/texts/texto_manrope.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
const versionApp = "1.0.5+27";
final backendBaseUrl = dotenv.get('BACKEND_BASE_URL');

const Color colorPrincipal = Color(0XFF044B7F);
const Color colorSecundario = Color(0xFF107E7D);
const Color colorTerciario = Color(0xFFD8E214);

SharedPreferences? StateGlobal;

inicializarStateGlobal() async {
  StateGlobal ??= await SharedPreferences.getInstance();
}


Future<String> getToken() async {
  await inicializarStateGlobal();
  final token = StateGlobal?.getString('token');
  return token ?? '';
}

Future<http.Response> post_(String recurso, Object? datos) async {
  final (url, headers) = await datosDePeticion(recurso);
  return http.post(url, body: jsonEncode(datos), headers: headers);
}

Future<http.Response> put_(String recurso, Object? datos) async {
  final (url, headers) = await datosDePeticion(recurso);
  return http.put(url, body: jsonEncode(datos), headers: headers);
}

Future<http.Response> get_(String recurso) async {
  final (url, headers) = await datosDePeticion(recurso);
  return http.get(url, headers: headers);
}

Future<http.Response> delete_(String recurso) async {
  final (url, headers) = await datosDePeticion(recurso);
  return http.delete(url, headers: headers);
}

Future<http.Response> post(BuildContext context,String recurso,Object? datos,String mensaje, VoidCallback? accionBotonAlerta,VoidCallback? accionErrorRespuesta,) async {
  var response = await post_(recurso, datos);
  return manejarRespuestaHTTP(context, response, mensaje, accionBotonAlerta, accionErrorRespuesta);
}

Future<http.Response> put(BuildContext context,String recurso, Object? datos, String? mensaje,VoidCallback? accionBotonAlerta,VoidCallback? accionErrorRespuesta) async {
  var response = await put_(recurso, datos);
  return manejarRespuestaHTTP(context, response, mensaje, accionBotonAlerta, accionErrorRespuesta);
}

Future<http.Response> get(BuildContext context,String recurso,String? mensaje,VoidCallback? accionBotonAlerta,) async {
  var response = await get_(recurso);
  return manejarRespuestaHTTP(context, response, mensaje, accionBotonAlerta, null);
}


Future<(Uri, Map<String, String>)> datosDePeticion(String recurso) async {
  final url = Uri.parse('$backendBaseUrl$recurso');
  final token = await getToken();
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  };

  return (url, headers);
}

http.Response manejarRespuestaHTTP(BuildContext context, http.Response response, String? mensaje, VoidCallback? accionBotonAlerta, VoidCallback? accionErrorRespuesta) {
  if (!context.mounted) {
    print('[847653475]');
    throw false;
  }

  var correcto = response.statusCode >= 200 && response.statusCode < 300;

  if (!correcto) {
    mensaje = 'Ocurrió un error';

    if (response.body.isNotEmpty) {
      final rtaJSON = jsonDecode(response.body);
      if (rtaJSON.containsKey('error')) {
        mensaje = rtaJSON['error'];
      }
    }

    mostrarMensaje(context, AlertType.none, mensaje!, accionErrorRespuesta);

    throw mensaje;
  }

  if (context.mounted && mensaje != null) {
    mostrarMensaje(context, AlertType.success, mensaje, accionBotonAlerta);
  }

  return response;
}

void mostrarMensaje(BuildContext context, AlertType tipo, String mensaje,VoidCallback? accion) {
  Alert(
    context: context,
    type: AlertType.none,
    content: Builder(builder: (BuildContext context) {
      return Column(
        children: [
          // if (tipo == AlertType.error)
          //   Container(
          //     margin: EdgeInsets.zero,
          //     child: Image.asset('assets/informacion.png'),
          //   ),
          // if (tipo == AlertType.success)
          //   Container(
          //     margin: EdgeInsets.zero,
          //     child: Image.asset('assets/successAlert.png'),
          //   ),
          // if (tipo == AlertType.none)
          //   Container(
          //     margin: EdgeInsets.zero,
          //     child: Image.asset('assets/informacion.png'),
          //   ),
          TextoManrope(
            text: mensaje,
            fontSize: MediaQuery.of(context).size.height * 0.023,
            margin: EdgeInsets.only(
              left: MediaQuery.of(context).size.height * 0.05,
              right: MediaQuery.of(context).size.height * 0.05,
              top: MediaQuery.of(context).size.height * 0.03,
            ),
            textColor: Colors.black,
            fontWeight: FontWeight.w700,
            alignment: Alignment.centerRight,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }),
    buttons: [
      DialogButton(
        color: Colors.blue,
        onPressed: accion ?? () => Navigator.pop(context),
        width: MediaQuery.of(context).size.height * 0.2,
        child: Text(
          "Accept",
          style: GoogleFonts.manrope(
            color: colorPrincipal,
            fontSize: MediaQuery.of(context).size.width * 0.035,
            fontWeight: FontWeight.w600,
            height: 1.5,
            letterSpacing: -0.01,
          ),
        ),
      ),
    ],
  ).show();
}

class AlertaLoading {
  static OverlayEntry? _overlayEntry;
  static void show(BuildContext context, [String mensaje = "Loading..."]) {
    if (_overlayEntry != null) return;
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        child: Material(
          color: Colors.black.withOpacity(0.7),
          child: Center(
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: mensaje == "Loading..." ? MediaQuery.of(context).size.height * 0.3 : MediaQuery.of(context).size.height * 0.6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Image.asset(
                      //   'assets/iconEdeal.png',
                      //   width: mensaje != "Loading..." ? 60 : 70,
                      //   height: mensaje != "Loading..." ? 60 : 70,
                      // ),
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(colorPrincipal),
                      ),
                      const SizedBox(height: 20),
                      TextoManrope(
                        text: mensaje,
                        fontSize: mensaje != "Loading..." ? MediaQuery.of(context).size.width * 0.03 : MediaQuery.of(context).size.width * 0.04,
                        margin: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.01,
                        ),
                        textColor: Colors.black,
                        fontWeight: FontWeight.w700,
                        alignment: Alignment.center,
                      )
                    ],
                  ),
                ),
                if (mensaje == "Loading...")
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () {
                      hide();
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ]
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

Future<String> obtenerDireccionIP() async {
  try {
    var response = await http.get(Uri.parse('https://api64.ipify.org'));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Fallo al cargar la dirección IP');
    }
  } catch (e) {
    print('[98256345] $e');
    throw Exception('Fallo al cargar la dirección IP');
  }
}

Future<String> obtenerDireccionIPOpcional() async {
  try {
    return obtenerDireccionIP();
  } catch (_) {
    return '';
  }
}

void mostrarAlerta(BuildContext context, String titulo, String mensaje, AlertType tipoAlerta, VoidCallback onPressed, bool mostrarSegundoBoton, VoidCallback? onPressedSegundoBoton,String textoBotonAccept) {
  Alert(
    context: context,
    type: AlertType.none,
    content: Builder(builder: (BuildContext context) {
      return Container(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.zero,
              child: Image.asset('assets/informacion.png'),
            ),

            TextoManrope(
              text: mensaje, 
              fontSize: MediaQuery.of(context).size.width * 0.035, 
              margin: EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.05, right: MediaQuery.of(context).size.width * 0.05, top: MediaQuery.of(context).size.height * 0.03  ), 
              textColor: Colors.black, 
              fontWeight: FontWeight.w500, 
              alignment: Alignment.centerRight,
              textAlign: TextAlign.center,
            )
          ],
        )
      );
    }),
    buttons: [
      DialogButton(
        color: colorTerciario,
        onPressed: onPressed,
        width: MediaQuery.of(context).size.width * 0.4,
        child: TextoManrope(
          text: textoBotonAccept,
          fontSize: MediaQuery.of(context).size.width* 0.035,
          margin: EdgeInsets.zero,
          textColor: colorPrincipal,
          fontWeight: FontWeight.w700,
          alignment: Alignment.center
        ),
      ),
      if (mostrarSegundoBoton == true)
        DialogButton(
          color: colorTerciario,
          onPressed: onPressedSegundoBoton,
          width: MediaQuery.of(context).size.width * 0.4,
          child: TextoManrope(
            text: 'Rechazar ',
            fontSize: MediaQuery.of(context).size.width * 0.035,
            margin: EdgeInsets.zero,
            textColor: colorPrincipal,
            fontWeight: FontWeight.w700,
            alignment: Alignment.center
          ),
        ),
    ],
  ).show();
}
