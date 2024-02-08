// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

MyDevice myDevice = MyDevice();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String myDeviceid = '';
String deviceName = '';
bool bluetoothOn = false;
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
final FirebaseAuth auth = FirebaseAuth.instance;
Timer? locationTimer;
Timer? bluetoothTimer;
int lastUser = 0;
List<String> previusConnections = [];
Map<String, String> nicknamesMap = {};
String deviceType = '';
MqttServerClient? mqttClient5773;
MqttServerClient? mqttClient022000;
MqttServerClient? mqttClient027000;
bool mqttConected022000 = false;
bool mqttConected027000 = false;
bool mqttConected5773 = false;

//!------------------------------VERSION NUMBER---------------------------------------

String appVersionNumber = '24020802';
//ACORDATE: Cambia el número de versión en el pubspec.yaml antes de publicar

//!------------------------------VERSION NUMBER---------------------------------------

// FUNCIONES //

void showToast(String message) {
  print('Toast: $message');
  Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      textColor: const Color.fromARGB(255, 37, 34, 35),
      fontSize: 16.0);
}

Future<void> sendWifitoBle() async {
  MyDevice myDevice = MyDevice();
  String value = '$wifiName#$wifiPassword';
  String dataToSend = '${command(deviceType)}[3]($value)';
  print(dataToSend);
  try {
    await myDevice.toolsUuid.write(dataToSend.codeUnits);
    print('Se mando el wifi ANASHE');
  } catch (e) {
    print('Error al conectarse a Wifi $e');
  }
  atemp = true;
  wifiName = '';
  wifiPassword = '';
}

String command(String device) {
  switch (device) {
    case '022000':
      return '022000_IOT';
    case '027000':
      return '027000_IOT';
    case '5773':
      return '57_IOT';
    default:
      return '';
  }
}

void setupMqtt5773() async {
  String deviceId = 'intelligentgas_IOT/${generateRandomNumbers(32)}';
  String hostname = '';
  String username = '';
  String password = '';

  // Cargar el certificado CA
  ByteData data = await rootBundle.load('assets/cert/emqxsl-ca.crt');
  SecurityContext context = SecurityContext(withTrustedRoots: false);
  context.setTrustedCertificatesBytes(data.buffer.asUint8List());

  mqttClient5773 = MqttServerClient.withPort(hostname, deviceId, 8883);

  mqttClient5773!.secure = true;

  mqttClient5773!.logging(on: true);
  mqttClient5773!.onDisconnected = mqttonDisconnected;

  // Configuración de las credenciales
  mqttClient5773!.setProtocolV311();
  mqttClient5773!.keepAlivePeriod = 3;
  await mqttClient5773!.connect(username, password);
  mqttConected5773 = true;
}

void setupMqtt022000() async {
  String deviceId = 'calden022000_IOT/${generateRandomNumbers(32)}';
  String hostname = 'm989ca21.ala.us-east-1.emqxsl.com';
  String username = '022000_IOT';
  String password = '022000_IOT';

  // Cargar el certificado CA
  ByteData data = await rootBundle.load('assets/cert/emqxsl-ca.crt');
  SecurityContext context = SecurityContext(withTrustedRoots: false);
  context.setTrustedCertificatesBytes(data.buffer.asUint8List());

  mqttClient022000 = MqttServerClient.withPort(hostname, deviceId, 8883);

  mqttClient022000!.secure = true;

  mqttClient022000!.logging(on: true);
  mqttClient022000!.onDisconnected = mqttonDisconnected;

  // Configuración de las credenciales
  mqttClient022000!.setProtocolV311();
  mqttClient022000!.keepAlivePeriod = 3;
  await mqttClient022000!.connect(username, password);
  mqttConected022000 = true;
}

void setupMqtt027000() async {
  String deviceId = 'calden_IOT027000/${generateRandomNumbers(32)}';
  String hostname = 'm989ca21.ala.us-east-1.emqxsl.com';
  String username = '027000_IOT';
  String password = '027000_IOT';

  // Cargar el certificado CA
  ByteData data = await rootBundle.load('assets/cert/emqxsl-ca.crt');
  SecurityContext context = SecurityContext(withTrustedRoots: false);
  context.setTrustedCertificatesBytes(data.buffer.asUint8List());

  mqttClient027000 = MqttServerClient.withPort(hostname, deviceId, 8883);

  mqttClient027000!.secure = true;

  mqttClient027000!.logging(on: true);
  mqttClient027000!.onDisconnected = mqttonDisconnected;

  // Configuración de las credenciales
  mqttClient027000!.setProtocolV311();
  mqttClient027000!.keepAlivePeriod = 3;
  await mqttClient027000!.connect(username, password);
  mqttConected027000 = true;
}

