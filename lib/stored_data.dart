import 'dart:convert';
import 'package:biocalden_smart_life/master.dart';
import 'package:shared_preferences/shared_preferences.dart';

// MASTERLOAD \\
void loadValues() async {
  globalDATA = await loadGlobalData();
  previusConnections = await cargarLista();
  productCode = await loadProductCodesMap();
  topicsToSub = await loadTopicList();
  ownedDevices = await loadOwnedDevices();
  nicknamesMap = await loadNicknamesMap();
  actualToken = await loadToken();
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

//*-Position

Future<void> savePositionLatitude(double latitude) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('latitude', latitude);
}

Future<void> savePositionLongitud(double longitud) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('longitud', longitud);
}

Future<double> loadLatitude() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('latitude') ?? 0;
}

Future<double> loadLongitud() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('longitud') ?? 0;
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

//*-Product code

Future<void> saveProductCodesMap(Map<String, String> productCodesMap) async {
  final prefs = await SharedPreferences.getInstance();
  String productCodesMapString = json.encode(productCodesMap);
  await prefs.setString('productCodes', productCodesMapString);
}

Future<Map<String, String>> loadProductCodesMap() async {
  final prefs = await SharedPreferences.getInstance();
  String? productCodesMapString = prefs.getString('productCodes');
  if (productCodesMapString != null) {
    return Map<String, String>.from(json.decode(productCodesMapString));
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

//*-Distancias de control

Future<void> saveDistanceON(double distanceON) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('distanceON', distanceON);
}

Future<double> loadDistanceON() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('distanceON') ?? 3000;
}

Future<void> saveDistanceOFF(double distanceOFF) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setDouble('distanceOFF', distanceOFF);
}

Future<double> loadDistanceOFF() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('distanceOFF') ?? 100;
}

//*-Control de distancia

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

Future<void> saveToken(String token) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('token', token);
}

Future<String> loadToken() async {
  final prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  if (token != null) {
    return token;
  } else {
    return '';
  }
}
