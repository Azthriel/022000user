import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:amplify_flutter/amplify_flutter.dart';
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
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

//!-----DATA MASTER-----!\\
Map<String, Map<String, dynamic>> globalDATA = {};
//!-----DATA MASTER-----!\\
final dio = Dio();
List<String> topicsToSub = [];
Map<String, String> productCode = {};
List<String> ownedDevices = [];
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
String wifiName = '';
String wifiPassword = '';
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
Map<String, String> nicknamesMap = {};
Map<String, String> subNicknamesMap = {};
String deviceType = '';
String softwareVersion = '';
String hardwareVersion = '';
String actualToken = '';
String actualIOToken = '';
String currentUserEmail = '';
String deviceSerialNumber = '';
late String appName;
Map<String, List<bool>> notificationMap = {};
bool werror = false;
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Si esta en modo profile.
const bool xProfileMode = bool.fromEnvironment('dart.vm.profile');
// Si esta en modo release.
const bool xReleaseMode = bool.fromEnvironment('dart.vm.product');
// Determina si la app esta en debug.
const bool xDebugMode = !xProfileMode && !xReleaseMode;

//!------------------------------VERSION NUMBER---------------------------------------

String appVersionNumber = '24051501';
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
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      textColor: const Color.fromARGB(255, 0, 0, 0),
      fontSize: 16.0);
}

Future<void> sendWifitoBle() async {
  MyDevice myDevice = MyDevice();
  String value = '$wifiName#$wifiPassword';
  String deviceCommand = command(deviceType);
  printLog(deviceCommand);
  String dataToSend = '$deviceCommand[1]($value)';
  printLog(dataToSend);
  try {
    await myDevice.toolsUuid.write(dataToSend.codeUnits);
    printLog('Se mando el wifi ANASHE');
  } catch (e) {
    printLog('Error al conectarse a Wifi $e');
  }
  atemp = true;
  wifiName = '';
  wifiPassword = '';
}

String command(String device) {
  // printLog('Entro $device');
  switch (device) {
    case '022000':
      return '022000_IOT';
    case '027000':
      return '027000_IOT';
    case '015773':
      return '015773_IOT';
    case '041220':
      return '041220_IOT';
    case '020010':
      return '020010_IOT';
    default:
      return '';
  }
}

String generateErrorReport(FlutterErrorDetails details) {
  return '''
Error: ${details.exception}
Stacktrace: ${details.stack}
  ''';
}

