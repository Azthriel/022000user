import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'aws/dynamo/dynamo.dart';
import 'aws/dynamo/dynamo_certificates.dart';
import 'aws/mqtt/mqtt.dart';
import 'stored_data.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';

//!-----DATA MASTER-----!\\
Map<String, Map<String, dynamic>> globalDATA = {};
//!-----DATA MASTER-----!\\
late bool android;
final dio = Dio();
List<String> topicsToSub = [];
List<String> adminDevices = [];
MyDevice myDevice = MyDevice();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
List<int> infoValues = [];
List<int> toolsValues = [];
List<int> ioValues = [];
String myDeviceid = '';
String deviceName = '';
bool bluetoothOn = true;
bool checkbleFlag = false;
bool checkubiFlag = false;
String textState = '';
String errorMessage = '';
String errorSintax = '';
String nameOfWifi = '';
var wifiIcon = Icons.wifi_off;
bool connectionFlag = false;
bool atemp = false;
bool isWifiConnected = false;
bool wifilogoConnected = false;
MaterialColor statusColor = Colors.grey;
bool alreadyLog = false;
int wrongPass = 0;
Timer? locationTimer;
Timer? bluetoothTimer;
int lastUser = 0;
List<String> previusConnections = [];
List<String> highlightedConnections = [];
Map<String, String> nicknamesMap = {};
Map<String, String> subNicknamesMap = {};
String deviceType = '';
String softwareVersion = '';
String hardwareVersion = '';
String currentUserEmail = '';
String deviceSerialNumber = '';
late String appName;
Map<String, List<bool>> notificationMap = {};
bool werror = false;
Map<String, String> tokensOfDevices = {};
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
bool deviceOwner = false;
bool secondaryAdmin = false;
String owner = '';
bool payAdmSec = false;
bool payAT = false;
bool activatedAT = false;
int vencimientoAdmSec = 0;
int vencimientoAT = 0;
bool tenant = false;

// Si esta en modo profile.
const bool xProfileMode = bool.fromEnvironment('dart.vm.profile');
// Si esta en modo release.
const bool xReleaseMode = bool.fromEnvironment('dart.vm.product');
// Determina si la app esta en debug.
const bool xDebugMode = !xProfileMode && !xReleaseMode;

//!------------------------------VERSION NUMBER---------------------------------------

String appVersionNumber = '24090900';
bool biocalden = true;
//ACORDATE: Cambia el número de versión en el pubspec.yaml antes de publicar
//ACORDATE: En caso de Silema, cambiar bool a false...

//!------------------------------VERSION NUMBER---------------------------------------

// FUNCIONES //

void printLog(var text) {
  if (xDebugMode) {
    // ignore: avoid_print
    print('PrintData: $text');
  }
}

void showToast(String message) {
  printLog('Toast: $message');
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color(0xFFFFFFFF),
      textColor: const Color(0xFF000000),
      fontSize: 16.0);
}

String command(String device) {
  if (device.contains('Eléctrico')) {
    return '022000_IOT';
  } else if (device.contains('Gas')) {
    return '027000_IOT';
  } else if (device.contains('Detector')) {
    return '015773_IOT';
  } else if (device.contains('Radiador')) {
    return '041220_IOT';
  } else if (device.contains('Módulo') || device.contains('Domótica')) {
    return '020010_IOT';
  } else {
    return '';
  }
}

String generateErrorReport(FlutterErrorDetails details) {
  return '''
Error: ${details.exception}
Stacktrace: ${details.stack}
Contexto: ${details.context}
  ''';
}

void sendReportError(String cuerpo) async {
  printLog(cuerpo);
  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  String recipients = 'ingenieria@intelligentgas.com.ar';
  String subject = 'Reporte de error $deviceName';

  try {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: recipients,
      query: encodeQueryParameters(
          <String, String>{'subject': subject, 'body': cuerpo}),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
    printLog('Correo enviado');
  } catch (error) {
    printLog('Error al enviar el correo: $error');
  }
}

void handleManualError(String e, String s) {
  String data = '''
Error: $e
Stacktrace: $s
  ''';
  _sendWhatsAppMessage('5491161437533', data);
}

String getWifiErrorSintax(int errorCode) {
  switch (errorCode) {
    case 1:
      return "WIFI_REASON_UNSPECIFIED";
    case 2:
      return "WIFI_REASON_AUTH_EXPIRE";
    case 3:
      return "WIFI_REASON_AUTH_LEAVE";
    case 4:
      return "WIFI_REASON_ASSOC_EXPIRE";
    case 5:
      return "WIFI_REASON_ASSOC_TOOMANY";
    case 6:
      return "WIFI_REASON_NOT_AUTHED";
    case 7:
      return "WIFI_REASON_NOT_ASSOCED";
    case 8:
      return "WIFI_REASON_ASSOC_LEAVE";
    case 9:
      return "WIFI_REASON_ASSOC_NOT_AUTHED";
    case 10:
      return "WIFI_REASON_DISASSOC_PWRCAP_BAD";
    case 11:
      return "WIFI_REASON_DISASSOC_SUPCHAN_BAD";
    case 12:
      return "WIFI_REASON_BSS_TRANSITION_DISASSOC";
    case 13:
      return "WIFI_REASON_IE_INVALID";
    case 14:
      return "WIFI_REASON_MIC_FAILURE";
    case 15:
      return "WIFI_REASON_4WAY_HANDSHAKE_TIMEOUT";
    case 16:
      return "WIFI_REASON_GROUP_KEY_UPDATE_TIMEOUT";
    case 17:
      return "WIFI_REASON_IE_IN_4WAY_DIFFERS";
    case 18:
      return "WIFI_REASON_GROUP_CIPHER_INVALID";
    case 19:
      return "WIFI_REASON_PAIRWISE_CIPHER_INVALID";
    case 20:
      return "WIFI_REASON_AKMP_INVALID";
    case 21:
      return "WIFI_REASON_UNSUPP_RSN_IE_VERSION";
    case 22:
      return "WIFI_REASON_INVALID_RSN_IE_CAP";
    case 23:
      return "WIFI_REASON_802_1X_AUTH_FAILED";
    case 24:
      return "WIFI_REASON_CIPHER_SUITE_REJECTED";
    case 25:
      return "WIFI_REASON_TDLS_PEER_UNREACHABLE";
    case 26:
      return "WIFI_REASON_TDLS_UNSPECIFIED";
    case 27:
      return "WIFI_REASON_SSP_REQUESTED_DISASSOC";
    case 28:
      return "WIFI_REASON_NO_SSP_ROAMING_AGREEMENT";
    case 29:
      return "WIFI_REASON_BAD_CIPHER_OR_AKM";
    case 30:
      return "WIFI_REASON_NOT_AUTHORIZED_THIS_LOCATION";
    case 31:
      return "WIFI_REASON_SERVICE_CHANGE_PERCLUDES_TS";
    case 32:
      return "WIFI_REASON_UNSPECIFIED_QOS";
    case 33:
      return "WIFI_REASON_NOT_ENOUGH_BANDWIDTH";
    case 34:
      return "WIFI_REASON_MISSING_ACKS";
    case 35:
      return "WIFI_REASON_EXCEEDED_TXOP";
    case 36:
      return "WIFI_REASON_STA_LEAVING";
    case 37:
      return "WIFI_REASON_END_BA";
    case 38:
      return "WIFI_REASON_UNKNOWN_BA";
    case 39:
      return "WIFI_REASON_TIMEOUT";
    case 46:
      return "WIFI_REASON_PEER_INITIATED";
    case 47:
      return "WIFI_REASON_AP_INITIATED";
    case 48:
      return "WIFI_REASON_INVALID_FT_ACTION_FRAME_COUNT";
    case 49:
      return "WIFI_REASON_INVALID_PMKID";
    case 50:
      return "WIFI_REASON_INVALID_MDE";
    case 51:
      return "WIFI_REASON_INVALID_FTE";
    case 67:
      return "WIFI_REASON_TRANSMISSION_LINK_ESTABLISH_FAILED";
    case 68:
      return "WIFI_REASON_ALTERATIVE_CHANNEL_OCCUPIED";
    case 200:
      return "WIFI_REASON_BEACON_TIMEOUT";
    case 201:
      return "WIFI_REASON_NO_AP_FOUND";
    case 202:
      return "WIFI_REASON_AUTH_FAIL";
    case 203:
      return "WIFI_REASON_ASSOC_FAIL";
    case 204:
      return "WIFI_REASON_HANDSHAKE_TIMEOUT";
    case 205:
      return "WIFI_REASON_CONNECTION_FAIL";
    case 206:
      return "WIFI_REASON_AP_TSF_RESET";
    case 207:
      return "WIFI_REASON_ROAMING";
    default:
      return "Error Desconocido";
  }
}

void startBluetoothMonitoring() {
  bluetoothTimer = Timer.periodic(
      const Duration(seconds: 1), (Timer t) => bluetoothStatus());
}

void bluetoothStatus() async {
  FlutterBluePlus.adapterState.listen((state) {
    // print('Estado ble: $state');
    if (state != BluetoothAdapterState.on) {
      bluetoothOn = false;
      showBleText();
    } else if (state == BluetoothAdapterState.on) {
      bluetoothOn = true;
    }
  });
}

void showBleText() async {
  if (!checkbleFlag) {
    checkbleFlag = true;
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252223),
          title: const Text(
            'Bluetooth apagado',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
          content: const Text(
            'No se puede continuar sin Bluetooth',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
          actions: [
            TextButton(
              style: const ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF))),
              onPressed: () async {
                if (Platform.isAndroid) {
                  await FlutterBluePlus.turnOn();
                  checkbleFlag = false;
                  bluetoothOn = true;
                  navigatorKey.currentState?.pop();
                } else {
                  checkbleFlag = false;
                  navigatorKey.currentState?.pop();
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}

void startLocationMonitoring() {
  locationTimer =
      Timer.periodic(const Duration(seconds: 1), (Timer t) => locationStatus());
}

void locationStatus() async {
  await NativeService.isLocationServiceEnabled();
}

void showPrivacyDialogIfNeeded() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasShownDialog = prefs.getBool('hasShownDialog') ?? false;

  if (!hasShownDialog) {
    await showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252223),
          title: const Text(
            'Política de Privacidad',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'En $appName,  valoramos tu privacidad y seguridad. Queremos asegurarte que nuestra aplicación está diseñada con el respeto a tu privacidad personal. Aquí hay algunos puntos clave que debes conocer:\nNo Recopilamos Información Personal: Nuestra aplicación no recopila ni almacena ningún tipo de información personal de nuestros usuarios. Puedes usar nuestra aplicación con la tranquilidad de que tu privacidad está protegida.\nUso de Permisos: Aunque nuestra aplicación solicita ciertos permisos, como el acceso a la cámara, estos se utilizan exclusivamente para el funcionamiento de la aplicación y no para recopilar datos personales.\nPolítica de Privacidad Detallada: Si deseas obtener más información sobre nuestra política de privacidad, te invitamos a visitar nuestra página web. Allí encontrarás una explicación detallada de nuestras prácticas de privacidad.\nPara continuar y disfrutar de todas las funcionalidades de $appName, por favor, acepta nuestra política de privacidad.',
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: const ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF))),
              child: const Text('Leer nuestra politica de privacidad'),
              onPressed: () async {
                Uri uri = Uri.parse(biocalden
                    ? 'https://biocalden.com.ar/privacidad/'
                    : 'https://silema.com.ar/privacidad/');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  showToast('No se pudo abrir el sitio web');
                }
              },
            ),
            TextButton(
              style: const ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF))),
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    await prefs.setBool('hasShownDialog', true);
  }
}

