// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:project_022000iot_user/firebase_options.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:workmanager/workmanager.dart';

// VARIABLES //

MyDevice myDevice = MyDevice();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
String legajoConectado = '';
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
bool alreadySubOta = false;
List<int> toolsValues = [];
List<int> credsValues = [];
List<int> varsValues = [];
bool alreadySubTools = false;
String wifiName = '';
String wifiPassword = '';
bool atemp = false;
bool isWifiConnected = false;
bool wifilogoConnected = false;
MaterialColor statusColor = Colors.grey;
bool alreadyLog = false;
bool toastFlag = false;
int wrongPass = 0;
final FirebaseAuth auth = FirebaseAuth.instance;
double distOnValue = 0.0;
double distOffValue = 0.0;
bool turnOn = false;
Map<String, String> nicknamesMap = {};
bool isTaskScheduled = false;
bool deviceOwner = false;
bool inApp = false;
bool trueStatus = false;
late bool nightMode;
MqttServerClient? mqttClient;
Timer? locationTimer;
bool mqttConected = false;

//!------------------------------VERSION NUMBER---------------------------------------

String appVersionNumber = '24011901';

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

String generateErrorReport(FlutterErrorDetails details) {
  return '''
Error: ${details.exception}
Stacktrace: ${details.stack}
  ''';
}

