import 'dart:async';
import 'dart:convert';
import 'package:biocalden_smart_life/mqtt/mqtt.dart';
import 'package:biocalden_smart_life/stored_data.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:biocalden_smart_life/master.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// VARIABLES //

bool alreadySubOta = false;
List<int> varsValues = [];
bool alreadySubTools = false;
double distOnValue = 0.0;
double distOffValue = 0.0;
bool turnOn = false;
bool isTaskScheduled = false;
bool deviceOwner = false;
bool trueStatus = false;
bool userConnected = false;


late List<String> pikachu;

// FUNCIONES //

void gamerMode(int fun) {
  String data = '${command(deviceType)}[11]($fun)';
  myDevice.toolsUuid.write(data.codeUnits);
}

// CLASES //

//*-Drawer-*//Menú lateral con dispositivos

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
  String measure = deviceType == '022000' ? 'KW/h' : 'M³/h';

  @override
  void initState() {
    super.initState();
    cargarFechaGuardada();
    nightState = widget.night;
    printLog('NightMode status: $nightState');
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
      printLog('Estoy haciendo calculaciones misticas');
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
                      height: 50,
                      // width: double.infinity,
                      child:
                          Image.asset('assets/Biocalden/BiocaldenBanner.png'),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                        width: 200,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: costController,
                          style: const TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255)),
                          cursorColor: const Color.fromARGB(255, 189, 189, 189),
                          decoration: InputDecoration(
                            labelText: 'Ingresa valor $measure',
                            labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255)),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 189, 189, 189)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
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
                          String data = '${command(deviceType)}[10](0)';
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
                          printLog('Estado: $nightState');
                          int fun = nightState ? 1 : 0;
                          String data = '${command(deviceType)}[9]($fun)';
                          printLog(data);
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
                                        String mailData =
                                            '${command(deviceType)}[5](NA)';
                                        myDevice.toolsUuid
                                            .write(mailData.codeUnits);
                                        ownedDevices.remove(deviceName);
                                        saveOwnedDevices(ownedDevices);
                                        myDevice.device.disconnect();
                                        Navigator.of(dialogContext).pop();
                                      } catch (e, s) {
                                        printLog(
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
                        child: const Text('Dejar de ser administrador')),
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
                  showContactInfo(context);
                },
                child: const Text('CONTACTANOS'),
              ),
            ),
          ],
        ));
  }
}

class SilemaDrawer extends StatefulWidget {
  final bool night;
  const SilemaDrawer({super.key, required this.night});

  @override
  SilemaDrawerState createState() => SilemaDrawerState();
}

class SilemaDrawerState extends State<SilemaDrawer> {
  final TextEditingController costController = TextEditingController();
  late bool loading;
  bool buttonPressed = false;
  double result = 0.0;
  DateTime? fechaSeleccionada;
  late bool nightState;
  String measure = 'KW/h';