String generateRandomNumbers(int length) {
  Random random = Random();
  String result = '';

  for (int i = 0; i < length; i++) {
    result += random.nextInt(10).toString();
  }

  return result;
}

Future<void> openQRScanner(BuildContext context) async {
  try {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var qrResult = await navigatorKey.currentState
          ?.push(MaterialPageRoute(builder: (context) => const QRScanPage()));
      if (qrResult != null) {
        var wifiData = parseWifiQR(qrResult);
        sendWifitoBle(wifiData['SSID']!, wifiData['password']!);
      }
    });
  } catch (e) {
    printLog("Error during navigation: $e");
  }
}

Map<String, String> parseWifiQR(String qrContent) {
  printLog(qrContent);
  final ssidMatch = RegExp(r'S:([^;]+)').firstMatch(qrContent);
  final passwordMatch = RegExp(r'P:([^;]+)').firstMatch(qrContent);

  final ssid = ssidMatch?.group(1) ?? '';
  final password = passwordMatch?.group(1) ?? '';
  return {"SSID": ssid, "password": password};
}

void asking() async {
  bool alreadyLog = await isUserSignedIn();

  if (!alreadyLog) {
    printLog('Usuario no está logueado');
    navigatorKey.currentState?.pushReplacementNamed('/login');
  } else {
    printLog('Usuario logueado');
    navigatorKey.currentState?.pushReplacementNamed('/scan');
  }
}

Future<bool> isUserSignedIn() async {
  final result = await Amplify.Auth.fetchAuthSession();
  return result.isSignedIn;
}

Future<String> getUserMail() async {
  try {
    final attributes = await Amplify.Auth.fetchUserAttributes();
    for (final attribute in attributes) {
      if (attribute.userAttributeKey.key == 'email') {
        return attribute.value; // Retorna el correo electrónico del usuario
      }
    }
  } on AuthException catch (e) {
    printLog('Error fetching user attributes: ${e.message}');
  }
  return ''; // Retorna nulo si no se encuentra el correo electrónico
}

void getMail() async {
  currentUserEmail = await getUserMail();
}

String extractSerialNumber(String productName) {
  RegExp regExp = RegExp(r'(\d{8})');

  Match? match = regExp.firstMatch(productName);

  return match?.group(0) ?? '';
}

void showContactInfo(BuildContext context) {
  showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Contacto comercial:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => _sendWhatsAppMessage('5491162234181',
                        '¡Hola! Tengo una duda comercial sobre los productos $appName: \n'),
                    icon: Icon(
                      android ? Icons.phone : CupertinoIcons.phone,
                      size: 20,
                    )),
                const Text('+54 9 11 6223-4181', style: TextStyle(fontSize: 20))
              ],
            ),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => _launchEmail(
                          'ceat@ibsanitarios.com.ar',
                          'Consulta comercial acerca de la linea $appName',
                          '¡Hola! mi equipo es el $deviceName y tengo la siguiente duda:\n'),
                      icon: const Icon(
                        Icons.mail,
                        size: 20,
                      ),
                    ),
                    const Text('ceat@ibsanitarios.com.ar',
                        style: TextStyle(fontSize: 20))
                  ],
                )),
            const SizedBox(height: 20),
            const Text('Consulta técnica:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _launchEmail(
                        'pablo@intelligentgas.com.ar',
                        'Consulta ref. $deviceName',
                        '¡Hola! Tengo una consulta referida al área de ingenieria sobre mi equipo.\n Información del mismo:\nModelo: ${command(deviceName)}\nVersión de software: $softwareVersion \nVersión de hardware: $hardwareVersion \nMi duda es la siguiente:\n'),
                    icon: const Icon(
                      Icons.mail,
                      size: 20,
                    ),
                  ),
                  const Text(
                    'pablo@intelligentgas.com.ar',
                    style: TextStyle(fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Customer service:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => _sendWhatsAppMessage('5491162232619',
                        '¡Hola! Te hablo por una duda sobre mi equipo $deviceName: \n'),
                    icon: const Icon(
                      Icons.phone,
                      size: 20,
                    )),
                const Text('+54 9 11 6223-2619', style: TextStyle(fontSize: 20))
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _launchEmail(
                        'service@calefactorescalden.com.ar',
                        'Consulta ${command(deviceName)}',
                        'Tengo una consulta referida a mi equipo $deviceName: \n'),
                    icon: const Icon(
                      Icons.mail,
                      size: 20,
                    ),
                  ),
                  const Text(
                    'service@calefactorescalden.com.ar',
                    style: TextStyle(color: Color(0xFF000000), fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showSilemaContactInfo(BuildContext context) {
  showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Servicio técnico:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => _sendWhatsAppMessage('5491122845561',
                        '¡Hola! Tengo una duda comercial sobre los productos $appName: \n'),
                    icon: const Icon(
                      Icons.phone,
                      size: 20,
                    )),
                const Text('+54 9 11 2284-5561', style: TextStyle(fontSize: 20))
              ],
            ),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => _launchEmail(
                          'silemacalefaccion@gmail.com',
                          'Consulta comercial acerca de la linea IOT',
                          '¡Hola! mi equipo es el $deviceName y tengo la siguiente duda:\n'),
                      icon: const Icon(
                        Icons.mail,
                        size: 20,
                      ),
                    ),
                    const Text('silemacalefaccion@gmail.com',
                        style: TextStyle(fontSize: 20))
                  ],
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () async {
                    String url = 'http://www.silema.com.ar/';
                    var uri = Uri.parse(url);
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        printLog('No se pudo abrir la URL: $url');
                      }
                    } catch (e, s) {
                      printLog('Error url $e Stacktrace: $s');
                    }
                  },
                  icon: const Icon(
                    Icons.language,
                    size: 20,
                  ),
                ),
                const Text('silema.com.ar', style: TextStyle(fontSize: 20))
              ],
            )
          ],
        ),
      );
    },
  );
}

Future<void> _sendWhatsAppMessage(String phoneNumber, String message) async {
  var whatsappUrl =
      "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeFull(message)}";
  Uri uri = Uri.parse(whatsappUrl);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    showToast('No se pudo abrir WhatsApp');
  }
}

void _launchEmail(String mail, String asunto, String cuerpo) async {
  final Uri emailLaunchUri = Uri(
    scheme: 'mailto',
    path: mail,
    query: encodeQueryParameters(
        <String, String>{'subject': asunto, 'body': cuerpo}),
  );

  if (await canLaunchUrl(emailLaunchUri)) {
    await launchUrl(emailLaunchUri);
  } else {
    showToast('No se pudo abrir el correo electrónico');
  }
}

String encodeQueryParameters(Map<String, String> params) {
  return params.entries
      .map((e) =>
          '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}

void setupToken(String pc, String sn, String device) async {
  if (android) {
    String? token = await FirebaseMessaging.instance.getToken();
    String? tokenToSend = '$token/-/${nicknamesMap[device] ?? device}';
    List<String> tokens = await getTokens(service, pc, sn);
    printLog('Tokens: $tokens');
    if (token != null) {
      if (tokens.contains(tokensOfDevices[device])) {
        tokens.remove(tokensOfDevices[device]);
      }
      tokens.add(tokenToSend);
      await putTokens(service, pc, sn, tokens);
      tokensOfDevices.addAll({device: tokenToSend});
      saveToken(tokensOfDevices);
      printLog('Token agregado exitosamente');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      String? newTokenToSend = '$newToken/-/${nicknamesMap[device] ?? device}';
      List<String> tokens = await getTokens(service, pc, sn);
      if (tokensOfDevices[device] != null) {
        tokens.remove(tokensOfDevices[device]);
      }
      tokens.add(newTokenToSend);
      await putTokens(service, pc, sn, tokens);
      tokensOfDevices.addAll({device: newTokenToSend});
      saveToken(tokensOfDevices);
      printLog('Token actualizado exitosamente');
    });
  } else {
    printLog('Soy iOS');
    String? token = await NativeService.getApnsToken();
    String? tokenToSend = '$token/-/${nicknamesMap[device] ?? device}';
    List<String> tokens = await getTokens(service, pc, sn);
    printLog('Tokens: $tokens');
    if (token != null) {
      // await saveTokenasEndpoint(token);
      if (tokens.contains(tokensOfDevices[device])) {
        tokens.remove(tokensOfDevices[device]);
      }
      tokens.add(tokenToSend);
      await putTokens(service, pc, sn, tokens);
      tokensOfDevices.addAll({device: tokenToSend});
      saveToken(tokensOfDevices);
      printLog('Token agregado exitosamente');
    }
  }
}

void setupIOToken(
    String nick, int index, String pc, String sn, String device) async {
  if (android) {
    String? token = await FirebaseMessaging.instance.getToken();
    printLog('Nick: $nick');
    String? tokenToSend = '$token/-/$nick';

    List<String> tokens = await getIOTokens(service, pc, sn, index);
    if (token != null) {
      if (tokensOfDevices['$device$index'] != null) {
        printLog('Eliminando: ${tokensOfDevices['$device$index']}');
        tokens.remove(tokensOfDevices['$device$index']);
      }
      tokens.add(tokenToSend);
      await putIOTokens(service, pc, sn, tokens, index);
      tokensOfDevices.addAll({'$device$index': tokenToSend});
      saveToken(tokensOfDevices);
      printLog('Token agregado exitosamente');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      String? newtokenToSend = '$newToken/-/$nick';
      List<String> tokens = await getIOTokens(service, pc, sn, index);
      if (tokensOfDevices['$device$index'] != null) {
        tokens.remove(tokensOfDevices['$device$index']);
      }
      tokens.add(newtokenToSend);
      tokensOfDevices.addAll({'$device$index': newtokenToSend});
      await putIOTokens(service, pc, sn, tokens, index);
      saveToken(tokensOfDevices);
    });
  } else {
    printLog('Soy iOS');
    String? token = await NativeService.getApnsToken();
    printLog('Nick: $nick');
    String? tokenToSend = '$token/-/$nick';
    List<String> tokens = await getIOTokens(service, pc, sn, index);
    printLog('Tokens: $tokens');
    if (token != null) {
      if (tokens.contains(tokensOfDevices[device])) {
        tokens.remove(tokensOfDevices[device]);
      }
      tokens.add(tokenToSend);
      tokensOfDevices.addAll({'$device$index': tokenToSend});
      await putIOTokens(service, pc, sn, tokens, index);
      saveToken(tokensOfDevices);
      printLog('Token agregado exitosamente');
    }
  }
}

void createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'fcm_fallback_notification_channel',
    'FCM Notifications',
    description: 'This channel is used for FCM notifications.',
    importance: Importance.max,
    sound: RawResourceAndroidNotificationSound('alarm_sound'),
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

void showAdminText() {
  showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252223),
          title: const Text(
            'Haz alcanzado el límite máximo de administradores secundarios',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
          content: const Text(
            'En caso de requerir más puedes solicitarlos vía mail',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
          actions: [
            TextButton(
                style: const ButtonStyle(
                    foregroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF))),
                onPressed: () async {
                  String cuerpo =
                      '¡Hola! Me comunico porque busco extender el plazo de administradores secundarios en mi equipo $deviceName\nCódigo de Producto: ${command(deviceName)}\nNúmero de Serie: ${extractSerialNumber(deviceName)}\nDueño actual del equipo: $owner';
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'cobranzas@ibsanitarios.com.ar',
                    query: encodeQueryParameters(<String, String>{
                      'subject': 'Extensión de administradores secundarios',
                      'body': cuerpo,
                      'CC': 'pablo@intelligentgas.com.ar'
                    }),
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  } else {
                    showToast('No se pudo enviar el correo electrónico');
                  }
                  navigatorKey.currentState?.pop();
                },
                child: const Text('Solicitar'))
          ],
        );
      });
}

Future<void> analizePayment(
  String pc,
  String sn,
) async {
  List<DateTime> expDates = await getDates(service, pc, sn);

  vencimientoAdmSec = expDates[0].difference(DateTime.now()).inDays;

  payAdmSec = vencimientoAdmSec > 0;

  printLog('--------------Administradores secundarios--------------');
  printLog(expDates[0].toIso8601String());
  printLog('Se vence en $vencimientoAdmSec dias');
  printLog('¿Esta pago? ${payAdmSec ? 'Si' : 'No'}');
  printLog('--------------Administradores secundarios--------------');

  vencimientoAT = expDates[1].difference(DateTime.now()).inDays;

  payAT = vencimientoAT > 0;

  printLog('--------------Alquiler Temporario--------------');
  printLog(expDates[1].toIso8601String());
  printLog('Se vence en $vencimientoAT dias');
  printLog('¿Esta pago? ${payAT ? 'Si' : 'No'}');
  printLog('--------------Alquiler Temporario--------------');
}

void showPaymentTest(bool adm, int vencimiento, BuildContext context) {
  try {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E242B),
          title: const Text(
            '¡Estas por perder tu beneficio!',
            style: TextStyle(
              color: Color(0xFFB2B5AE),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Faltan $vencimiento días para que te quedes sin la opción:',
                style: const TextStyle(
                    color: Color(0xFFB2B5AE), fontWeight: FontWeight.normal),
              ),
              adm
                  ? const Text(
                      'Administradores secundarios extra',
                      style: TextStyle(
                          color: Color(0xFFB2B5AE),
                          fontWeight: FontWeight.bold),
                    )
                  : const Text(
                      'Habilitar alquiler temporario',
                      style: TextStyle(
                          color: Color(0xFFB2B5AE),
                          fontWeight: FontWeight.bold),
                    )
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: const ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  Color(0xFFB2B5AE),
                ),
              ),
              child: const Text('Ignorar'),
              onPressed: () {
                navigatorKey.currentState?.pop();
              },
            ),
            TextButton(
              style: const ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  Color(0xFFB2B5AE),
                ),
              ),
              child: const Text('Solicitar extensión'),
              onPressed: () async {
                String cuerpo = adm
                    ? '¡Hola! Me comunico porque busco extender mi beneficio de "Administradores secundarios extra" en mi equipo $deviceName\nCódigo de Producto: ${command(deviceName)}\nNúmero de Serie: ${extractSerialNumber(deviceName)}\nDueño actual del equipo: $owner\nVencimiento en: $vencimiento dias'
                    : '¡Hola! Me comunico porque busco extender mi beneficio "Habilitar alquiler temporario" en mi equipo $deviceName\nCódigo de Producto: ${command(deviceName)}\nNúmero de Serie: ${extractSerialNumber(deviceName)}\nDueño actual del equipo: $owner\nVencimiento en: $vencimiento dias';
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'cobranzas@ibsanitarios.com.ar',
                  query: encodeQueryParameters(<String, String>{
                    'subject': 'Extensión de beneficio',
                    'body': cuerpo,
                    'CC': 'pablo@intelligentgas.com.ar'
                  }),
                );
                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri);
                } else {
                  showToast('No se pudo enviar el correo electrónico');
                }
                navigatorKey.currentState?.pop();
              },
            ),
          ],
        );
      },
    );
  } catch (e, s) {
    printLog(e);
    printLog(s);
  }
}

void showATText() {
  showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF252223),
          title: const Text(
            'Actualmente no tienes habilitado este beneficio',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
          content: const Text(
            'En caso de requerirlo puedes solicitarlo vía mail',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
          actions: [
            TextButton(
                style: const ButtonStyle(
                    foregroundColor: WidgetStatePropertyAll(Color(0xFFFFFFFF))),
                onPressed: () async {
                  String cuerpo =
                      '¡Hola! Me comunico porque busco habilitar la opción de "Alquiler temporario" en mi equipo $deviceName\nCódigo de Producto: ${command(deviceName)}\nNúmero de Serie: ${extractSerialNumber(deviceName)}\nDueño actual del equipo: $owner';
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'cobranzas@ibsanitarios.com.ar',
                    query: encodeQueryParameters(<String, String>{
                      'subject': 'Habilitación alquiler temporario',
                      'body': cuerpo,
                      'CC': 'pablo@intelligentgas.com.ar'
                    }),
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  } else {
                    showToast('No se pudo enviar el correo electrónico');
                  }
                  navigatorKey.currentState?.pop();
                },
                child: const Text('Solicitar'))
          ],
        );
      });
}

Future<void> configAT() async {
  showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: true,
      builder: (context) {
        final TextEditingController tenantController = TextEditingController();
        final TextEditingController tenantDistanceOn = TextEditingController();
        final TextEditingController tenantDistanceOff = TextEditingController();
        bool dOnOk = false;
        bool dOffOk = false;
        final FocusNode dOnNode = FocusNode();
        final FocusNode dOffNode = FocusNode();
        return AlertDialog(
          backgroundColor: const Color(0xFF252223),
          title: const Text(
            'Configura los parametros del alquiler',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
          content: SingleChildScrollView(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tenantController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                    ),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.person),
                      iconColor: Color(0xFFFFFFFF),
                      labelText: "Email del inquilino",
                      labelStyle: TextStyle(
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    onEditingComplete: () {
                      if (tenantController.text != '') {
                        dOffNode.requestFocus();
                      } else {
                        showToast('Debes ingresar un mail');
                      }
                    },
                  ),
                  TextField(
                    controller: tenantDistanceOff,
                    keyboardType: TextInputType.number,
                    focusNode: dOffNode,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                    ),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.map),
                      iconColor: Color(0xFFFFFFFF),
                      labelText: "Distancia de apagado",
                      labelStyle: TextStyle(
                        color: Color(0xFFFFFFFF),
                      ),
                      hintText: 'Entre 100 y 300 metros',
                      hintStyle: TextStyle(
                        color: Color(0xFF8D8D8D),
                      ),
                    ),
                    onEditingComplete: () {
                      int? fun = int.tryParse(tenantDistanceOff.text);
                      if (fun == null || fun < 100 || fun > 300) {
                        showToast('Distancia de apagado no permitida');
                      } else {
                        dOffOk = true;
                        dOnNode.requestFocus();
                      }
                    },
                  ),
                  TextField(
                    controller: tenantDistanceOn,
                    keyboardType: TextInputType.number,
                    focusNode: dOnNode,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                    ),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.map),
                      iconColor: Color(0xFFFFFFFF),
                      labelText: "Distancia de encendido",
                      labelStyle: TextStyle(
                        color: Color(0xFFFFFFFF),
                      ),
                      hintText: 'Entre 3000 y 5000 metros',
                      hintStyle: TextStyle(
                        color: Color(0xFF8D8D8D),
                      ),
                    ),
                    onEditingComplete: () {
                      int? fun = int.tryParse(tenantDistanceOn.text);
                      if (fun == null || fun < 3000 || fun > 5000) {
                        showToast('Distancia de encendido no permitida');
                      } else {
                        dOnOk = true;
                      }
                    },
                  ),
                ]),
          ),
          actions: [
            TextButton(
                style: const ButtonStyle(
                  foregroundColor: WidgetStatePropertyAll(
                    Color(0xFFFFFFFF),
                  ),
                ),
                onPressed: () {
                  if (dOnOk && dOffOk && tenantController.text != '') {
                    saveATData(
                      service,
                      command(deviceName),
                      extractSerialNumber(deviceName),
                      true,
                      tenantController.text.trim(),
                      tenantDistanceOn.text.trim(),
                      tenantDistanceOff.text.trim(),
                    );
                    navigatorKey.currentState?.pop();
                  } else {
                    showToast('Parametros no permitidos');
                  }
                },
                child: const Text('Activar')),
          ],
        );
      });
}

void showCupertinoBleText() async {
  if (!checkbleFlag) {
    checkbleFlag = true;
    showCupertinoDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Bluetooth apagado',
            style: TextStyle(color: CupertinoColors.label),
          ),
          content: const Text(
            'No se puede continuar sin Bluetooth',
            style: TextStyle(color: CupertinoColors.label),
          ),
          actions: [
            TextButton(
              style: const ButtonStyle(
                  foregroundColor:
                      WidgetStatePropertyAll(CupertinoColors.label)),
              onPressed: () async {
                if (Platform.isAndroid) {
                  await FlutterBluePlus.turnOn();
                  checkbleFlag = false;
                  bluetoothOn = true;
                  navigatorKey.currentState?.pop();
                } else {
                  checkbleFlag = false;
                  navigatorKey.currentState?.pop();
                }
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }
}

void showCupertinoUbiText() {
  if (!checkubiFlag) {
    checkubiFlag = true;
    showCupertinoDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Ubicación apagada',
              style: TextStyle(color: CupertinoColors.label),
            ),
            content: const Text(
              'No se puede continuar sin la ubicación',
              style: TextStyle(color: CupertinoColors.label),
            ),
            actions: [
              TextButton(
                  style: const ButtonStyle(
                      foregroundColor:
                          WidgetStatePropertyAll(Color(0xFFFFFFFF))),
                  onPressed: () async {
                    checkubiFlag = false;
                    navigatorKey.currentState?.pop();
                  },
                  child: const Text('Aceptar'))
            ],
          );
        });
  }
}