void sendReportOnWhatsApp(String filePath) async {
  const text = '¡Hola! Este es un reporte de error de la app Calefactor Smart';
  final file = File(filePath);
  final base64File = base64Encode(file.readAsBytesSync());
  final fileName = Uri.encodeComponent(file.path.split('/').last);

  const phoneNumber = '5491130621338';

  Uri url = Uri.parse(
      'whatsapp://send?phone=$phoneNumber&text=$text&file=$base64File&filename=$fileName');

  if (await canLaunchUrl(url)) {
    await launchUrl(url);
  } else {
    print('No se pudo lanzar la URL de WhatsApp');
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

Future<void> sendWifitoBle() async {
  MyDevice myDevice = MyDevice();
  String value = '$wifiName#$wifiPassword';
  String dataToSend = '022000_IOT[3]($value)';
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

Future<double> readDistanceOnValue() async {
  String userEmail =
      FirebaseAuth.instance.currentUser?.email ?? 'usuario_desconocido';

  try {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection(userEmail)
        .doc(deviceName)
        .get();
    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      return data['distanciaOn']?.toDouble() ??
          3000.0; // Retorna 100.0 si no se encuentra el campo
    } else {
      print("Documento no encontrado");
      return 3000.0;
    }
  } catch (e) {
    print("Error al leer de Firestore: $e");
    return 3000.0;
  }
}

Future<double> readDistanceOffValue() async {
  String userEmail =
      FirebaseAuth.instance.currentUser?.email ?? 'usuario_desconocido';

  try {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection(userEmail)
        .doc(deviceName)
        .get();
    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      return data['distanciaOff']?.toDouble() ??
          100.0; // Retorna 100.0 si no se encuentra el campo
    } else {
      print("Documento no encontrado");
      return 100.0;
    }
  } catch (e) {
    print("Error al leer de Firestore: $e");
    return 100.0;
  }
}

Future<bool> readStatusValue() async {
  String userEmail =
      FirebaseAuth.instance.currentUser?.email ?? 'usuario_desconocido';

  try {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection(userEmail)
        .doc(deviceName)
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

Future<List<DocumentoEquipo>> obtenerDocumentos(String userMail) async {
  QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection(userMail).get();

  return querySnapshot.docs
      .map((doc) => DocumentoEquipo.fromFirestore(doc))
      .toList();
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

Future<void> saveControlValue(bool control) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('ControlValue', control);
}

Future<bool> loadControlValue() async {
  final prefs = await SharedPreferences.getInstance();
  bool? controlValue = prefs.getBool('ControlValue');
  if (controlValue != null) {
    return controlValue;
  } else {
    return false;
  }
}

void sendOwner() async {
  try {
    String userEmail =
        FirebaseAuth.instance.currentUser?.email ?? 'usuario_desconocido';
    DocumentReference documentRef =
        FirebaseFirestore.instance.collection(userEmail).doc(deviceName);
    await documentRef.set({'owner': userEmail}, SetOptions(merge: true));
  } catch (e, s) {
    print('Error al enviar owner a firebase $e $s');
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

void setupMqtt() async {
  String deviceId = 'SIME${generateRandomNumbers(32)}';
  String hostname = 'nee8a41e.ala.us-east-1.emqxsl.com';
  String username = 'trillo';
  String password = '4199';

  // Cargar el certificado CA
  ByteData data = await rootBundle.load('assets/cert/emqxsl-ca.crt');
  SecurityContext context = SecurityContext(withTrustedRoots: false);
  context.setTrustedCertificatesBytes(data.buffer.asUint8List());

  mqttClient = MqttServerClient.withPort(hostname, deviceId, 8883);

  mqttClient!.secure = true;

  mqttClient!.logging(on: true);
  mqttClient!.onDisconnected = mqttonDisconnected;

  // Configuración de las credenciales
  mqttClient!.setProtocolV311();
  mqttconnect(username, password);
}

void mqttonDisconnected() {
  mqttConected = false;
  print('Desconectado');
}

Future<void> mqttconnect(String u, String p) async {
  try {
    await mqttClient!.connect(u, p);
    mqttConected = true;
  } catch (e) {
    print('Error de conexión: $e');
  }
}

void sendMessagemqtt(String topic, String message) {
  print('Estado del mqtt: $mqttConected');
  if (mqttConected) {
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);

    mqttClient!.publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
  }
}

void checkBle() async {
  FlutterBluePlus.adapterState.listen((state) {
    if (state != BluetoothAdapterState.on && inApp) {
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
    } else if (state == BluetoothAdapterState.on) {
      bluetoothOn = true;
    }
  });
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
                Uri uri = Uri.parse('https://calefactorescalden.com.ar/privacidad/');
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

// CLASES //

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

//*-BLE-*//caracteristicas y servicios

class MyDevice {
  static final MyDevice _singleton = MyDevice._internal();

  factory MyDevice() {
    return _singleton;
  }

  MyDevice._internal();

  late BluetoothDevice device;
  late BluetoothCharacteristic toolsUuid;
  late BluetoothCharacteristic credsUuid;
  late BluetoothCharacteristic varsUuid;
  late BluetoothCharacteristic espServicesUuid;

  Future<bool> setup(BluetoothDevice connectedDevice) async {
    try {
      device = connectedDevice;

      List<BluetoothService> services =
          await device.discoverServices(timeout: 3);
      print('Los servicios: $services');

      BluetoothService espService = services.firstWhere(
          (s) => s.uuid == Guid('6f2fa024-d122-4fa3-a288-8eca1af30502'));

      toolsUuid = espService.characteristics.firstWhere(
          (c) => c.uuid == Guid('3565a918-f830-4fa1-b743-18d618fc5269'));
      credsUuid = espService.characteristics.firstWhere(
          (c) => c.uuid == Guid('14a84bb7-7c7c-466c-a3bd-adf2f843df97'));
      varsUuid = espService.characteristics.firstWhere(
          (c) => c.uuid == Guid('52a2f121-a8e3-468c-a5de-45dca9a2a207'));

      return Future.value(true);
    } catch (e, stackTrace) {
      print('Lcdtmbe $e $stackTrace');

      return Future.value(false);
    }
  }
}

//*-Drawer-*//Menú lateral con dispositivos

class DocumentoEquipo {
  String id;
  bool estado;
  String owner;

  DocumentoEquipo(
      {required this.id, required this.estado, required this.owner});

  factory DocumentoEquipo.fromFirestore(DocumentSnapshot doc) {
    // Realizar un cast explícito de los datos a Map<String, dynamic>
    Map<String, dynamic> data = doc.data()! as Map<String, dynamic>;

    return DocumentoEquipo(
      id: doc.id,
      estado: data['estado'] ?? false,
      owner: data['owner'] ?? 'NA',
    );
  }
}

class MyDrawer extends StatefulWidget {
  final String userMail;

  const MyDrawer({super.key, required this.userMail});

  @override
  MyDrawerState createState() => MyDrawerState();
}

class MyDrawerState extends State<MyDrawer> {
  List<DocumentoEquipo> documentos = [];

  @override
  void initState() {
    super.initState();
    cargarDocumentos();
  }

  cargarDocumentos() async {
    documentos = await obtenerDocumentos(widget.userMail);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 37, 34, 35),
      child: ListView.builder(
        itemCount:
            documentos.length + 1, // Aumenta el conteo en 1 para el encabezado
        itemBuilder: (context, index) {
          if (index == 0) {
            // El primer ítem será el DrawerHeader
            return const DrawerHeader(
                decoration: BoxDecoration(
                    // color: Colors.blue,
                    ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.start, children: [
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

          // Ajusta el índice para los documentos debido al encabezado
          DocumentoEquipo doc = documentos[index - 1];
          String userEmail =
              FirebaseAuth.instance.currentUser?.email ?? 'usuario_desconocido';
          bool owner = userEmail == doc.owner;
          return ListTile(
            title: Row(
              children: [
                Text(
                  nicknamesMap[doc.id] ?? doc.id,
                  style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255)),
                ),
                doc.estado
                    ? Icon(Icons.flash_on_rounded,
                        size: 20, color: Colors.amber[600])
                    : const SizedBox(width: 0, height: 0),
              ],
            ),
            trailing: owner
                ? Switch(
                    activeColor: const Color.fromARGB(255, 189, 189, 189),
                    activeTrackColor: const Color.fromARGB(255, 255, 255, 255),
                    inactiveThumbColor:
                        const Color.fromARGB(255, 255, 255, 255),
                    inactiveTrackColor:
                        const Color.fromARGB(255, 189, 189, 189),
                    value: doc.estado,
                    onChanged: (bool value) {
                      setState(() {
                        doc.estado = value;
                      });
                      actualizarEstadoDocumento(widget.userMail, doc.id, value);
                      sendMessagemqtt(doc.id, value ? '1' : '0');
                    },
                  )
                : doc.estado
                    ? const Text('Encendido',
                        style: TextStyle(color: Colors.green))
                    : const Text('Apagado',
                        style: TextStyle(color: Colors.red)),
          );
        },
      ),
    );
  }

  actualizarEstadoDocumento(String userMail, String docId, bool estado) async {
    await FirebaseFirestore.instance
        .collection(userMail)
        .doc(docId)
        .update({'estado': estado});
  }
}

class DeviceDrawer extends StatefulWidget {
  final bool night;
  const DeviceDrawer({super.key, required this.night});

  @override
  DeviceDrawerState createState() => DeviceDrawerState();
}

class DeviceDrawerState extends State<DeviceDrawer> {
  final TextEditingController costController = TextEditingController();
  late bool loading;
  bool buttonPressed = false;
  double result = 0.0;
  DateTime? fechaSeleccionada;
  late bool nightState;

  @override
  void initState() {
    super.initState();
    cargarFechaGuardada();
    nightState = widget.night;
    print('NightMode status: $nightState');
  }

  Future<void> guardarFecha() async {
    DateTime now = DateTime.now();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('year', now.year);
    await prefs.setInt('month', now.month);
    await prefs.setInt('day', now.day);
    setState(() {
      fechaSeleccionada = now;
    });
  }

  Future<void> cargarFechaGuardada() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? year = prefs.getInt('year');
    int? month = prefs.getInt('month');
    int? day = prefs.getInt('day');
    if (year != null && month != null && day != null) {
      setState(() {
        fechaSeleccionada = DateTime(year, month, day);
      });
    }
  }

  void makeCompute() async {
    if (costController.text.isNotEmpty) {
      setState(() {
        buttonPressed = true;
        loading = true;
      });
      print('Estoy haciendo calculaciones misticas');
      List<int> list = await myDevice.varsUuid.read();
      var parts = utf8.decode(list).split(':');

      result = double.parse(parts[2]) * 2 * double.parse(costController.text);

      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        loading = false;
      });
    } else {
      showToast('Primero debes ingresar un valor kW/h');
    }
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: const Color.fromARGB(255, 37, 34, 35),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    SizedBox(
                        width: 200,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: costController,
                          style: const TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255)),
                          cursorColor: const Color.fromARGB(255, 189, 189, 189),
                          decoration: const InputDecoration(
                            labelText: 'Ingresa valor KW/h',
                            labelStyle: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255)),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 189, 189, 189)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 189, 189, 189)),
                            ),
                          ),
                        )),
                    const SizedBox(height: 10),
                    if (buttonPressed) ...[
                      Visibility(
                          visible: loading,
                          child: const CircularProgressIndicator(
                              color: Color.fromARGB(255, 255, 255, 255))),
                      Visibility(
                          visible: !loading,
                          child: Text('\$$result',
                              style: const TextStyle(
                                  fontSize: 50, color: Colors.white))),
                    ],
                    const SizedBox(height: 10),
                    ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 189, 189, 189)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 255, 255, 255))),
                        onPressed: makeCompute,
                        child: const Text('Hacer calculo')),
                    ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 189, 189, 189)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 255, 255, 255))),
                        onPressed: () {
                          guardarFecha();
                          String data = '022000_IOT[8](0)';
                          myDevice.toolsUuid.write(data.codeUnits);
                        },
                        child: const Text('Reiniciar mes')),
                    fechaSeleccionada != null
                        ? Text(
                            'Ultimo reinicio: ${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white))
                        : const Text(''),
                    const SizedBox(height: 20),
                    const Text('Modo actual: ',
                        style: TextStyle(fontSize: 20, color: Colors.white)),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          nightState = !nightState;
                          print('Estado: $nightState');
                          int fun = nightState ? 1 : 0;
                          String data = '022000_IOT[7]($fun)';
                          print(data);
                          myDevice.toolsUuid.write(data.codeUnits);
                        });
                      },
                      icon: nightState
                          ? const Icon(Icons.nightlight,
                              color: Colors.white, size: 40)
                          : const Icon(Icons.wb_sunny,
                              color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 189, 189, 189)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 255, 255, 255))),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                backgroundColor:
                                    const Color.fromARGB(255, 37, 34, 35),
                                title: const Text(
                                  '¿Dejar de ser administrador del calefactor?',
                                  style: TextStyle(
                                      color:
                                          Color.fromARGB(255, 255, 255, 255)),
                                ),
                                content: const Text(
                                  'Esto hará que otras personas puedan conectarse al dispositivo y modificar sus parámetros',
                                  style: TextStyle(
                                      color:
                                          Color.fromARGB(255, 255, 255, 255)),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    style: const ButtonStyle(
                                        foregroundColor:
                                            MaterialStatePropertyAll(
                                                Color.fromARGB(
                                                    255, 255, 255, 255))),
                                    child: const Text('Cancelar'),
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                    },
                                  ),
                                  TextButton(
                                    style: const ButtonStyle(
                                        foregroundColor:
                                            MaterialStatePropertyAll(
                                                Color.fromARGB(
                                                    255, 255, 255, 255))),
                                    child: const Text('Aceptar'),
                                    onPressed: () async {
                                      try {
                                        String mailData = '022000_IOT[6](NA)';
                                        myDevice.toolsUuid
                                            .write(mailData.codeUnits);
                                        String userEmail = FirebaseAuth
                                                .instance.currentUser?.email ??
                                            'usuario_desconocido';
                                        FirebaseFirestore.instance
                                            .collection(userEmail)
                                            .doc(deviceName)
                                            .set({'owner': FieldValue.delete()},
                                                SetOptions(merge: true));
                                        myDevice.device.disconnect();
                                        Navigator.of(dialogContext).pop();
                                      } catch (e, s) {
                                        print(
                                            'Error al borrar owner $e Trace: $s');
                                        showToast(
                                            'Error al borrar el administrador.');
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Text('Dejar de ser administrador'))
                  ],
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                    style: const ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(
                            Color.fromARGB(255, 189, 189, 189)),
                        foregroundColor: MaterialStatePropertyAll(
                            Color.fromARGB(255, 255, 255, 255))),
                    onPressed: () {
                      showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                                backgroundColor:
                                    const Color.fromARGB(255, 37, 34, 35),
                                content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Contacto comercial:',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                              onPressed: () => _sendWhatsAppMessage(
                                                  '5491162234181',
                                                  '¡Hola! Tengo una duda comercial sobre el Calefactor022000: \n'),
                                              icon: const Icon(
                                                Icons.phone,
                                                color: Colors.white,
                                                size: 20,
                                              )),
                                          // const SizedBox(width: 5),
                                          const Text('+54 9 11 6223-4181',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20))
                                        ],
                                      ),
                                      SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                onPressed: () => _launchEmail(
                                                    'ceat@ibsanitarios.com.ar',
                                                    'Consulta comercial 022000eIOT',
                                                    '¡Hola! mi equipo es el $deviceName y tengo la siguiente duda:\n'),
                                                icon: const Icon(
                                                  Icons.mail,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              // const SizedBox(width: 5),
                                              const Text(
                                                  'ceat@ibsanitarios.com.ar',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20))
                                            ],
                                          )),
                                      const SizedBox(height: 20),
                                      const Text('Consulta técnica:',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: () => _launchEmail(
                                                  'pablo@intelligentgas.com.ar',
                                                  'Consulta ref. $deviceName',
                                                  '¡Hola! Tengo una consulta referida al área de ingenieria sobre mi equipo: \n'),
                                              icon: const Icon(
                                                Icons.mail,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            // const SizedBox(width: 5),
                                            const Text(
                                              'pablo@intelligentgas.com.ar',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20),
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text('Customer service:',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                              onPressed: () => _sendWhatsAppMessage(
                                                  '5491162232619',
                                                  '¡Hola! Te hablo por una duda sobre mi equipo $deviceName: \n'),
                                              icon: const Icon(
                                                Icons.phone,
                                                color: Colors.white,
                                                size: 20,
                                              )),
                                          // const SizedBox(width: 5),
                                          const Text('+54 9 11 6223-2619',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20))
                                        ],
                                      ),
                                      SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              IconButton(
                                                onPressed: () => _launchEmail(
                                                    'service@calefactorescalden.com.ar',
                                                    'Consulta 022000eIOT',
                                                    'Tengo una consulta referida a mi equipo $deviceName: \n'),
                                                icon: const Icon(
                                                  Icons.mail,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                              // const SizedBox(width: 5),
                                              const Text(
                                                'service@calefactorescalden.com.ar',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20),
                                                overflow: TextOverflow.ellipsis,
                                              )
                                            ],
                                          )),
                                    ]));
                          });
                    },
                    child: const Text('CONTACTANOS'))),
          ],
        ));
  }
}

