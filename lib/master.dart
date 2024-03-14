import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

//!-----DATA MASTER-----!\\
Map<String,Map<String,dynamic>> globalDATA = {};
//!-----DATA MASTER-----!\\
MyDevice myDevice = MyDevice();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
List<int> infoValues = [];
List<int> toolsValues = [];
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
late bool nightMode;
int lastUser = 0;
List<String> previusConnections = [];
Map<String, String> nicknamesMap = {};
String deviceType = '';
String softwareVersion = '';
String hardwareVersion = '';
String actualToken = '';
String currentUserEmail = '';

// Si esta en modo profile.
const bool xProfileMode = bool.fromEnvironment('dart.vm.profile');
// Si esta en modo release.
const bool xReleaseMode = bool.fromEnvironment('dart.vm.product');
// Determina si la app esta en debug.
const bool xDebugMode = !xProfileMode && !xReleaseMode;

//!------------------------------VERSION NUMBER---------------------------------------

String appVersionNumber = '24030600';
//ACORDATE: Cambia el número de versión en el pubspec.yaml antes de publicar

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
  printLog('Entro $device');
  switch (device) {
    case '022000':
      return '022000_IOT';
    case '027000':
      return '027000_IOT';
    case '015773':
      return '015773_IOT';
    case '041220':
      return '041220_IOT';
    default:
      return '';
  }
}

void loadValues() async {
  actualToken = await loadOldToken();
  previusConnections = await cargarLista();
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
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'En calefactor Smart,  valoramos tu privacidad y seguridad. Queremos asegurarte que nuestra aplicación está diseñada con el respeto a tu privacidad personal. Aquí hay algunos puntos clave que debes conocer:\nNo Recopilamos Información Personal: Nuestra aplicación no recopila ni almacena ningún tipo de información personal de nuestros usuarios. Puedes usar nuestra aplicación con la tranquilidad de que tu privacidad está protegida.\nUso de Permisos: Aunque nuestra aplicación solicita ciertos permisos, como el acceso a la cámara, estos se utilizan exclusivamente para el funcionamiento de la aplicación y no para recopilar datos personales.\nPolítica de Privacidad Detallada: Si deseas obtener más información sobre nuestra política de privacidad, te invitamos a visitar nuestra página web. Allí encontrarás una explicación detallada de nuestras prácticas de privacidad.\nPara continuar y disfrutar de todas las funcionalidades de Calefactor Smart, por favor, acepta nuestra política de privacidad.',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
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
                Uri uri =
                    Uri.parse('https://calefactorescalden.com.ar/privacidad/');
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

Future<void> guardarLista(List<String> listaDispositivos) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('dispositivos_conectados', listaDispositivos);
}

Future<List<String>> cargarLista() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('dispositivos_conectados') ?? [];
}

String generateRandomNumbers(int length) {
  Random random = Random();
  String result = '';

  for (int i = 0; i < length; i++) {
    result += random.nextInt(10).toString();
  }

  return result;
}

void sendOwner() async {
  try {
    String userEmail =
        currentUserEmail;
    await FirebaseFirestore.instance.collection(deviceName).doc(userEmail).set({
      'owner': userEmail,
    });
  } catch (e, s) {
    printLog('Error al enviar owner a firebase $e $s');
  }
}

Future<void> saveNicknamesMap(Map<String, String> nicknamesMap) async {
  final prefs = await SharedPreferences.getInstance();
  String nicknamesString = json.encode(nicknamesMap);
  await prefs.setString('nicknamesMap', nicknamesString);
}

Future<Map<String, String>> loadNicknamesMap() async {
  final prefs = await SharedPreferences.getInstance();
  String? nicknamesString = prefs.getString('nicknamesMap');
  if (nicknamesString != null) {
    return Map<String, String>.from(json.decode(nicknamesString));
  }
  return {}; // Devuelve un mapa vacío si no hay nada almacenado
}

Future<void> saveDetectorsList(List<String> lista) async {
  final prefs = await SharedPreferences.getInstance();
  String detList = json.encode(lista);
  await prefs.setString('detectoresLista', detList);
}

Future<List<String>> loadDetectorsList() async {
  final prefs = await SharedPreferences.getInstance();
  String? detList = prefs.getString('detectoresLista');
  if (detList != null) {
    return json.decode(detList);
  }
  return []; // Devuelve una lista vacío si no hay nada almacenado
}

Future<void> saveOldToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}

Future<String> loadOldToken() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  if (token != null) {
    return token;
  }
  return '';
}

Future<bool> readStatusValue() async {
  try {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection(deviceName)
        .doc('info')
        .get();
    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      return data['estado'];
    } else {
      printLog("Documento no encontrado");
      return false;
    }
  } catch (e) {
    printLog("Error al leer de Firestore: $e");
    return false;
  }
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

void setupToken() async {
  String? token = await FirebaseMessaging.instance.getToken();
  String? tokenToSend = '$token/-/${nicknamesMap[deviceName] ?? deviceName}';

  if (token != null) {
    removeTokenFromDatabase(actualToken);
    actualToken = tokenToSend;
    saveTokenToDatabase(tokenToSend);
  }

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    String? newtokenToSend =
        '$newToken/-/${nicknamesMap[deviceName] ?? deviceName}';
    saveTokenToDatabase(newtokenToSend);
  });
}

void saveTokenToDatabase(String token) async {
  saveOldToken(token);
  DocumentReference documentRef =
      FirebaseFirestore.instance.collection(deviceName).doc('info');
  await documentRef.set({
    'Tokens': FieldValue.arrayUnion([token])
  }, SetOptions(merge: true));
}