void showCupertinoPrivacyDialogIfNeeded() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasShownDialog = prefs.getBool('hasShownDialog') ?? false;

  if (!hasShownDialog) {
    await showCupertinoDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text(
            'Política de Privacidad',
            style: TextStyle(color: CupertinoColors.label),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'En $appName,  valoramos tu privacidad y seguridad. Queremos asegurarte que nuestra aplicación está diseñada con el respeto a tu privacidad personal. Aquí hay algunos puntos clave que debes conocer:\nNo Recopilamos Información Personal: Nuestra aplicación no recopila ni almacena ningún tipo de información personal de nuestros usuarios. Puedes usar nuestra aplicación con la tranquilidad de que tu privacidad está protegida.\nUso de Permisos: Aunque nuestra aplicación solicita ciertos permisos, como el acceso a la cámara, estos se utilizan exclusivamente para el funcionamiento de la aplicación y no para recopilar datos personales.\nPolítica de Privacidad Detallada: Si deseas obtener más información sobre nuestra política de privacidad, te invitamos a visitar nuestra página web. Allí encontrarás una explicación detallada de nuestras prácticas de privacidad.\nPara continuar y disfrutar de todas las funcionalidades de $appName, por favor, acepta nuestra política de privacidad.',
                  style: const TextStyle(color: CupertinoColors.label),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: const ButtonStyle(
                  foregroundColor:
                      WidgetStatePropertyAll(CupertinoColors.label)),
              child: const Text('Leer nuestra politica de privacidad'),
              onPressed: () async {
                Uri uri = Uri.parse(biocalden
                    ? 'https://biocalden.com.ar/privacidad/'
                    : 'https://silema.com.ar/privacidad/');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  showToast('No se pudo abrir el sitio web');
                }
              },
            ),
            TextButton(
              style: const ButtonStyle(
                  foregroundColor:
                      WidgetStatePropertyAll(CupertinoColors.label)),
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    await prefs.setBool('hasShownDialog', true);
  }
}

void showCupertinoContactInfo(BuildContext context) {
  showCupertinoDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Contacto comercial:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                      onPressed: () => _sendWhatsAppMessage('5491162234181',
                          '¡Hola! Tengo una duda comercial sobre los productos $appName: \n'),
                      child: const Icon(
                        CupertinoIcons.phone,
                        size: 20,
                      )),
                  const Text('+54 9 11 6223-4181',
                      style: TextStyle(fontSize: 20))
                ],
              ),
            ),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      onPressed: () => _launchEmail(
                          'ceat@ibsanitarios.com.ar',
                          'Consulta comercial acerca de la linea $appName',
                          '¡Hola! mi equipo es el $deviceName y tengo la siguiente duda:\n'),
                      child: const Icon(
                        CupertinoIcons.mail,
                        size: 20,
                      ),
                    ),
                    const Text('ceat@ibsanitarios.com.ar',
                        style: TextStyle(fontSize: 20))
                  ],
                )),
            const SizedBox(height: 20),
            const Text('Consulta técnica:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                    onPressed: () => _launchEmail(
                        'pablo@intelligentgas.com.ar',
                        'Consulta ref. $deviceName',
                        '¡Hola! Tengo una consulta referida al área de ingenieria sobre mi equipo.\n Información del mismo:\nModelo: ${command(deviceName)}\nVersión de software: $softwareVersion \nVersión de hardware: $hardwareVersion \nMi duda es la siguiente:\n'),
                    child: const Icon(
                      CupertinoIcons.mail,
                      size: 20,
                    ),
                  ),
                  const Text(
                    'pablo@intelligentgas.com.ar',
                    style: TextStyle(fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Customer service:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                      onPressed: () => _sendWhatsAppMessage('5491162232619',
                          '¡Hola! Te hablo por una duda sobre mi equipo $deviceName: \n'),
                      child: const Icon(
                        CupertinoIcons.phone,
                        size: 20,
                      )),
                  const Text('+54 9 11 6223-2619',
                      style: TextStyle(fontSize: 20))
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoButton(
                    onPressed: () => _launchEmail(
                        'service@calefactorescalden.com.ar',
                        'Consulta ${command(deviceName)}',
                        'Tengo una consulta referida a mi equipo $deviceName: \n'),
                    child: const Icon(
                      CupertinoIcons.mail,
                      size: 20,
                    ),
                  ),
                  const Text(
                    'service@calefactorescalden.com.ar',
                    style: TextStyle(color: Color(0xFF000000), fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showCupertinoSilemaContactInfo(BuildContext context) {
  showCupertinoDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Servicio técnico:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: () => _sendWhatsAppMessage('5491122845561',
                          '¡Hola! Tengo una duda comercial sobre los productos $appName: \n'),
                      icon: const Icon(
                        CupertinoIcons.phone,
                        size: 20,
                      )),
                  const Text('+54 9 11 2284-5561',
                      style: TextStyle(fontSize: 20))
                ],
              ),
            ),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => _launchEmail(
                          'silemacalefaccion@gmail.com',
                          'Consulta comercial acerca de la linea IOT',
                          '¡Hola! mi equipo es el $deviceName y tengo la siguiente duda:\n'),
                      icon: const Icon(
                        CupertinoIcons.mail,
                        size: 20,
                      ),
                    ),
                    const Text('silemacalefaccion@gmail.com',
                        style: TextStyle(fontSize: 20))
                  ],
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () async {
                    String url = 'http://www.silema.com.ar/';
                    var uri = Uri.parse(url);
                    try {
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      } else {
                        printLog('No se pudo abrir la URL: $url');
                      }
                    } catch (e, s) {
                      printLog('Error url $e Stacktrace: $s');
                    }
                  },
                  icon: const Icon(
                    Icons.language,
                    size: 20,
                  ),
                ),
                const Text('silema.com.ar', style: TextStyle(fontSize: 20))
              ],
            )
          ],
        ),
      );
    },
  );
}

void showCupertinoAdminText() {
  showCupertinoDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text(
            'Haz alcanzado el límite máximo de administradores secundarios',
            style: TextStyle(color: CupertinoColors.white),
          ),
          content: const Text(
            'En caso de requerir más puedes solicitarlos vía mail',
            style: TextStyle(color: Color(0xFFFFFFFF)),
          ),
          actions: [
            CupertinoButton(
                color: const Color(0xFFFFFFFF),
                onPressed: () async {
                  String cuerpo =
                      '¡Hola! Me comunico porque busco extender el plazo de administradores secundarios en mi equipo $deviceName\nCódigo de Producto: ${command(deviceName)}\nNúmero de Serie: ${extractSerialNumber(deviceName)}\nDueño actual del equipo: $owner';
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'cobranzas@ibsanitarios.com.ar',
                    query: encodeQueryParameters(<String, String>{
                      'subject': 'Extensión de administradores secundarios',
                      'body': cuerpo,
                      'CC': 'pablo@intelligentgas.com.ar'
                    }),
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  } else {
                    showToast('No se pudo enviar el correo electrónico');
                  }
                  navigatorKey.currentState?.pop();
                },
                child: const Text('Solicitar'))
          ],
        );
      });
}

void showCupertinoATText() {
  showCupertinoDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: true,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text(
            'Actualmente no tienes habilitado este beneficio',
            style: TextStyle(color: CupertinoColors.label),
          ),
          content: const Text(
            'En caso de requerirlo puedes solicitarlo vía mail',
            style: TextStyle(color: CupertinoColors.label),
          ),
          actions: [
            TextButton(
                style: const ButtonStyle(
                    foregroundColor:
                        WidgetStatePropertyAll(CupertinoColors.label)),
                onPressed: () async {
                  String cuerpo =
                      '¡Hola! Me comunico porque busco habilitar la opción de "Alquiler temporario" en mi equipo $deviceName\nCódigo de Producto: ${command(deviceName)}\nNúmero de Serie: ${extractSerialNumber(deviceName)}\nDueño actual del equipo: $owner';
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'cobranzas@ibsanitarios.com.ar',
                    query: encodeQueryParameters(<String, String>{
                      'subject': 'Habilitación alquiler temporario',
                      'body': cuerpo,
                      'CC': 'pablo@intelligentgas.com.ar'
                    }),
                  );
                  if (await canLaunchUrl(emailLaunchUri)) {
                    await launchUrl(emailLaunchUri);
                  } else {
                    showToast('No se pudo enviar el correo electrónico');
                  }
                  navigatorKey.currentState?.pop();
                },
                child: const Text('Solicitar'))
          ],
        );
      });
}

Future<void> configCupertinoAT() async {
  showCupertinoDialog(
    context: navigatorKey.currentContext!,
    barrierDismissible: true,
    builder: (context) {
      final TextEditingController tenantController = TextEditingController();
      final TextEditingController tenantDistanceOn = TextEditingController();
      final TextEditingController tenantDistanceOff = TextEditingController();
      bool dOnOk = false;
      bool dOffOk = false;
      final FocusNode dOnNode = FocusNode();
      final FocusNode dOffNode = FocusNode();
      return CupertinoAlertDialog(
        title: const Text(
          'Configura los parametros del alquiler',
          style: TextStyle(color: CupertinoColors.label),
        ),
        content: SingleChildScrollView(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(
                  controller: tenantController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: CupertinoColors.label,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                  placeholder: 'Email del inquilino',
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.label,
                  ),
                  prefix: const Icon(
                    CupertinoIcons.mail,
                    color: CupertinoColors.label,
                  ),
                  onEditingComplete: () {
                    if (tenantController.text != '') {
                      dOffNode.requestFocus();
                    } else {
                      showToast('Debes ingresar un mail');
                    }
                  },
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: tenantDistanceOff,
                  keyboardType: TextInputType.number,
                  focusNode: dOffNode,
                  style: const TextStyle(
                    color: CupertinoColors.label,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                  placeholder: 'Distancia de apagado',
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.label,
                  ),
                  prefix: const Icon(
                    CupertinoIcons.map,
                    color: CupertinoColors.label,
                  ),
                  onEditingComplete: () {
                    int? fun = int.tryParse(tenantDistanceOff.text);
                    if (fun == null || fun < 100 || fun > 300) {
                      showToast('Distancia de apagado no permitida');
                    } else {
                      dOffOk = true;
                      dOnNode.requestFocus();
                    }
                  },
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: tenantDistanceOn,
                  keyboardType: TextInputType.number,
                  focusNode: dOnNode,
                  style: const TextStyle(
                    color: CupertinoColors.label,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                  placeholder: 'Distancia de encendido',
                  placeholderStyle: const TextStyle(
                    color: CupertinoColors.label,
                  ),
                  prefix: const Icon(
                    CupertinoIcons.map,
                    color: CupertinoColors.label,
                  ),
                  onEditingComplete: () {
                    int? fun = int.tryParse(tenantDistanceOn.text);
                    if (fun == null || fun < 3000 || fun > 5000) {
                      showToast('Distancia de encendido no permitida');
                    } else {
                      dOnOk = true;
                    }
                  },
                ),
              ]),
        ),
        actions: [
          TextButton(
              style: const ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  CupertinoColors.label,
                ),
              ),
              onPressed: () {
                if (dOnOk && dOffOk && tenantController.text != '') {
                  saveATData(
                    service,
                    command(deviceName),
                    extractSerialNumber(deviceName),
                    true,
                    tenantController.text.trim(),
                    tenantDistanceOn.text.trim(),
                    tenantDistanceOff.text.trim(),
                  );
                  navigatorKey.currentState?.pop();
                } else {
                  showToast('Parametros no permitidos');
                }
              },
              child: const Text('Activar')),
        ],
      );
    },
  );
}