//BACKGROUND //

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    String userEmail = inputData?['userEmail'];
    String deviceName = inputData?['deviceName'];

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Leer datos de Firestore
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(userEmail)
        .doc(deviceName)
        .get();

    if (snapshot.exists) {
      print('Desgloso datos');
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      GeoPoint storedLocation = data['ubicacion']; // La ubicación almacenada
      int distanceOn =
          data['distanciaOn']; // El umbral de distancia para encendido
      int distanceOff =
          data['distanciaOff']; // El umbral de distancia para apagado

      print('Distancia guardada $storedLocation');

      Position currentPosition1 = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print(currentPosition1);

      double distance1 = Geolocator.distanceBetween(
        currentPosition1.latitude,
        currentPosition1.longitude,
        storedLocation.latitude,
        storedLocation.longitude,
      );
      print(distance1);

      await Future.delayed(const Duration(minutes: 2));

      Position currentPosition2 = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      print(currentPosition1);

      double distance2 = Geolocator.distanceBetween(
        currentPosition2.latitude,
        currentPosition2.longitude,
        storedLocation.latitude,
        storedLocation.longitude,
      );
      print(distance2);

      if (distance2.round() <= distanceOn && distance1 > distance2) {
        print('Usuario cerca, encendiendo');
        DocumentReference documentRef =
            FirebaseFirestore.instance.collection(userEmail).doc(deviceName);
        await documentRef.set({'estado': true}, SetOptions(merge: true));
        //En un futuro acá agrego las notificaciones unu
      } else if (distance2.round() >= distanceOff && distance1 < distance2) {
        print('Usuario lejos, apagando');
        //Estas re lejos apago el calefactor
        DocumentReference documentRef =
            FirebaseFirestore.instance.collection(userEmail).doc(deviceName);
        await documentRef.set({'estado': false}, SetOptions(merge: true));
      }
    }

    return Future.value(true);
  });
}

void scheduleBackgroundTask(String userEmail, String deviceName) {
  Workmanager().registerPeriodicTask(
    'ControldeDistancia', // ID único para la tarea
    "checkLocationTask", // Nombre de la tarea
    inputData: {
      'userEmail': userEmail,
      'deviceName': deviceName,
    },
    frequency:
        const Duration(minutes: 15), // Ajusta la frecuencia según sea necesario
  );
}

void cancelPeriodicTask() {
  Workmanager().cancelByUniqueName('ControldeDistancia');
}