void removeTokenFromDatabase(String token) async {
  printLog('Borrando esto: $token');
  try {
    DocumentReference documentRef =
        FirebaseFirestore.instance.collection(deviceName).doc('info');
    await documentRef.update({
      'Tokens': FieldValue.arrayRemove([token])
    });
  } catch (e, s) {
    printLog('Error al borrar token $e $s');
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

Future<String?> getUserMail() async {
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
  return null; // Retorna nulo si no se encuentra el correo electrónico
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
      softwareVersion = partes[2];
      hardwareVersion = partes[3];
      printLog('Device: $deviceType');

      if (deviceType == '022000' ||
          deviceType == '027000' ||
          deviceType == '041220') {
        BluetoothService espService = services.firstWhere(
            (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));

        varsUuid = espService.characteristics.firstWhere((c) =>
            c.uuid ==
            Guid(
                '52a2f121-a8e3-468c-a5de-45dca9a2a207')); //WorkingTemp:WorkingStatus:EnergyTimer:HeaterOn:NightMode
      } else {
        BluetoothService service = services.firstWhere(
            (s) => s.uuid == Guid('dd249079-0ce8-4d11-8aa9-53de4040aec6'));

        workUuid = service.characteristics.firstWhere((c) =>
            c.uuid ==
            Guid(
                '6869fe94-c4a2-422a-ac41-b2a7a82803e9')); //Array de datos (ppm,etc)
        lightUuid = service.characteristics.firstWhere((c) =>
            c.uuid == Guid('12d3c6a1-f86e-4d5b-89b5-22dc3f5c831f')); //No leo
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int fun = 0;
  int fun1 = 0;
  bool fun2 = false;

  void toggleState(String deviceName, bool newState, String equipo) async {
    // Función para cambiar el estado
    await _firestore
        .collection(deviceName)
        .doc('info')
        .update({'estado': newState});
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
                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection(deviceName).doc('info').get(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      String equipo = snapshot.data!['tipo'];
                      if (equipo == '022000' || equipo == '027000') {
                        bool estado = snapshot.data!['estado'];
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
                                    const Text('Encendido',
                                        style: TextStyle(
                                            color: Colors.green, fontSize: 15)),
                                    equipo == '022000'
                                        ? Icon(Icons.flash_on_rounded,
                                            size: 15, color: Colors.amber[800])
                                        : Icon(Icons.local_fire_department,
                                            size: 15, color: Colors.amber[800])
                                  ],
                                )
                              : const Text('Apagado',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 15)),
                          trailing: FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection(deviceName)
                                .doc(widget.userMail)
                                .get(),
                            builder: (context, ownerSnapshot) {
                              if (ownerSnapshot.data != null &&
                                  ownerSnapshot.data!.exists) {
                                // Si el documento existe, mostrar el Switch
                                return Switch(
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
                                    toggleState(deviceName, newValue, equipo);
                                    setState(() {
                                      estado = newValue;
                                    });
                                  },
                                );
                              } else {
                                // Si el documento no existe, no mostrar nada o mostrar un widget alternativo
                                return const SizedBox(height: 0, width: 0);
                              }
                            },
                          ),
                        );
                      } else if (equipo == '041220') {
                        bool estado = snapshot.data!['estado'];
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
                                    const Text('Encendido',
                                        style: TextStyle(
                                            color: Colors.green, fontSize: 15)),
                                    Icon(Icons.flash_on_rounded,
                                        size: 15, color: Colors.amber[800])
                                  ],
                                )
                              : const Text('Apagado',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 15)),
                          trailing: FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection(deviceName)
                                .doc(widget.userMail)
                                .get(),
                            builder: (context, ownerSnapshot) {
                              if (ownerSnapshot.data != null &&
                                  ownerSnapshot.data!.exists) {
                                // Si el documento existe, mostrar el Switch
                                return Switch(
                                  activeColor:
                                      const Color.fromARGB(255, 189, 189, 189),
                                  activeTrackColor:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  inactiveThumbColor:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  inactiveTrackColor:
                                      const Color.fromARGB(255, 189, 189, 189),
                                  value: estado,
                                  onChanged: (newValue) {
                                    toggleState(deviceName, newValue, equipo);
                                    setState(() {
                                      estado = newValue;
                                    });
                                  },
                                );
                              } else {
                                // Si el documento no existe, no mostrar nada o mostrar un widget alternativo
                                return const SizedBox(height: 0, width: 0);
                              }
                            },
                          ),
                        );
                      } else {
                        int ppmCO = snapshot.data!['ppmCO'] ?? 0;
                        int ppmCH4 = snapshot.data!['ppmCH4'] ?? 0;
                        bool alert = snapshot.data!['alert'] ?? false;
                        FirebaseFirestore.instance
                            .collection(deviceName)
                            .doc('info')
                            .snapshots()
                            .listen((event) {
                          if (event.data()!['ppmCO'] != fun) {
                            setState(() {
                              ppmCO = event.data()!['ppmCO'];
                            });
                            fun = ppmCO;
                          }
                          if (event.data()!['ppmCH4'] != fun1) {
                            setState(() {
                              ppmCH4 = event.data()!['ppmCH4'];
                            });
                            fun1 = ppmCH4;
                          }
                          if (event.data()!['alert'] != fun2) {
                            setState(() {
                              alert = event.data()!['alert'];
                            });
                            fun2 = alert;
                          }
                        });
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
                                  removeTokenFromDatabase(actualToken);
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
                      }
                    }
                    return ListTile(
                      title: Text(nicknamesMap[deviceName] ?? deviceName,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15)),
                      subtitle: const Text(
                        'Cargando...',
                        style: TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