//*-WIFI-*//

List<WiFiAccessPoint> _wifiNetworksList = [];
String? _currentlySelectedSSID;
Map<String, String?> _wifiPasswordsMap = {};
FocusNode wifiPassNode = FocusNode();
bool _scanInProgress = false;
int? _expandedIndex;

Future<void> sendWifitoBle(String ssid, String pass) async {
  MyDevice myDevice = MyDevice();
  String value = '$ssid#$pass';
  String deviceCommand = command(deviceName);
  printLog(deviceCommand);
  String dataToSend = '$deviceCommand[1]($value)';
  printLog(dataToSend);
  try {
    await myDevice.toolsUuid.write(dataToSend.codeUnits);
    printLog('Se mando el wifi ANASHE');
  } catch (e) {
    printLog('Error al conectarse a Wifi $e');
  }
  ssid != 'DSC' ? atemp = true : null;
}

Future<List<WiFiAccessPoint>> _fetchWiFiNetworks() async {
  if (_scanInProgress) return _wifiNetworksList;

  _scanInProgress = true;

  try {
    if (await Permission.locationWhenInUse.request().isGranted) {
      final canScan = await WiFiScan.instance.canStartScan();
      if (canScan == CanStartScan.yes) {
        final results = await WiFiScan.instance.startScan();
        if (results == true) {
          final networks = await WiFiScan.instance.getScannedResults();

          if (networks.isNotEmpty) {
            final uniqueResults = <String, WiFiAccessPoint>{};
            for (var network in networks) {
              if (network.ssid.isNotEmpty) {
                uniqueResults[network.ssid] = network;
              }
            }

            _wifiNetworksList = uniqueResults.values.toList()
              ..sort((a, b) => b.level.compareTo(a.level));
          }
        }
      } else {
        printLog('No se puede iniciar el escaneo.');
      }
    } else {
      printLog('Permiso de ubicación denegado.');
    }
  } catch (e) {
    printLog('Error durante el escaneo de WiFi: $e');
  } finally {
    _scanInProgress = false;
  }

  return _wifiNetworksList;
}