void sendReportError(String cuerpo) async {
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
          backgroundColor: const Color.fromARGB(255, 37, 34, 35),
          title: const Text(
            'Bluetooth apagado',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          content: const Text(
            'No se puede continuar sin Bluetooth',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          actions: [
            TextButton(
              style: const ButtonStyle(
                  foregroundColor: MaterialStatePropertyAll(
                      Color.fromARGB(255, 255, 255, 255))),
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
  bool status = await Geolocator.isLocationServiceEnabled();
  // print(status);
  if (!status) {
    showUbiText();
  }
}

void showUbiText() {
  if (!checkubiFlag) {
    checkubiFlag = true;
    showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 37, 34, 35),
            title: const Text(
              'Ubicación apagada',
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            ),
            content: const Text(
              'No se puede continuar sin la ubicación',
              style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            ),
            actions: [
              TextButton(
                  style: const ButtonStyle(
                      foregroundColor: MaterialStatePropertyAll(
                          Color.fromARGB(255, 255, 255, 255))),
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

void showPrivacyDialogIfNeeded() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool hasShownDialog = prefs.getBool('hasShownDialog') ?? false;

  if (!hasShownDialog) {
    await showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 37, 34, 35),
          title: const Text(
            'Política de Privacidad',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'En $appName,  valoramos tu privacidad y seguridad. Queremos asegurarte que nuestra aplicación está diseñada con el respeto a tu privacidad personal. Aquí hay algunos puntos clave que debes conocer:\nNo Recopilamos Información Personal: Nuestra aplicación no recopila ni almacena ningún tipo de información personal de nuestros usuarios. Puedes usar nuestra aplicación con la tranquilidad de que tu privacidad está protegida.\nUso de Permisos: Aunque nuestra aplicación solicita ciertos permisos, como el acceso a la cámara, estos se utilizan exclusivamente para el funcionamiento de la aplicación y no para recopilar datos personales.\nPolítica de Privacidad Detallada: Si deseas obtener más información sobre nuestra política de privacidad, te invitamos a visitar nuestra página web. Allí encontrarás una explicación detallada de nuestras prácticas de privacidad.\nPara continuar y disfrutar de todas las funcionalidades de $appName, por favor, acepta nuestra política de privacidad.',
                  style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255)),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: const ButtonStyle(
                  foregroundColor: MaterialStatePropertyAll(
                      Color.fromARGB(255, 255, 255, 255))),
              child: const Text('Leer nuestra politica de privacidad'),
              onPressed: () async {
                Uri uri = Uri.parse(biocalden
                    ? 'https://calefactorescalden.com.ar/privacidad/'
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
                  foregroundColor: MaterialStatePropertyAll(
                      Color.fromARGB(255, 255, 255, 255))),
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
        wifiName = wifiData['SSID']!;
        wifiPassword = wifiData['password']!;
        sendWifitoBle();
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
            // backgroundColor: const Color.fromARGB(255, 230, 254, 255),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              const Text('Contacto comercial:',
                  style: TextStyle(
                      // color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: () => _sendWhatsAppMessage('5491162234181',
                          '¡Hola! Tengo una duda comercial sobre los productos $appName: \n'),
                      icon: const Icon(
                        Icons.phone,
                        // color: Color.fromARGB(255, 29, 163, 169),
                        size: 20,
                      )),
                  // const SizedBox(width: 5),
                  const Text('+54 9 11 6223-4181',
                      style: TextStyle(
                          // color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 20))
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
                          // color: Color.fromARGB(255, 29, 163, 169),
                          size: 20,
                        ),
                      ),
                      // const SizedBox(width: 5),
                      const Text('ceat@ibsanitarios.com.ar',
                          style: TextStyle(
                              // color: Color.fromARGB(255, 0, 0, 0),
                              fontSize: 20))
                    ],
                  )),
              const SizedBox(height: 20),
              const Text('Consulta técnica:',
                  style: TextStyle(
                      // color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => _launchEmail(
                          'pablo@intelligentgas.com.ar',
                          'Consulta ref. $deviceName',
                          '¡Hola! Tengo una consulta referida al área de ingenieria sobre mi equipo.\n Información del mismo:\nModelo: ${productCode[deviceName]}\nVersión de software: $softwareVersion \nVersión de hardware: $hardwareVersion \nMi duda es la siguiente:\n'),
                      icon: const Icon(
                        Icons.mail,
                        // color: Color.fromARGB(255, 29, 163, 169),
                        size: 20,
                      ),
                    ),
                    // const SizedBox(width: 5),
                    const Text(
                      'pablo@intelligentgas.com.ar',
                      style: TextStyle(
                          // color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 20),
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Customer service:',
                  style: TextStyle(
                      // color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                      onPressed: () => _sendWhatsAppMessage('5491162232619',
                          '¡Hola! Te hablo por una duda sobre mi equipo $deviceName: \n'),
                      icon: const Icon(
                        Icons.phone,
                        // color: Color.fromARGB(255, 29, 163, 169),
                        size: 20,
                      )),
                  // const SizedBox(width: 5),
                  const Text('+54 9 11 6223-2619',
                      style: TextStyle(
                          // color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 20))
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
                            'Consulta ${productCode[deviceName]}',
                            'Tengo una consulta referida a mi equipo $deviceName: \n'),
                        icon: const Icon(
                          Icons.mail,
                          // color: Color.fromARGB(255, 29, 163, 169),
                          size: 20,
                        ),
                      ),
                      // const SizedBox(width: 5),
                      const Text(
                        'service@calefactorescalden.com.ar',
                        style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  )),
            ]));
      });
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

void setupToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  String? tokenToSend = '$token/-/${nicknamesMap[deviceName] ?? deviceName}';

  if (token != null) {
    if (actualToken != tokenToSend) {
      await removeTokenFromDatabase(actualToken, deviceName);
      actualToken = tokenToSend;
      saveToken(actualToken);
      saveTokenToDatabase(tokenToSend, deviceName);
    } else {
      printLog('Token ya agregado...');
    }
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    String? newtokenToSend =
        '$newToken/-/${nicknamesMap[deviceName] ?? deviceName}';

    if (actualToken != '') {
      await removeTokenFromDatabase(actualToken, deviceName);
    }
    actualToken = newtokenToSend;
    saveTokenToDatabase(newtokenToSend, deviceName);
  });
}

void saveTokenToDatabase(String token, String device) async {
  printLog("Voy a mandar: $token");
  const url =
      'https://ymuvhra8ve.execute-api.sa-east-1.amazonaws.com/final/saveToken';
  final response = await dio.post(
    url,
    data: json.encode(
      {
        'productCode': productCode[device],
        'serialNumber': extractSerialNumber(device),
        'token': token,
      },
    ),
  );

  if (response.statusCode == 200) {
    // Handle success
    printLog('Token added successfully');
  } else {
    // Handle failure
    printLog('Failed to add token');
    printLog(response);
    printLog(response.data.toString());
  }
}

Future<void> removeTokenFromDatabase(String token, String device) async {
  printLog('Borrando esto: $token');
  actualToken = '';
  const url =
      'https://ymuvhra8ve.execute-api.sa-east-1.amazonaws.com/final/removeToken';
  final response = await dio.post(
    url,
    data: json.encode(
      {
        'productCode': productCode[device],
        'serialNumber': extractSerialNumber(device),
        'token': token,
      },
    ),
  );
  if (response.statusCode == 200) {
    // Handle success
    printLog('Token removed successfully');
  } else {
    // Handle failure
    printLog('Failed to removed token');
    printLog(response.data);
  }
}

void requestPermissionFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    provisional: false,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    printLog('User granted permission');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    printLog('User granted provisional permission');
  } else {
    printLog('User declined or has not accepted permission');
  }
}

void setupIOToken(String nick, int index) async {
  String? token = await FirebaseMessaging.instance.getToken();
  String? tokenToSend = '$token/-/$nick';

  if (token != null) {
    if (actualIOToken != tokenToSend) {
      await removeIOTokenFromDatabase(
          actualIOToken, deviceName, index.toString());
      actualIOToken = tokenToSend;
      saveTokenIO(actualIOToken);
      saveIOTokenToDatabase(tokenToSend, deviceName, index.toString());
    } else {
      printLog('ioToken ya existente...');
    }
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    String? newtokenToSend = '$newToken/-/$nick/-/$index';

    if (actualIOToken != '') {
      await removeIOTokenFromDatabase(
          actualIOToken, deviceName, index.toString());
    }
    actualIOToken = newtokenToSend;
    saveIOTokenToDatabase(newtokenToSend, deviceName, index.toString());
  });
}

void saveIOTokenToDatabase(String token, String device, String entry) async {
  printLog("Voy a mandar: $token");
  const url =
      'https://ymuvhra8ve.execute-api.sa-east-1.amazonaws.com/final/saveTokenIO';
  final response = await dio.post(
    url,
    data: json.encode(
      {
        'productCode': productCode[device],
        'serialNumber': extractSerialNumber(device),
        'token': token,
        'entry': entry,
      },
    ),
  );

  if (response.statusCode == 200) {
    // Handle success
    printLog('Token added successfully');
  } else {
    // Handle failure
    printLog('Failed to add token');
    printLog(response);
    printLog(response.data);
  }
}

Future<void> removeIOTokenFromDatabase(
    String token, String device, String entry) async {
  printLog('Borrando esto: $token');
  actualIOToken = '';
  const url =
      'https://ymuvhra8ve.execute-api.sa-east-1.amazonaws.com/final/removeTokenIO';
  final response = await dio.post(
    url,
    data: json.encode(
      {
        'productCode': productCode[device],
        'serialNumber': extractSerialNumber(device),
        'token': token,
        'entry': entry,
      },
    ),
  );
  if (response.statusCode == 200) {
    // Handle success
    printLog('Token removed successfully');
  } else {
    // Handle failure
    printLog('Failed to removed token');
    printLog(response.data);
  }
}