  @override
  void initState() {
    super.initState();
    cargarFechaGuardada();
    nightState = widget.night;
    printLog('NightMode status: $nightState');
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
      printLog('Estoy haciendo calculaciones misticas');
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    SizedBox(
                      height: 50,
                      // width: double.infinity,
                      child: Image.asset('assets/Silema/WB_Banner.png'),
                    ),
                    const SizedBox(height: 50),
                    SizedBox(
                        width: 200,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          controller: costController,
                          style: const TextStyle(
                              color: Color.fromARGB(255, 0, 0, 0)),
                          cursorColor: const Color.fromARGB(255, 189, 189, 189),
                          decoration: InputDecoration(
                            labelText: 'Ingresa valor $measure',
                            labelStyle: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0)),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color.fromARGB(255, 189, 189, 189)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
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
                              color: Color.fromARGB(255, 0, 0, 0))),
                      Visibility(
                          visible: !loading,
                          child: Text('\$$result',
                              style: const TextStyle(
                                  fontSize: 50,
                                  color: Color.fromARGB(255, 0, 0, 0)))),
                    ],
                    const SizedBox(height: 10),
                    ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 72, 72, 72)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 255, 255, 255))),
                        onPressed: makeCompute,
                        child: const Text('Hacer calculo')),
                    ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 72, 72, 72)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 255, 255, 255))),
                        onPressed: () {
                          guardarFecha();
                          String data = '${command(deviceType)}[10](0)';
                          myDevice.toolsUuid.write(data.codeUnits);
                        },
                        child: const Text('Reiniciar mes')),
                    fechaSeleccionada != null
                        ? Text(
                            'Ultimo reinicio: ${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color.fromARGB(255, 0, 0, 0)))
                        : const Text(''),
                    const SizedBox(height: 20),
                    const Text('Modo actual: ',
                        style: TextStyle(
                            fontSize: 20, color: Color.fromARGB(255, 0, 0, 0))),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          nightState = !nightState;
                          printLog('Estado: $nightState');
                          int fun = nightState ? 1 : 0;
                          String data = '${command(deviceType)}[9]($fun)';
                          printLog(data);
                          myDevice.toolsUuid.write(data.codeUnits);
                        });
                      },
                      icon: nightState
                          ? const Icon(Icons.nightlight,
                              color: Color.fromARGB(255, 0, 0, 0), size: 40)
                          : const Icon(Icons.wb_sunny,
                              color: Color.fromARGB(255, 0, 0, 0), size: 40),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 72, 72, 72)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 255, 255, 255))),
                        onPressed: () {
                          showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                backgroundColor:
                                    const Color.fromARGB(255, 255, 255, 255),
                                title: const Text(
                                  '¿Dejar de ser administrador del calefactor?',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                                content: const Text(
                                  'Esto hará que otras personas puedan conectarse al dispositivo y modificar sus parámetros',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 0, 0, 0)),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    style: const ButtonStyle(
                                        foregroundColor:
                                            MaterialStatePropertyAll(
                                                Color.fromARGB(255, 0, 0, 0))),
                                    child: const Text('Cancelar'),
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                    },
                                  ),
                                  TextButton(
                                    style: const ButtonStyle(
                                        foregroundColor:
                                            MaterialStatePropertyAll(
                                                Color.fromARGB(255, 0, 0, 0))),
                                    child: const Text('Aceptar'),
                                    onPressed: () async {
                                      try {
                                        String mailData =
                                            '${command(deviceType)}[5](NA)';
                                        myDevice.toolsUuid
                                            .write(mailData.codeUnits);
                                        ownedDevices.remove(deviceName);
                                        saveOwnedDevices(ownedDevices);
                                        myDevice.device.disconnect();
                                        Navigator.of(dialogContext).pop();
                                      } catch (e, s) {
                                        printLog(
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
                        child: const Text('Dejar de ser administrador')),
                  ],
                ),
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                    style: const ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(
                            Color.fromARGB(255, 72, 72, 72)),
                        foregroundColor: MaterialStatePropertyAll(
                            Color.fromARGB(255, 255, 255, 255))),
                    onPressed: () {
                      showContactInfo(context);
                    },
                    child: const Text('CONTACTANOS'))),
          ],
        ));
  }
}

//BACKGROUND //

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      String deviceName = inputData?['deviceName'];
      String productCode = inputData?['productCode'];
      String sn = extractSerialNumber(deviceName);

      await setupMqtt();

      double latitude = await loadLatitude();
      double longitude = await loadLongitud();
      double distanceOn = await loadDistanceON();
      double distanceOff = await loadDistanceOFF();
      globalDATA = await loadGlobalData();

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

      printLog('Distancia guardada $storedLocation');

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

      printLog('Esperando dos minutos');
      await Future.delayed(const Duration(minutes: 2));

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

      if (distance2 <= distanceOn && distance1 > distance2) {
        printLog('Usuario cerca, encendiendo');
        globalDATA
            .putIfAbsent('$productCode/$deviceSerialNumber', () => {})
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
        globalDATA
            .putIfAbsent('$productCode/$deviceSerialNumber', () => {})
            .addAll({"w_status": false});
        saveGlobalData(globalDATA);
        String topic = 'devices_rx/$productCode/$sn';
        String topic2 = 'devices_tx/$productCode/$sn';
        String message = jsonEncode({"w_status": false});
        sendMessagemqtt(topic, message);
        sendMessagemqtt(topic2, message);
        //Estas re lejos apago el calefactor
      } else {
        printLog('Ningun caso unu');
      }
      return Future.value(true);
    } catch (e, s) {
      printLog('Error en segundo plano $e');
      printLog(s);
      return Future.value(false);
    }
  });
}

void scheduleBackgroundTask(String deviceName, String productCode) {
  Workmanager().registerPeriodicTask(
    'ControldeDistancia', // ID único para la tarea
    "checkLocationTask", // Nombre de la tarea
    inputData: {
      'deviceName': deviceName,
      'productCode': productCode,
    },
    frequency:
        const Duration(minutes: 15), // Ajusta la frecuencia según sea necesario
  );
}

void cancelPeriodicTask() {
  Workmanager().cancelByUniqueName('ControldeDistancia');
}