void mqttonDisconnected() {
  mqttConected5773 = false;
  mqttConected022000 = false;
  mqttConected027000 = false;
  print('Desconectado de mqtt');
}

void sendMessagemqtt(String deviceName, String message, String device) {
  print(
      'Conexiones: 57 $mqttConected5773 :: 022000 $mqttConected022000 :: 027000 $mqttConected027000');
  late RegExpMatch? match;
  if (device == '022000' || device == '027000') {
    final regex = RegExp(r'Calefactor(\d+)');
    match = regex.firstMatch(deviceName);
  } else {
    final regex = RegExp(r'Detector(\d+)');
    match = regex.firstMatch(deviceName);
  }

  final serialNum = match!.group(1);
  String topic = '${command(device)}/$serialNum';
  final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
  builder.addString(message);

  if (device == '022000' && mqttConected022000) {
    mqttClient022000!
        .publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  } else if (device == '027000' && mqttConected027000) {
    mqttClient027000!
        .publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  } else if (device == '5773' && mqttConected5773) {
    mqttClient5773!
        .publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }
}

String generateErrorReport(FlutterErrorDetails details) {
  return '''
Error: ${details.exception}
Stacktrace: ${details.stack}
  ''';
}

void sendReportError(String filePath) async {
  final Email email = Email(
    body: '¡Hola! Te envio el reporte de error que surgió en mi app',
    subject: 'Reporte de error $deviceName',
    recipients: ['ingenieria@intelligentgas.com.ar'],
    attachmentPaths: [filePath],
    isHTML: false,
  );

  try {
    await FlutterEmailSender.send(email);
    print('Correo enviado');
  } catch (error) {
    print('Error al enviar el correo: $error');
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
    } else {
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
        FirebaseAuth.instance.currentUser?.email ?? 'usuario_desconocido';
    await FirebaseFirestore.instance.collection(deviceName).doc(userEmail).set({
      'owner': userEmail,
    });
  } catch (e, s) {
    print('Error al enviar owner a firebase $e $s');
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
      print("Documento no encontrado");
      return false;
    }
  } catch (e) {
    print("Error al leer de Firestore: $e");
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
    print("Error during navigation: $e");
  }
}

