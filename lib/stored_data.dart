import 'dart:convert';
import '/aws/dynamo/dynamo_certificates.dart';
import '/aws/dynamo/dynamo.dart';
import 'master.dart';
import 'package:shared_preferences/shared_preferences.dart';

// MASTERLOAD \\
void loadValues() async {
  globalDATA = await loadGlobalData();
  previusConnections = await cargarLista();
  topicsToSub = await loadTopicList();
  nicknamesMap = await loadNicknamesMap();
  tokensOfDevices = await loadToken();
  subNicknamesMap = await loadSubNicknamesMap();
  notificationMap = await loadNotificationMap();

  for (var device in previusConnections) {
    await queryItems(
        service, command(device), extractSerialNumber(device));
  }
}
// MASTERLOAD \\

//*-Dispositivos conectados
Future<void> guardarLista(List<String> listaDispositivos) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('dispositivos_conectados', listaDispositivos);
}

Future<List<String>> cargarLista() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('dispositivos_conectados') ?? [];
}

//*-Topics mqtt
Future<void> saveTopicList(List<String> listatopics) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('Topics', listatopics);
}

Future<List<String>> loadTopicList() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('Topics') ?? [];
}

//*-Nicknames

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

//*-SubNicknames

Future<void> saveSubNicknamesMap(Map<String, String> nicknamesMap) async {
  final prefs = await SharedPreferences.getInstance();
  String nicknamesString = json.encode(nicknamesMap);
  await prefs.setString('subNicknamesMap', nicknamesString);
}

Future<Map<String, String>> loadSubNicknamesMap() async {
  final prefs = await SharedPreferences.getInstance();
  String? nicknamesString = prefs.getString('subNicknamesMap');
  if (nicknamesString != null) {
    return Map<String, String>.from(json.decode(nicknamesString));
  }
  return {}; // Devuelve un mapa vacío si no hay nada almacenado
}

//*-GlobalDATA

Future<void> saveGlobalData(
    Map<String, Map<String, dynamic>> globalData) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  Map<String, String> stringMap = globalData.map((key, value) {
    return MapEntry(key, json.encode(value));
  });
  await prefs.setString('globalData', json.encode(stringMap));
}

Future<Map<String, Map<String, dynamic>>> loadGlobalData() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? jsonString = prefs.getString('globalData');
  if (jsonString == null) {
    return {};
  }
  Map<String, dynamic> stringMap =
      json.decode(jsonString) as Map<String, dynamic>;
  Map<String, Map<String, dynamic>> globalData = stringMap.map((key, value) {
    return MapEntry(key, json.decode(value) as Map<String, dynamic>);
  });
  return globalData;
}

//*-Position

Future<void> savePositionLatitude(Map<String, double> latitudeMap) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String latitude = json.encode(latitudeMap);
  await prefs.setString('latitude', latitude);
}

Future<Map<String, double>> loadLatitude() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? latitude = prefs.getString('latitude');
  if (latitude != null) {
    return Map<String, double>.from(json.decode(latitude));
  }
  return {};
}

Future<void> savePositionLongitud(Map<String, double> longitudMap) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String longitud = json.encode(longitudMap);
  await prefs.setString('longitud', longitud);
}

Future<Map<String, double>> loadLongitud() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? longitud = prefs.getString('longitud');
  if (longitud != null) {
    return Map<String, double>.from(json.decode(longitud));
  }
  return {};
}

//*-Control de distancia habilitado

Future<void> saveControlValue(Map<String, bool> taskMap) async {
  final prefs = await SharedPreferences.getInstance();
  String taskMapString = json.encode(taskMap);
  await prefs.setString('taskMap', taskMapString);
}

Future<Map<String, bool>> loadControlValue() async {
  final prefs = await SharedPreferences.getInstance();
  String? taskMapString = prefs.getString('taskMap');
  if (taskMapString != null) {
    return Map<String, bool>.from(json.decode(taskMapString));
  }
  return {}; // Devuelve un mapa vacío si no hay nada almacenado
}

//*-DevicesForDistanceControl

Future<void> saveDevicesForDistanceControl(List<String> devices) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setStringList('DevicesForDistanceControl', devices);
}

Future<List<String>> loadDevicesForDistanceControl() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getStringList('DevicesForDistanceControl') ?? [];
}

//*-NotificationOn List

Future<void> saveNotificationMap(Map<String, List<bool>> map) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String jsonString = json.encode(map);
  await prefs.setString('NotificationMap', jsonString);
}

Future<Map<String, List<bool>>> loadNotificationMap() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? jsonString = prefs.getString('NotificationMap');
  Map<String, List<bool>> map = jsonString != null
      ? Map.from(json.decode(jsonString)).map((key, value) {
          List<bool> boolList = List<bool>.from(value);
          return MapEntry(key, boolList);
        })
      : {};

  return map;
}

//*-Owned Devices

Future<void> saveOwnedDevices(List<String> lista) async {
  final prefs = await SharedPreferences.getInstance();
  String devicesList = json.encode(lista);
  await prefs.setString('OwnedDevices', devicesList);
}

Future<List<String>> loadOwnedDevices() async {
  final prefs = await SharedPreferences.getInstance();
  String? devicesList = prefs.getString('OwnedDevices');
  if (devicesList != null) {
    List<dynamic> decodedList = json.decode(devicesList);
    return decodedList.cast<String>();
  }
  return []; // Devuelve una lista vacía si no hay nada almacenado
}

//*- Token FCM

Future<void> saveToken(Map<String, String> token) async {
  final prefs = await SharedPreferences.getInstance();
  String tokenString = json.encode(token);
  await prefs.setString('tokens', tokenString);
}

Future<Map<String, String>> loadToken() async {
  final prefs = await SharedPreferences.getInstance();
  String? tokenString = prefs.getString('tokens');
  if (tokenString != null) {
    return Map<String, String>.from(json.decode(tokenString));
  }
  return {}; // Devuelve un mapa vacío si no hay nada almacenado
}
//*-Fecha reinicio

Future<void> guardarFecha(String device) async {
  DateTime now = DateTime.now();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setInt('year$device', now.year);
  await prefs.setInt('month$device', now.month);
  await prefs.setInt('day$device', now.day);
}

Future<DateTime?> cargarFechaGuardada(String device) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  int? year = prefs.getInt('year$device');
  int? month = prefs.getInt('month$device');
  int? day = prefs.getInt('day$device');
  if (year != null && month != null && day != null) {
    return DateTime(year, month, day);
  } else {
    return null;
  }
}