void wifiText(BuildContext context) {
  showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          if (!_scanInProgress && _wifiNetworksList.isEmpty) {
            _fetchWiFiNetworks().then((wifiNetworks) {
              setState(() {
                _wifiNetworksList = wifiNetworks;
              });
            });
          }

          return AlertDialog(
            backgroundColor: const Color(0xff1f1d20),
            title: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text.rich(
                    TextSpan(
                      text: 'Estado de conexión: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: isWifiConnected ? 'Conectado' : 'Desconectado',
                      style: TextStyle(
                        color: isWifiConnected ? Colors.green : Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (werror) ...[
                    Text.rich(
                      TextSpan(
                        text: 'Error: $errorMessage',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text.rich(
                      TextSpan(
                        text: 'Sintax: $errorSintax',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      const Text.rich(
                        TextSpan(
                          text: 'Red actual: ',
                          style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFFFFFFFF),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        nameOfWifi,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFFFFFFFF),
                        ),
                      ),
                    ]),
                  ),
                  if (isWifiConnected) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        sendWifitoBle('DSC', 'DSC');
                        Navigator.of(context).pop();
                      },
                      style: const ButtonStyle(
                        foregroundColor: WidgetStatePropertyAll(
                          Color(0xFFFFFFFF),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Icon(Icons.signal_wifi_off),
                          Text('Desconectar Red Actual')
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _wifiNetworksList.isEmpty && _scanInProgress
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.maxFinite,
                          height: 200.0,
                          child: ListView.builder(
                            itemCount: _wifiNetworksList.length,
                            itemBuilder: (context, index) {
                              final network = _wifiNetworksList[index];
                              int nivel = network.level;
                              // printLog('${network.ssid}: $nivel dBm ');
                              return nivel >= -80
                                  ? SizedBox(
                                      child: ExpansionTile(
                                        initiallyExpanded:
                                            _expandedIndex == index,
                                        onExpansionChanged: (bool open) {
                                          if (open) {
                                            wifiPassNode.requestFocus();
                                            setState(() {
                                              _expandedIndex = index;
                                            });
                                          } else {
                                            setState(() {
                                              _expandedIndex = null;
                                            });
                                          }
                                        },
                                        leading: Icon(
                                          nivel >= -30
                                              ? Icons.signal_wifi_4_bar
                                              : // Excelente
                                              nivel >= -67
                                                  ? Icons.signal_wifi_4_bar
                                                  : // Muy buena
                                                  nivel >= -70
                                                      ? Icons.network_wifi_3_bar
                                                      : // Okay
                                                      nivel >= -80
                                                          ? Icons
                                                              .network_wifi_2_bar
                                                          : // No buena
                                                          Icons
                                                              .signal_wifi_off, // Inusable
                                          color: Colors.white,
                                        ),
                                        title: Text(
                                          network.ssid,
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                        backgroundColor:
                                            const Color(0xff1f1d20),
                                        collapsedBackgroundColor:
                                            const Color(0xff1f1d20),
                                        textColor: Colors.white,
                                        iconColor: Colors.white,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16.0,
                                                vertical: 8.0),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.lock,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8.0),
                                                Expanded(
                                                  child: TextField(
                                                    focusNode: wifiPassNode,
                                                    style: const TextStyle(
                                                      color: Color(0xFFFFFFFF),
                                                    ),
                                                    decoration:
                                                        const InputDecoration(
                                                      hintText:
                                                          'Escribir contraseña',
                                                      hintStyle: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                      enabledBorder:
                                                          UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color: Colors.blue),
                                                      ),
                                                      border:
                                                          UnderlineInputBorder(
                                                        borderSide: BorderSide(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                    ),
                                                    obscureText: true,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _currentlySelectedSSID =
                                                            network.ssid;
                                                        _wifiPasswordsMap[
                                                                network.ssid] =
                                                            value;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : null;
                            },
                          ),
                        ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.qr_code,
                      color: Color(0xFFFFFFFF),
                    ),
                    iconSize: 30,
                    onPressed: () async {
                      PermissionStatus permissionStatusC =
                          await Permission.camera.request();
                      if (!permissionStatusC.isGranted) {
                        await Permission.camera.request();
                      }
                      permissionStatusC = await Permission.camera.status;
                      if (permissionStatusC.isGranted) {
                        openQRScanner(navigatorKey.currentContext ?? context);
                      }
                    },
                  ),
                  TextButton(
                    style: const ButtonStyle(),
                    child: const Text(
                      'Conectar',
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    onPressed: () {
                      if (_currentlySelectedSSID != null &&
                          _wifiPasswordsMap[_currentlySelectedSSID] != null) {
                        printLog(
                            '$_currentlySelectedSSID#${_wifiPasswordsMap[_currentlySelectedSSID]}');
                        sendWifitoBle(_currentlySelectedSSID!,
                            _wifiPasswordsMap[_currentlySelectedSSID]!);
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  ).then((_) {
    _scanInProgress = false;
    _expandedIndex = null;
  });
}

//*-BACKGROUND-*//

Timer? backTimer;

Future<void> initializeService() async {
  try {
    final backService = FlutterBackgroundService();

    AndroidNotificationChannel channel = AndroidNotificationChannel(
        'my_foreground', 'Eventos',
        description: 'Notificaciones de eventos en $appName',
        importance: Importance.low,
        enableLights: true);

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isIOS || Platform.isAndroid) {
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(
          iOS: DarwinInitializationSettings(),
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
    }

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await backService.configure(
      iosConfiguration: IosConfiguration(
          onBackground: onStart, autoStart: true, onForeground: onStart),
      androidConfiguration: AndroidConfiguration(
        notificationChannelId: 'my_foreground',
        foregroundServiceNotificationId: 888,
        initialNotificationTitle: 'Eventos $appName',
        initialNotificationContent:
            'Utilizamos este servicio para ejecutar tareas en la app\nTal como el control por distancia, entre otras...',
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
      ),
    );
    printLog('Se inició piola');
  } catch (e, s) {
    printLog('Error al inicializar servicio $e');
    printLog('$s');
  }
}

@pragma('vm:entry-point')
bool onStart(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  setupMqtt();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('distanceControl').listen((event) {
    showNotification('Se inició el control por distancia',
        'Recuerde tener la ubicación del telefono encendida', null);
    backTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      await backFunction();
    });
  });

  return true;
}

Future<bool> backFunction() async {
  printLog('Entre a hacer locuritas. ${DateTime.now()}');
  // showNotification('Entre a la función', '${DateTime.now()}');
  try {
    List<String> devicesStored = await loadDevicesForDistanceControl();
    globalDATA = await loadGlobalData();
    Map<String, double> latitudes = await loadLatitude();
    Map<String, double> longitudes = await loadLongitud();

    for (int index = 0; index < devicesStored.length; index++) {
      String name = devicesStored[index];
      String productCode = command(name);
      String sn = extractSerialNumber(name);

      await queryItems(service, productCode, sn);

      double latitude = latitudes[name]!;
      double longitude = longitudes[name]!;

      double distanceOff =
          globalDATA['$productCode/$sn']?['distanceOff'] ?? 100.0;
      double distanceOn =
          globalDATA['$productCode/$sn']?['distanceOn'] ?? 3000.0;

      Position storedLocation = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        floor: 0,
        isMocked: false,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      printLog('Ubicación guardada $storedLocation');

      // showNotification('Ubicación guardada', '$storedLocation');

      Position currentPosition1 = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      printLog('$currentPosition1');

      double distance1 = Geolocator.distanceBetween(
        currentPosition1.latitude,
        currentPosition1.longitude,
        storedLocation.latitude,
        storedLocation.longitude,
      );
      printLog('Distancia 1 : $distance1 metros');

      // showNotification('Distancia 1', '$distance1 metros');

      if (distance1 > 100.0) {
        printLog('Esperando 30 segundos ${DateTime.now()}');

        // showNotification('Esperando 30 segundos', '${DateTime.now()}');

        await Future.delayed(const Duration(seconds: 30));

        Position currentPosition2 = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        printLog('$currentPosition2');

        double distance2 = Geolocator.distanceBetween(
          currentPosition2.latitude,
          currentPosition2.longitude,
          storedLocation.latitude,
          storedLocation.longitude,
        );
        printLog('Distancia 2 : $distance2 metros');

        // showNotification('Distancia 2', '$distance2 metros');

        if (distance2 <= distanceOn && distance1 > distance2) {
          printLog('Usuario cerca, encendiendo');

          showNotification('Encendimos el calefactor',
              'Te acercaste a menos de $distanceOn metros', null);

          globalDATA
              .putIfAbsent('$productCode/$sn', () => {})
              .addAll({"w_status": true});
          saveGlobalData(globalDATA);
          String topic = 'devices_rx/$productCode/$sn';
          String topic2 = 'devices_tx/$productCode/$sn';
          String message = jsonEncode({"w_status": true});
          sendMessagemqtt(topic, message);
          sendMessagemqtt(topic2, message);
          //Ta cerca prendo
        } else if (distance2 >= distanceOff && distance1 < distance2) {
          printLog('Usuario lejos, apagando');

          showNotification('Apagamos el calefactor',
              'Te alejaste a más de $distanceOff metros', null);

          globalDATA
              .putIfAbsent('$productCode/$sn', () => {})
              .addAll({"w_status": false});
          saveGlobalData(globalDATA);
          String topic = 'devices_rx/$productCode/$sn';
          String topic2 = 'devices_tx/$productCode/$sn';
          String message = jsonEncode({"w_status": false});
          sendMessagemqtt(topic, message);
          sendMessagemqtt(topic2, message);
          //Estas re lejos apago el calefactor
        } else {
          printLog('Ningun caso');

          // showNotification('No se cumplio ningún caso', 'No hicimos nada');
        }
      } else {
        printLog('Esta en home');
      }
    }

    return Future.value(true);
  } catch (e, s) {
    printLog('Error en segundo plano $e');
    printLog(s);

    // showNotification('Error en segundo plano $e', '$e');

    return Future.value(false);
  }
}

void showNotification(String title, String body, String? sonido) async {
  try {
    await flutterLocalNotificationsPlugin.show(
      888,
      title,
      body,
      NotificationDetails(
          android: AndroidNotificationDetails(
            'my_foreground',
            'Eventos',
            icon: '@mipmap/ic_launcher',
            sound: sonido != null
                ? RawResourceAndroidNotificationSound(sonido)
                : null,
            ongoing: false,
          ),
          iOS: const DarwinNotificationDetails()),
    );
  } catch (e, s) {
    printLog('Error enviando notif: $e');
    printLog(s);
  }
}

// CLASES //

//*-BLE-*//caracteristicas y servicios

class MyDevice {
  static final MyDevice _singleton = MyDevice._internal();

  factory MyDevice() {
    return _singleton;
  }

  MyDevice._internal();

  late BluetoothDevice device;
  late BluetoothCharacteristic infoUuid;

  late BluetoothCharacteristic toolsUuid;
  late BluetoothCharacteristic varsUuid;
  late BluetoothCharacteristic workUuid;
  late BluetoothCharacteristic lightUuid;
  late BluetoothCharacteristic ioUuid;

  Future<bool> setup(BluetoothDevice connectedDevice) async {
    try {
      device = connectedDevice;

      List<BluetoothService> services =
          await device.discoverServices(timeout: 3);
      // printLog('Los servicios: $services');

      BluetoothService infoService = services.firstWhere(
          (s) => s.uuid == Guid('6a3253b4-48bc-4e97-bacd-325a1d142038'));
      infoUuid = infoService.characteristics.firstWhere((c) =>
          c.uuid ==
          Guid(
              'fc5c01f9-18de-4a75-848b-d99a198da9be')); //ProductType:SerialNumber:SoftVer:HardVer:Owner
      toolsUuid = infoService.characteristics.firstWhere((c) =>
          c.uuid ==
          Guid(
              '89925840-3d11-4676-bf9b-62961456b570')); //WifiStatus:WifiSSID/WifiError:BleStatus(users)

      infoValues = await infoUuid.read();
      String str = utf8.decode(infoValues);
      var partes = str.split(':');
      var fun = partes[0].split('_');
      deviceType = fun[0];
      softwareVersion = partes[2];
      hardwareVersion = partes[3];
      printLog('Device: $deviceType');
      printLog('Product code: ${command(device.platformName)}');
      printLog('Serial number: ${extractSerialNumber(device.platformName)}');
      globalDATA.putIfAbsent(
          '${command(device.platformName)}/${extractSerialNumber(device.platformName)}',
          () => {});
      saveGlobalData(globalDATA);

      switch (deviceType) {
        case '022000':
          BluetoothService espService = services.firstWhere(
              (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));

          varsUuid = espService.characteristics.firstWhere((c) =>
              c.uuid ==
              Guid(
                  '52a2f121-a8e3-468c-a5de-45dca9a2a207')); //WorkingTemp:WorkingStatus:EnergyTimer:HeaterOn:NightMode
          break;
        case '027000':
          BluetoothService espService = services.firstWhere(
              (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));

          varsUuid = espService.characteristics.firstWhere((c) =>
              c.uuid ==
              Guid(
                  '52a2f121-a8e3-468c-a5de-45dca9a2a207')); //WorkingTemp:WorkingStatus:EnergyTimer:HeaterOn:NightMode
          break;
        case '041220':
          BluetoothService espService = services.firstWhere(
              (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));

          varsUuid = espService.characteristics.firstWhere((c) =>
              c.uuid ==
              Guid(
                  '52a2f121-a8e3-468c-a5de-45dca9a2a207')); //WorkingTemp:WorkingStatus:EnergyTimer:HeaterOn:NightMode
          break;
        case '015773':
          BluetoothService service = services.firstWhere(
              (s) => s.uuid == Guid('dd249079-0ce8-4d11-8aa9-53de4040aec6'));

          workUuid = service.characteristics.firstWhere((c) =>
              c.uuid ==
              Guid(
                  '6869fe94-c4a2-422a-ac41-b2a7a82803e9')); //Array de datos (ppm,etc)
          lightUuid = service.characteristics.firstWhere((c) =>
              c.uuid == Guid('12d3c6a1-f86e-4d5b-89b5-22dc3f5c831f')); //No leo

          break;
        case '020010':
          BluetoothService service = services.firstWhere(
              (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));
          ioUuid = service.characteristics.firstWhere(
              (c) => c.uuid == Guid('03b1c5d9-534a-4980-aed3-f59615205216'));
          break;
        case '030710':
          break;
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      printLog('Lcdtmbe $e $stackTrace');

      return Future.value(false);
    }
  }
}

//*-QRPAGE-*//solo scanQR

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});
  @override
  QRScanPageState createState() => QRScanPageState();
}

class QRScanPageState extends State<QRScanPage>
    with SingleTickerProviderStateMixin {
  Barcode? result;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController controller = MobileScannerController();
  AnimationController? animationController;
  bool flashOn = false;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    animation = Tween<double>(begin: 10, end: 350).animate(animationController!)
      ..addListener(() {
        setState(() {});
      });

    animationController!.repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        MobileScanner(
          controller: controller,
          onDetect: (
            barcode,
          ) {
            setState(() {
              result = barcode.barcodes.first;
            });
            if (result != null) {
              Navigator.pop(context, result!.rawValue);
            }
          },
        ),
        // Arriba
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 250,
          child: Container(
              color: Colors.black54,
              child: const Center(
                child: Text('Escanea el QR',
                    style: TextStyle(color: Color(0xFFB2B5AE))),
              )),
        ),
        // Abajo
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 250,
          child: Container(
            color: Colors.black54,
          ),
        ),
        // Izquierda
        Positioned(
          top: 250,
          bottom: 250,
          left: 0,
          width: 50,
          child: Container(
            color: Colors.black54,
          ),
        ),
        // Derecha
        Positioned(
          top: 250,
          bottom: 250,
          right: 0,
          width: 50,
          child: Container(
            color: Colors.black54,
          ),
        ),
        // Área transparente con bordes redondeados
        Positioned(
          top: 250,
          left: 50,
          right: 50,
          bottom: 250,
          child: Stack(
            children: [
              Positioned(
                top: animation.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  color: const Color(0xFF1E242B),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  color: const Color(0xFFB2B5AE),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  color: const Color(0xFFB2B5AE),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Container(
                  width: 3,
                  color: const Color(0xFFB2B5AE),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                child: Container(
                  width: 3,
                  color: const Color(0xFFB2B5AE),
                ),
              ),
            ],
          ),
        ),
        // Botón de Flash
        Positioned(
          bottom: 20,
          right: 20,
          child: IconButton(
            icon: Icon(
                controller.torchEnabled ? Icons.flash_on : Icons.flash_off),
            onPressed: () => controller.toggleTorch(),
          ),
        ),
      ]),
    );
  }
}

//*-DRAWER-*// Menu lateral

class MyDrawer extends StatefulWidget {
  final String userMail;
  const MyDrawer({super.key, required this.userMail});

  @override
  MyDrawerState createState() => MyDrawerState();
}

class MyDrawerState extends State<MyDrawer> {
  int fun = 0;
  int fun1 = 0;
  bool fun2 = false;

  @override
  void initState() {
    super.initState();
    for (String device in previusConnections) {
      queryItems(service, command(device), extractSerialNumber(device));
    }
  }