void wifiText(BuildContext context) {
  showDialog(
    barrierDismissible: true,
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xff1f1d20),
        title: Row(
          children: [
            const Text.rich(
              TextSpan(
                text: 'Estado de conexión: ',
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
            Text.rich(
              TextSpan(
                text: textState,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            )
          ],
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
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: 'Sintax: $errorSintax',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color.fromARGB(255, 255, 255, 255),
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
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    nameOfWifi,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 10),
              const Text.rich(
                TextSpan(
                  text: 'Ingrese los datos de WiFi',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.qr_code,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                iconSize: 50,
                onPressed: () async {
                  PermissionStatus permissionStatusC =
                      await Permission.camera.request();
                  if (!permissionStatusC.isGranted) {
                    await Permission.camera.request();
                  }
                  permissionStatusC = await Permission.camera.status;
                  if (permissionStatusC.isGranted) {
                    openQRScanner(navigatorKey.currentContext!);
                  }
                },
              ),
              TextField(
                style: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                decoration: const InputDecoration(
                  hintText: 'Nombre de la red',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(),
                  ),
                ),
                onChanged: (value) {
                  wifiName = value;
                },
              ),
              TextField(
                style: const TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                decoration: const InputDecoration(
                  hintText: 'Contraseña',
                  hintStyle: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(),
                  ),
                ),
                obscureText: true,
                onChanged: (value) {
                  wifiPassword = value;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: const ButtonStyle(),
            child: const Text(
              'Aceptar',
              style: TextStyle(
                color: Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            onPressed: () {
              sendWifitoBle();
              navigatorKey.currentState?.pop();
            },
          ),
        ],
      );
    },
  );
}

//BACKGROUND //

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
      iosConfiguration:
          IosConfiguration(onBackground: onStart, autoStart: true),
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

  setupMqtt();

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('distanceControl').listen((event) {
    showNotification('Se inició el control por distancia',
        'Recuerde tener la ubicación del telefono encendida');
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
    Map<String, String> products = await loadProductCodesMap();
    globalDATA = await loadGlobalData();
    Map<String, double> latitudes = await loadLatitude();
    Map<String, double> longitudes = await loadLongitud();
    Map<String, double> distancesOn = await loadDistanceON();
    Map<String, double> distancesOff = await loadDistanceOFF();

    for (int index = 0; index < devicesStored.length; index++) {
      String name = devicesStored[index];
      String productCode = products[name]!;
      String sn = extractSerialNumber(name);

      double latitude = latitudes[name]!;
      double longitude = longitudes[name]!;
      double distanceOn = distancesOn[name] ?? 3000.0;
      double distanceOff = distancesOff[name] ?? 100.0;

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
              'Te acercaste a menos de $distanceOn metros');

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
              'Te alejaste a más de $distanceOff metros');

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

void showNotification(String title, String body) async {
  try {
    await flutterLocalNotificationsPlugin.show(
      888,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'my_foreground',
          'Eventos',
          icon: '@mipmap/ic_launcher',
          ongoing: false,
        ),
      ),
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
      printLog('Los servicios: $services');

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
      productCode[device.platformName] = partes[0];
      saveProductCodesMap(productCode);
      softwareVersion = partes[2];
      hardwareVersion = partes[3];
      printLog('Device: $deviceType');
      printLog('Product code: ${productCode[device.platformName]}');
      printLog('Serial number: ${extractSerialNumber(device.platformName)}');
      globalDATA.putIfAbsent(
          '${productCode[device.platformName]}/${extractSerialNumber(device.platformName)}',
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
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
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
                      style:
                          TextStyle(color: Color.fromARGB(255, 178, 181, 174))),
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
                    color: const Color.fromARGB(255, 30, 36, 43),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    color: const Color.fromARGB(255, 178, 181, 174),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    color: const Color.fromARGB(255, 178, 181, 174),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 3,
                    color: const Color.fromARGB(255, 178, 181, 174),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 3,
                    color: const Color.fromARGB(255, 178, 181, 174),
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
                flashOn ? Icons.flash_on : Icons.flash_off,
                color: Colors.white,
              ),
              onPressed: () {
                controller?.toggleFlash();
                setState(() {
                  flashOn = !flashOn;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      Future.delayed(const Duration(milliseconds: 800), () {
        try {
          if (navigatorKey.currentState != null &&
              navigatorKey.currentState!.canPop()) {
            navigatorKey.currentState!.pop(scanData.code);
          }
        } catch (e, stackTrace) {
          printLog("Error: $e $stackTrace");
          showToast('Error al leer QR');
        }
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    animationController?.dispose();
    super.dispose();
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

  void toggleState(String deviceName, bool newState) async {
    // Función para cambiar el estado
    deviceSerialNumber = extractSerialNumber(deviceName);
    globalDATA['${productCode[deviceName]}/$deviceSerialNumber']!['w_status'] =
        newState;
    saveGlobalData(globalDATA);
    String topic = 'devices_rx/${productCode[deviceName]}/$deviceSerialNumber';
    String topic2 = 'devices_tx/${productCode[deviceName]}/$deviceSerialNumber';
    String message = jsonEncode({"w_status": newState});
    sendMessagemqtt(topic, message);
    sendMessagemqtt(topic2, message);
    printLog(globalDATA['${productCode[deviceName]}/$deviceSerialNumber']);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 30, 36, 43),
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
                          color: Color.fromARGB(255, 178, 181, 174),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              itemCount: previusConnections.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  // El primer ítem será el DrawerHeader
                  return const DrawerHeader(
                      decoration: BoxDecoration(
                          // color: Colors.blue,
                          ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Mis equipos\nregistrados:',
                              style: TextStyle(
                                color: Color.fromARGB(255, 178, 181, 174),
                                fontSize: 24,
                              ),
                            ),
                            SizedBox(width: 80),
                            Icon(Icons.wifi,
                                color: Color.fromARGB(
                                    255, 178, 181, 174)) //(255, 156, 157, 152)
                          ]));
                }

                String deviceName = previusConnections[index - 1];
                return Consumer<GlobalDataNotifier>(
                  builder: (context, notifier, child) {
                    String equipo = productCode[deviceName] ?? 'Error';
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
                    if (equipo == '022000_IOT') {
                      bool estado = deviceDATA['w_status'] ?? false;
                      bool heaterOn = deviceDATA['f_status'] ?? false;
                      bool owner = ownedDevices.contains(deviceName);
                      return ListTile(
                          leading: SizedBox(
                            width: 20,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Color.fromARGB(255, 156, 157, 152),
                                  size: 20,
                                ),
                                onPressed: () {
                                  printLog('Eliminando de la lista');
                                  setState(() {
                                    previusConnections.removeAt(index - 1);
                                  });
                                  guardarLista(previusConnections);
                                  unSubToTopicMQTT(
                                      'devices_tx/$equipo/$deviceName');
                                },
                              ),
                            ),
                          ),
                          title: Text(nicknamesMap[deviceName] ?? deviceName,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 178, 181, 174),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
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
                                  activeColor:
                                      const Color.fromARGB(255, 156, 157, 152),
                                  activeTrackColor:
                                      const Color.fromARGB(255, 178, 181, 174),
                                  inactiveThumbColor:
                                      const Color.fromARGB(255, 178, 181, 174),
                                  inactiveTrackColor:
                                      const Color.fromARGB(255, 156, 157, 152),
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
                                ));
                    } else if (equipo == '027000_IOT') {
                      bool estado = deviceDATA['w_status'] ?? false;
                      bool heaterOn = deviceDATA['f_status'] ?? false;
                      bool owner = ownedDevices.contains(deviceName);
                      return ListTile(
                          leading: SizedBox(
                            width: 20,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Color.fromARGB(255, 156, 157, 152),
                                  size: 20,
                                ),
                                onPressed: () {
                                  printLog('Eliminando de la lista');
                                  setState(() {
                                    previusConnections.removeAt(index - 1);
                                  });
                                  guardarLista(previusConnections);
                                  unSubToTopicMQTT(
                                      'devices_tx/$equipo/$deviceName');
                                },
                              ),
                            ),
                          ),
                          title: Text(nicknamesMap[deviceName] ?? deviceName,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 178, 181, 174),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
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
                                  activeColor:
                                      const Color.fromARGB(255, 156, 157, 152),
                                  activeTrackColor:
                                      const Color.fromARGB(255, 178, 181, 174),
                                  inactiveThumbColor:
                                      const Color.fromARGB(255, 178, 181, 174),
                                  inactiveTrackColor:
                                      const Color.fromARGB(255, 156, 157, 152),
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
                                ));
                    } else if (equipo == '041220_IOT') {
                      bool estado = deviceDATA['w_status'] ?? false;
                      bool heaterOn = deviceDATA['f_status'] ?? false;
                      bool owner = ownedDevices.contains(deviceName);
                      return ListTile(
                          leading: SizedBox(
                            width: 20,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Color.fromARGB(255, 156, 157, 152),
                                  size: 20,
                                ),
                                onPressed: () {
                                  printLog('Eliminando de la lista');
                                  setState(() {
                                    previusConnections.removeAt(index - 1);
                                  });
                                  guardarLista(previusConnections);
                                  unSubToTopicMQTT(
                                      'devices_tx/$equipo/$deviceName');
                                },
                              ),
                            ),
                          ),
                          title: Text(nicknamesMap[deviceName] ?? deviceName,
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 178, 181, 174),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
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
                                  activeColor:
                                      const Color.fromARGB(255, 156, 157, 152),
                                  activeTrackColor:
                                      const Color.fromARGB(255, 178, 181, 174),
                                  inactiveThumbColor:
                                      const Color.fromARGB(255, 178, 181, 174),
                                  inactiveTrackColor:
                                      const Color.fromARGB(255, 156, 157, 152),
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
                                ));
                    } else if (equipo == '015773_IOT') {
                      int ppmCO = deviceDATA['ppmco'] ?? 0;
                      int ppmCH4 = deviceDATA['ppmch4'] ?? 0;
                      bool alert = deviceDATA['alert'] == 1;
                      return ListTile(
                        leading: SizedBox(
                          width: 20,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Color.fromARGB(255, 156, 157, 152),
                                size: 20,
                              ),
                              onPressed: () {
                                printLog('Eliminando de la lista');
                                setState(() {
                                  previusConnections.removeAt(index - 1);
                                });
                                guardarLista(previusConnections);
                                unSubToTopicMQTT(
                                    'devices_tx/$equipo/$deviceName');
                                removeTokenFromDatabase(
                                    actualToken, deviceName);
                              },
                            ),
                          ),
                        ),
                        title: Text(nicknamesMap[deviceName] ?? deviceName,
                            style: const TextStyle(
                                color: Color.fromARGB(255, 178, 181, 174),
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text.rich(
                          TextSpan(children: [
                            const TextSpan(
                              text: 'PPM CO: ',
                              style: TextStyle(
                                color: Color.fromARGB(255, 156, 157, 152),
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: '$ppmCO\n',
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 156, 157, 152),
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(
                              text: 'CH4 LIE: ',
                              style: TextStyle(
                                color: Color.fromARGB(255, 156, 157, 152),
                                fontSize: 15,
                              ),
                            ),
                            TextSpan(
                              text: '${(ppmCH4 / 500).round()}%',
                              style: const TextStyle(
                                  color: Color.fromARGB(255, 156, 157, 152),
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
                      );
                    } else if (equipo == '020010_IOT') {
                      String io =
                          '${deviceDATA['io0']}/${deviceDATA['io1']}/${deviceDATA['io2']}/${deviceDATA['io3']}';
                      var partes = io.split('/');
                      List<String> tipoDrawer = [];
                      List<bool> estadoDrawer = [];
                      for (int i = 0; i < partes.length; i++) {
                        var equipo = partes[i].split(':');
                        tipoDrawer.add(equipo[0] == '0' ? 'Salida' : 'Entrada');
                        estadoDrawer.add(equipo[1] == '1');
                      }
                      return ListTile(
                        leading: SizedBox(
                          width: 20,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Color.fromARGB(255, 156, 157, 152),
                                size: 20,
                              ),
                              onPressed: () {
                                printLog('Eliminando de la lista');
                                setState(() {
                                  previusConnections.removeAt(index - 1);
                                });
                                guardarLista(previusConnections);
                                unSubToTopicMQTT(
                                    'devices_tx/$equipo/$deviceName');
                                removeTokenFromDatabase(
                                    actualToken, deviceName);
                              },
                            ),
                          ),
                        ),
                        title: Text(nicknamesMap[deviceName] ?? deviceName,
                            style: const TextStyle(
                                color: Color.fromARGB(255, 178, 181, 174),
                                fontSize: 15,
                                fontWeight: FontWeight.bold)),
                        subtitle: SizedBox(
                            height: 80,
                            child: PageView.builder(
                              physics: const PageScrollPhysics(
                                  parent: BouncingScrollPhysics()),
                              itemCount: partes.length,
                              itemBuilder: (context, index) {
                                bool entradaDrawer =
                                    tipoDrawer[index] == 'Entrada';
                                return ListTile(
                                  title: Text(
                                    subNicknamesMap['$deviceName/-/$index'] ??
                                        '${tipoDrawer[index]} ${index + 1}',
                                    style: const TextStyle(
                                        color:
                                            Color.fromARGB(255, 178, 181, 174),
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.start,
                                  ),
                                  subtitle: entradaDrawer
                                      ? estadoDrawer[index]
                                          ? const Text('Cerrado',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 15))
                                          : const Text('Abierto',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 15))
                                      : estadoDrawer[index]
                                          ? const Text('Encendido',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 15))
                                          : const Text('Apagado',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontSize: 15)),
                                  trailing: entradaDrawer
                                      ? estadoDrawer[index]
                                          ? const Icon(
                                              Icons.new_releases,
                                              color: Color(0xff9b9b9b),
                                            )
                                          : const Icon(
                                              Icons.new_releases,
                                              color: Color(0xffcb3234),
                                            )
                                      : Switch(
                                          activeColor: const Color.fromARGB(
                                              255, 156, 157, 152),
                                          activeTrackColor:
                                              const Color.fromARGB(
                                                  255, 178, 181, 174),
                                          inactiveThumbColor:
                                              const Color.fromARGB(
                                                  255, 178, 181, 174),
                                          inactiveTrackColor:
                                              const Color.fromARGB(
                                                  255, 156, 157, 152),
                                          value: estadoDrawer[index],
                                          onChanged: (value) {
                                            String fun2 =
                                                '$index:${value ? '1' : '0'}';
                                            deviceSerialNumber =
                                                extractSerialNumber(deviceName);
                                            String topic =
                                                'devices_rx/${productCode[deviceName]}/$deviceSerialNumber';
                                            String topic2 =
                                                'devices_tx/${productCode[deviceName]}/$deviceSerialNumber';
                                            String message =
                                                jsonEncode({'io$index': fun2});
                                            sendMessagemqtt(topic, message);
                                            estadoDrawer[index] = value;
                                            for (int i = 0;
                                                i < estadoDrawer.length;
                                                i++) {
                                              String device =
                                                  '${tipoDrawer[i] == 'Salida' ? '0' : '1'}:${estadoDrawer[i] == true ? '1' : '0'}';
                                              globalDATA[
                                                      '${productCode[deviceName]}/$deviceSerialNumber']![
                                                  'io$i'] = device;
                                            }

                                            saveGlobalData(globalDATA);
                                            String message2 = jsonEncode(globalDATA[
                                                '${productCode[deviceName]}/$deviceSerialNumber']);
                                            sendMessagemqtt(topic2, message2);
                                          },
                                        ),
                                );
                              },
                            )),
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