Map<String, String> parseWifiQR(String qrContent) {
  print(qrContent);
  final ssidMatch = RegExp(r'S:([^;]+)').firstMatch(qrContent);
  final passwordMatch = RegExp(r'P:([^;]+)').firstMatch(qrContent);

  final ssid = ssidMatch?.group(1) ?? '';
  final password = passwordMatch?.group(1) ?? '';
  return {"SSID": ssid, "password": password};
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
  late BluetoothCharacteristic credsUuid;
  late BluetoothCharacteristic varsUuid;
  late BluetoothCharacteristic workUuid;
  late BluetoothCharacteristic lightUuid;

  Future<bool> setup(BluetoothDevice connectedDevice) async {
    try {
      device = connectedDevice;

      List<BluetoothService> services =
          await device.discoverServices(timeout: 3);
      print('Los servicios: $services');

      BluetoothService infoService = services.firstWhere(
          (s) => s.uuid == Guid('6a3253b4-48bc-4e97-bacd-325a1d142038'));
      infoUuid = infoService.characteristics.firstWhere(
          (c) => c.uuid == Guid('fc5c01f9-18de-4a75-848b-d99a198da9be'));

      List<int> listita = await infoUuid.read();
      String str = utf8.decode(listita);
      var partes = str.split('_');
      deviceType = partes[0];

      if (deviceType == '022000' || deviceType == '027000') {
        BluetoothService espService = services.firstWhere(
            (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));

        toolsUuid = espService.characteristics.firstWhere(
            (c) => c.uuid == Guid('3565a918-f830-4fa1-b743-18d618fc5269'));
        credsUuid = espService.characteristics.firstWhere(
            (c) => c.uuid == Guid('14a84bb7-7c7c-466c-a3bd-adf2f843df97'));
        varsUuid = espService.characteristics.firstWhere(
            (c) => c.uuid == Guid('52a2f121-a8e3-468c-a5de-45dca9a2a207'));
      } else {
        BluetoothService service = services.firstWhere(
            (s) => s.uuid == Guid('dd249079-0ce8-4d11-8aa9-53de4040aec6'));
        workUuid = service.characteristics.firstWhere(
            (c) => c.uuid == Guid('6869fe94-c4a2-422a-ac41-b2a7a82803e9'));
        lightUuid = service.characteristics.firstWhere(
            (c) => c.uuid == Guid('12d3c6a1-f86e-4d5b-89b5-22dc3f5c831f'));

        BluetoothService espService = services.firstWhere(
            (s) => s.uuid == Guid('33e3a05a-c397-4bed-81b0-30deb11495c7'));
        toolsUuid = espService.characteristics.firstWhere(
            (c) => c.uuid == Guid('89925840-3d11-4676-bf9b-62961456b570'));
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      print('Lcdtmbe $e $stackTrace');

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
                          TextStyle(color: Color.fromARGB(255, 189, 189, 189))),
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
                    color: const Color.fromARGB(255, 189, 189, 189),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    color: const Color.fromARGB(255, 1, 18, 28),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    color: const Color.fromARGB(255, 1, 18, 28),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  child: Container(
                    width: 3,
                    color: const Color.fromARGB(255, 1, 18, 28),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 3,
                    color: const Color.fromARGB(255, 1, 18, 28),
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
          print("Error: $e $stackTrace");
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

  void toggleState(String deviceName, bool newState, String equipo) async {
    // Función para cambiar el estado
    await _firestore
        .collection(deviceName)
        .doc('info')
        .update({'estado': newState});
    sendMessagemqtt(deviceName, newState ? '1' : '0', equipo);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 37, 34, 35),
      child: previusConnections.isEmpty
          ? ListView(
              children: const [
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Aún no se ha conectado a ningún calefactor',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 255, 255, 255),
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
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontSize: 24,
                              ),
                            ),
                            SizedBox(width: 80),
                            Icon(Icons.wifi, color: Colors.white)
                          ]));
                }

                String deviceName = previusConnections[index - 1];
                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection(deviceName).doc('info').get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
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
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: () {
                                  print('Eliminando de la lista');
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
                                  color: Colors.white,
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
                              if (ownerSnapshot.connectionState ==
                                  ConnectionState.done) {
                                if (ownerSnapshot.data != null &&
                                    ownerSnapshot.data!.exists) {
                                  // Si el documento existe, mostrar el Switch
                                  return Switch(
                                    activeColor: const Color.fromARGB(
                                        255, 189, 189, 189),
                                    activeTrackColor: const Color.fromARGB(
                                        255, 255, 255, 255),
                                    inactiveThumbColor: const Color.fromARGB(
                                        255, 255, 255, 255),
                                    inactiveTrackColor: const Color.fromARGB(
                                        255, 189, 189, 189),
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
                              } else {
                                // Manejo de otros estados de conexión
                                return const CircularProgressIndicator(
                                  color: Colors.white,
                                );
                              }
                            },
                          ),
                        );
                      } else {
                        int ppmCO = snapshot.data!['ppmCO'] ?? 0;
                        int ppmCH4 = snapshot.data!['ppmCH4'] ?? 0;
                        bool alert = snapshot.data!['alert'];
                        return ListTile(
                          title: Text(nicknamesMap[deviceName] ?? deviceName,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15)),
                          subtitle: Text.rich(
                            TextSpan(children: [
                              const TextSpan(
                                text: 'PPMCO: ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: '$ppmCO         ',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold),
                              ),
                              const TextSpan(
                                text: 'PPMCH4: ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              TextSpan(
                                text: '$ppmCH4',
                                style: const TextStyle(
                                    color: Colors.white,
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
                        subtitle: const Text('Cargando...',
                            style:
                                TextStyle(color: Colors.white, fontSize: 15)),
                        trailing: const CircularProgressIndicator(
                          color: Colors.white,
                        ));
                  },
                );
              },
            ),
    );
  }
}