  void toggleState(String deviceName, bool newState) async {
    deviceSerialNumber = extractSerialNumber(deviceName);
    globalDATA['${command(deviceName)}/$deviceSerialNumber']!['w_status'] =
        newState;
    saveGlobalData(globalDATA);
    String topic = 'devices_rx/${command(deviceName)}/$deviceSerialNumber';
    String topic2 = 'devices_tx/${command(deviceName)}/$deviceSerialNumber';
    String message = jsonEncode({"w_status": newState});
    sendMessagemqtt(topic, message);
    sendMessagemqtt(topic2, message);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF141824),
      child: previusConnections.isEmpty
          ? ListView(
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Aún no se ha conectado a ningún equipo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB2B5AE),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              itemCount:
                  highlightedConnections.length + previusConnections.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  // El primer ítem será el DrawerHeader
                  return const DrawerHeader(
                      key: Key('drawerHeader'),
                      decoration: BoxDecoration(
                          // color: Colors.blue,
                          ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Mis equipos\nregistrados:',
                                style: TextStyle(
                                  color: Color(0xFFB2B5AE),
                                  fontSize: 24,
                                ),
                              ),
                              SizedBox(width: 80),
                              Icon(
                                Icons.wifi,
                                color: Color(0xFFB2B5AE),
                              )
                            ],
                          ),
                        ],
                      ));
                }

                bool isHighlighted = index <= highlightedConnections.length;

                String deviceName = isHighlighted
                    ? highlightedConnections[index - 1]
                    : previusConnections[
                        index - highlightedConnections.length - 1];

                return Consumer<GlobalDataNotifier>(
                  key: Key(deviceName),
                  builder: (context, notifier, child) {
                    String equipo = command(deviceName);
                    Map<String, dynamic> topicData = notifier
                        .getData('$equipo/${extractSerialNumber(deviceName)}');
                    globalDATA
                        .putIfAbsent(
                            '$equipo/${extractSerialNumber(deviceName)}',
                            () => {})
                        .addAll(topicData);
                    saveGlobalData(globalDATA);
                    Map<String, dynamic> deviceDATA = globalDATA[
                        '$equipo/${extractSerialNumber(deviceName)}']!;
                    printLog(deviceDATA);

                    bool online = deviceDATA['cstate'] ?? false;

                    List<dynamic> admins = deviceDATA['secondary_admin'] ?? [];

                    bool owner = deviceDATA['owner'] == currentUserEmail ||
                        admins.contains(deviceName) ||
                        deviceDATA['owner'] == '' ||
                        deviceDATA['owner'] == null;

                    if (equipo == '022000_IOT') {
                      bool estado = deviceDATA['w_status'] ?? false;
                      bool heaterOn = deviceDATA['f_status'] ?? false;
                      return Card(
                        color: const Color(0xFF1E242B),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        elevation: 2,
                        child: ListTile(
                          leading: SizedBox(
                            width: 40,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Color(0xFFB2B5AE),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isHighlighted) {
                                      highlightedConnections.remove(deviceName);
                                    } else {
                                      previusConnections.remove(deviceName);
                                    }
                                  });
                                  guardarLista(previusConnections);
                                  unSubToTopicMQTT(
                                      'devices_tx/$equipo/$deviceName');
                                },
                              ),
                            ),
                          ),
                          title: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          nicknamesMap[deviceName] ??
                                              deviceName,
                                          style: const TextStyle(
                                              color: Color(0xFFB2B5AE),
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: SizedBox(
                                            width: 20,
                                            child: IconButton(
                                              icon: Icon(
                                                size: 20,
                                                isHighlighted
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: isHighlighted
                                                    ? Colors.yellow
                                                    : Colors.grey,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (isHighlighted) {
                                                    highlightedConnections
                                                        .remove(deviceName);
                                                    previusConnections
                                                        .add(deviceName);
                                                  } else {
                                                    previusConnections
                                                        .remove(deviceName);
                                                    highlightedConnections
                                                        .add(deviceName);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                online
                                    ? const Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '● CONECTADO',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '● DESCONECTADO',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                              ]),
                          subtitle: estado
                              ? Row(
                                  children: [
                                    if (heaterOn) ...[
                                      Text('Calentando',
                                          style: TextStyle(
                                              color: Colors.amber[800],
                                              fontSize: 15)),
                                      Icon(Icons.flash_on_rounded,
                                          size: 15, color: Colors.amber[800])
                                    ] else ...[
                                      const Text('Encendido',
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 15)),
                                    ],
                                  ],
                                )
                              : const Text('Apagado',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 15)),
                          trailing: owner
                              ? Switch(
                                  activeColor: const Color(0xFF9C9D98),
                                  activeTrackColor: const Color(0xFFB2B5AE),
                                  inactiveThumbColor: const Color(0xFFB2B5AE),
                                  inactiveTrackColor: const Color(0xFF9C9D98),
                                  value: estado,
                                  onChanged: (newValue) {
                                    toggleState(deviceName, newValue);
                                    setState(() {
                                      estado = newValue;
                                    });
                                  },
                                )
                              : const SizedBox(
                                  height: 0,
                                  width: 0,
                                ),
                        ),
                      );
                    } else if (equipo == '027000_IOT') {
                      bool estado = deviceDATA['w_status'] ?? false;
                      bool heaterOn = deviceDATA['f_status'] ?? false;

                      return Card(
                        color: const Color(0xFF1E242B),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        elevation: 2,
                        child: ListTile(
                          leading: SizedBox(
                            width: 40,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Color(0xFFB2B5AE),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isHighlighted) {
                                      highlightedConnections.remove(deviceName);
                                    } else {
                                      previusConnections.remove(deviceName);
                                    }
                                  });
                                  guardarLista(previusConnections);
                                  unSubToTopicMQTT(
                                      'devices_tx/$equipo/$deviceName');
                                },
                              ),
                            ),
                          ),
                          title: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          nicknamesMap[deviceName] ??
                                              deviceName,
                                          style: const TextStyle(
                                              color: Color(0xFFB2B5AE),
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: SizedBox(
                                            width: 20,
                                            child: IconButton(
                                              icon: Icon(
                                                size: 20,
                                                isHighlighted
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: isHighlighted
                                                    ? Colors.yellow
                                                    : Colors.grey,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (isHighlighted) {
                                                    highlightedConnections
                                                        .remove(deviceName);
                                                    previusConnections
                                                        .add(deviceName);
                                                  } else {
                                                    previusConnections
                                                        .remove(deviceName);
                                                    highlightedConnections
                                                        .add(deviceName);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                online
                                    ? const Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '● CONECTADO',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '● DESCONECTADO',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                              ]),
                          subtitle: estado
                              ? Row(
                                  children: [
                                    if (heaterOn) ...[
                                      Text('Calentando',
                                          style: TextStyle(
                                              color: Colors.amber[800],
                                              fontSize: 15)),
                                      Icon(Icons.local_fire_department,
                                          size: 15, color: Colors.amber[800])
                                    ] else ...[
                                      const Text('Encendido',
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 15)),
                                    ],
                                  ],
                                )
                              : const Text('Apagado',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 15)),
                          trailing: owner
                              ? Switch(
                                  activeColor: const Color(0xFF9C9D98),
                                  activeTrackColor: const Color(0xFFB2B5AE),
                                  inactiveThumbColor: const Color(0xFFB2B5AE),
                                  inactiveTrackColor: const Color(0xFF9C9D98),
                                  value: estado,
                                  onChanged: (newValue) {
                                    toggleState(deviceName, newValue);
                                    setState(() {
                                      estado = newValue;
                                    });
                                  },
                                )
                              : const SizedBox(
                                  height: 0,
                                  width: 0,
                                ),
                        ),
                      );
                    } else if (equipo == '041220_IOT') {
                      bool estado = deviceDATA['w_status'] ?? false;
                      bool heaterOn = deviceDATA['f_status'] ?? false;

                      return Card(
                        color: const Color(0xFF1E242B),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        elevation: 2,
                        child: ListTile(
                          leading: SizedBox(
                            width: 40,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Color(0xFFB2B5AE),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isHighlighted) {
                                      highlightedConnections.remove(deviceName);
                                    } else {
                                      previusConnections.remove(deviceName);
                                    }
                                  });
                                  guardarLista(previusConnections);
                                  unSubToTopicMQTT(
                                      'devices_tx/$equipo/$deviceName');
                                },
                              ),
                            ),
                          ),
                          title: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          nicknamesMap[deviceName] ??
                                              deviceName,
                                          style: const TextStyle(
                                              color: Color(0xFFB2B5AE),
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: SizedBox(
                                            width: 20,
                                            child: IconButton(
                                              icon: Icon(
                                                size: 20,
                                                isHighlighted
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: isHighlighted
                                                    ? Colors.yellow
                                                    : Colors.grey,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (isHighlighted) {
                                                    highlightedConnections
                                                        .remove(deviceName);
                                                    previusConnections
                                                        .add(deviceName);
                                                  } else {
                                                    previusConnections
                                                        .remove(deviceName);
                                                    highlightedConnections
                                                        .add(deviceName);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                online
                                    ? const Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '● CONECTADO',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '● DESCONECTADO',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                              ]),
                          subtitle: estado
                              ? Row(
                                  children: [
                                    if (heaterOn) ...[
                                      Text('Calentando',
                                          style: TextStyle(
                                              color: Colors.amber[800],
                                              fontSize: 15)),
                                      Icon(Icons.flash_on_rounded,
                                          size: 15, color: Colors.amber[800])
                                    ] else ...[
                                      const Text('Encendido',
                                          style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 15)),
                                    ],
                                  ],
                                )
                              : const Text('Apagado',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 15)),
                          trailing: owner
                              ? Switch(
                                  activeColor: const Color(0xFF9C9D98),
                                  activeTrackColor: const Color(0xFFB2B5AE),
                                  inactiveThumbColor: const Color(0xFFB2B5AE),
                                  inactiveTrackColor: const Color(0xFF9C9D98),
                                  value: estado,
                                  onChanged: (newValue) {
                                    toggleState(deviceName, newValue);
                                    setState(() {
                                      estado = newValue;
                                    });
                                  },
                                )
                              : const SizedBox(
                                  height: 0,
                                  width: 0,
                                ),
                        ),
                      );
                    } else if (equipo == '015773_IOT') {
                      int ppmCO = deviceDATA['ppmco'] ?? 0;
                      int ppmCH4 = deviceDATA['ppmch4'] ?? 0;
                      bool alert = deviceDATA['alert'] == 1;
                      return Card(
                        color: const Color(0xFF1E242B),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        elevation: 2,
                        child: ListTile(
                          leading: SizedBox(
                            width: 40,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Color(0xFFB2B5AE),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isHighlighted) {
                                      highlightedConnections.remove(deviceName);
                                    } else {
                                      previusConnections.remove(deviceName);
                                    }
                                  });
                                  guardarLista(previusConnections);
                                  unSubToTopicMQTT(
                                      'devices_tx/$equipo/$deviceName');
                                },
                              ),
                            ),
                          ),
                          title: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          nicknamesMap[deviceName] ??
                                              deviceName,
                                          style: const TextStyle(
                                              color: Color(0xFFB2B5AE),
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: SizedBox(
                                            width: 20,
                                            child: IconButton(
                                              icon: Icon(
                                                size: 20,
                                                isHighlighted
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: isHighlighted
                                                    ? Colors.yellow
                                                    : Colors.grey,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (isHighlighted) {
                                                    highlightedConnections
                                                        .remove(deviceName);
                                                    previusConnections
                                                        .add(deviceName);
                                                  } else {
                                                    previusConnections
                                                        .remove(deviceName);
                                                    highlightedConnections
                                                        .add(deviceName);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                online
                                    ? const Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '● CONECTADO',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '● DESCONECTADO',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                              ]),
                          subtitle: Text.rich(
                            TextSpan(children: [
                              const TextSpan(
                                text: 'PPM CO: ',
                                style: TextStyle(
                                  color: Color(0xFF9C9D98),
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: '$ppmCO\n',
                                style: const TextStyle(
                                    color: Color(0xFF9C9D98),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text: 'CH4 LIE: ',
                                style: TextStyle(
                                  color: Color(0xFF9C9D98),
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: '${(ppmCH4 / 500).round()}%',
                                style: const TextStyle(
                                    color: Color(0xFF9C9D98),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                            ]),
                          ),
                          trailing: alert
                              ? const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                )
                              : null,
                        ),
                      );
                    } else if (equipo == '020010_IOT') {
                      String io =
                          '${deviceDATA['io0']}/${deviceDATA['io1']}/${deviceDATA['io2']}/${deviceDATA['io3']}';
                      var partes = io.split('/');
                      List<String> tipoDrawer = [];
                      List<bool> estadoDrawer = [];
                      List<String> comunDrawer = [];
                      for (int i = 0; i < partes.length; i++) {
                        var equipo = partes[i].split(':');
                        tipoDrawer.add(equipo[0] == '0' ? 'Salida' : 'Entrada');
                        estadoDrawer.add(equipo[1] == '1');
                        comunDrawer.add(equipo[2]);
                      }
                      return Card(
                        color: const Color(0xFF1E242B),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        elevation: 2,
                        child: ListTile(
                          leading: SizedBox(
                            width: 40,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Color(0xFFB2B5AE),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (isHighlighted) {
                                      highlightedConnections.remove(deviceName);
                                    } else {
                                      previusConnections.remove(deviceName);
                                    }
                                  });
                                  guardarLista(previusConnections);
                                  unSubToTopicMQTT(
                                      'devices_tx/$equipo/$deviceName');
                                },
                              ),
                            ),
                          ),
                          title: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: AlignmentDirectional.centerStart,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          nicknamesMap[deviceName] ??
                                              deviceName,
                                          style: const TextStyle(
                                              color: Color(0xFFB2B5AE),
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: SizedBox(
                                            width: 20,
                                            child: IconButton(
                                              icon: Icon(
                                                size: 20,
                                                isHighlighted
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: isHighlighted
                                                    ? Colors.yellow
                                                    : Colors.grey,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (isHighlighted) {
                                                    highlightedConnections
                                                        .remove(deviceName);
                                                    previusConnections
                                                        .add(deviceName);
                                                  } else {
                                                    previusConnections
                                                        .remove(deviceName);
                                                    highlightedConnections
                                                        .add(deviceName);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                online
                                    ? const Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '● CONECTADO',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : const Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Text(
                                                '● DESCONECTADO',
                                                textAlign: TextAlign.start,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                              ]),
                          subtitle: SizedBox(
                            height: 100,
                            child: PageView.builder(
                              physics: const PageScrollPhysics(
                                  parent: BouncingScrollPhysics()),
                              itemCount: partes.length,
                              itemBuilder: (context, i) {
                                bool entradaDrawer = tipoDrawer[i] == 'Entrada';
                                return ListTile(
                                  title: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          subNicknamesMap['$deviceName/-/$i'] ??
                                              '${tipoDrawer[i]} $i',
                                          style: const TextStyle(
                                              color: Color(0xFFB2B5AE),
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.start,
                                        ),
                                        const SizedBox(width: 5),
                                      ],
                                    ),
                                  ),
                                  subtitle: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Align(
                                            alignment: AlignmentDirectional
                                                .centerStart,
                                            child: Icon(
                                              i == 0
                                                  ? Icons.arrow_forward
                                                  : i == 1
                                                      ? Icons.compare_arrows
                                                      : i == 2
                                                          ? Icons.compare_arrows
                                                          : Icons.arrow_back,
                                              size: 30,
                                              color: const Color(0xFFB2B5AE),
                                            )),
                                        entradaDrawer
                                            ? estadoDrawer[i]
                                                ? comunDrawer[i] == '1'
                                                    ? const Align(
                                                        alignment:
                                                            AlignmentDirectional
                                                                .centerStart,
                                                        child: Text(
                                                          'Cerrado',
                                                          style: TextStyle(
                                                            color: Colors.green,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      )
                                                    : const Align(
                                                        alignment:
                                                            AlignmentDirectional
                                                                .centerStart,
                                                        child: Text(
                                                          'Abierto',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      )
                                                : comunDrawer[i] == '1'
                                                    ? const Align(
                                                        alignment:
                                                            AlignmentDirectional
                                                                .centerStart,
                                                        child: Text(
                                                          'Abierto',
                                                          style: TextStyle(
                                                            color: Colors.red,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      )
                                                    : const Align(
                                                        alignment:
                                                            AlignmentDirectional
                                                                .centerStart,
                                                        child: Text(
                                                          'Cerrado',
                                                          style: TextStyle(
                                                            color: Colors.green,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      )
                                            : estadoDrawer[i]
                                                ? const Align(
                                                    alignment:
                                                        AlignmentDirectional
                                                            .centerStart,
                                                    child: Text(
                                                      'Encendido',
                                                      style: TextStyle(
                                                        color: Colors.green,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  )
                                                : const Align(
                                                    alignment:
                                                        AlignmentDirectional
                                                            .centerStart,
                                                    child: Text(
                                                      'Apagado',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  )
                                      ],
                                    ),
                                  ),
                                  trailing: owner
                                      ? entradaDrawer
                                          ? estadoDrawer[i]
                                              ? comunDrawer[i] == '1'
                                                  ? const Icon(
                                                      Icons.new_releases,
                                                      color: Color(0xff9b9b9b),
                                                    )
                                                  : const Icon(
                                                      Icons.new_releases,
                                                      color: Color(0xffcb3234),
                                                    )
                                              : comunDrawer[i] == '1'
                                                  ? const Icon(
                                                      Icons.new_releases,
                                                      color: Color(0xffcb3234),
                                                    )
                                                  : const Icon(
                                                      Icons.new_releases,
                                                      color: Color(0xff9b9b9b),
                                                    )
                                          : Switch(
                                              activeColor:
                                                  const Color(0xFF9C9D98),
                                              activeTrackColor:
                                                  const Color(0xFFB2B5AE),
                                              inactiveThumbColor:
                                                  const Color(0xFFB2B5AE),
                                              inactiveTrackColor:
                                                  const Color(0xFF9C9D98),
                                              value: estadoDrawer[i],
                                              onChanged: (value) {
                                                String fun2 =
                                                    '${tipoDrawer[i] == 'Entrada' ? '1' : '0'}:${value ? '1' : '0'}:${comunDrawer[i]}';
                                                deviceSerialNumber =
                                                    extractSerialNumber(
                                                        deviceName);
                                                String topic =
                                                    'devices_rx/${command(deviceName)}/$deviceSerialNumber';
                                                String topic2 =
                                                    'devices_tx/${command(deviceName)}/$deviceSerialNumber';
                                                String message =
                                                    jsonEncode({'io$i': fun2});
                                                sendMessagemqtt(topic, message);
                                                sendMessagemqtt(
                                                    topic2, message);
                                                estadoDrawer[i] = value;
                                                for (int j = 0;
                                                    j < estadoDrawer.length;
                                                    j++) {
                                                  String device =
                                                      '${tipoDrawer[j] == 'Salida' ? '0' : '1'}:${estadoDrawer[j] == true ? '1' : '0'}:${comunDrawer[j]}';
                                                  globalDATA[
                                                          '${command(deviceName)}/$deviceSerialNumber']![
                                                      'io$j'] = device;
                                                }
                                                saveGlobalData(globalDATA);
                                              },
                                            )
                                      : null,
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    } else {
                      return const Text('Un error inesperado ha ocurrido');
                    }
                  },
                );
              },
            ),
    );
  }
}

//*-PROVIDER-*// Actualización de data

class GlobalDataNotifier extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _data = {};

  // Obtener datos por topic específico
  Map<String, dynamic> getData(String topic) {
    return _data[topic] ?? {};
  }

  // Actualizar datos para un topic específico y notificar a los oyentes
  void updateData(String topic, Map<String, dynamic> newData) {
    if (_data[topic] != newData) {
      _data[topic] = newData;
      notifyListeners(); // Esto notifica a todos los oyentes que algo cambió
    }
  }
}

//*-Slider-*//Cositas

class IconThumbSlider extends SliderComponentShape {
  final IconData iconData;
  final double thumbRadius;

  const IconThumbSlider({required this.iconData, required this.thumbRadius});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw the thumb as a circle
    final paint = Paint()
      ..color = sliderTheme.thumbColor!
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, thumbRadius, paint);

    // Draw the icon on the thumb
    TextSpan span = TextSpan(
      style: TextStyle(
        fontSize: thumbRadius,
        fontFamily: iconData.fontFamily,
        color: sliderTheme.valueIndicatorColor,
      ),
      text: String.fromCharCode(iconData.codePoint),
    );
    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr);
    tp.layout();
    Offset iconOffset = Offset(
      center.dx - (tp.width / 2),
      center.dy - (tp.height / 2),
    );
    tp.paint(canvas, iconOffset);
  }
}

//*-Nativo-*//Servicio

class NativeService {
  static const platform = MethodChannel('com.biocalden.smartlife.sime/native');

  static Future<bool> isLocationServiceEnabled() async {
    try {
      final bool isEnabled =
          await platform.invokeMethod("isLocationServiceEnabled");
      return isEnabled;
    } on PlatformException catch (e) {
      printLog('Error verificando ubicación: $e');
      return false;
    }
  }

  static Future<void> openLocationOptions() async {
    try {
      await platform.invokeMethod("openLocationSettings");
    } on PlatformException catch (e) {
      printLog('Error abriendo la configuración de ubicación: $e');
    }
  }

  static Future<String?> getApnsToken() async {
    try {
      final String? token = await platform.invokeMethod('onTokenReceived');
      printLog('APNs Token: $token');
      return token;
    } on PlatformException catch (e) {
      printLog('Error al obtener el token APNs: ${e.message}');
      return null;
    }
  }
}
