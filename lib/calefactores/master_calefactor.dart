import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:biocalden_smart_life/firebase_options.dart';
import 'package:biocalden_smart_life/master.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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

Future<double> readDistanceOnValue() async {
  String userEmail = currentUserEmail;

  try {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection(deviceName)
        .doc(userEmail)
        .get();
    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      return data['distanciaOn']?.toDouble() ??
          3000.0; // Retorna 100.0 si no se encuentra el campo
    } else {
      printLog("Documento no encontrado");
      return 3000.0;
    }
  } catch (e) {
    printLog("Error al leer de Firestore: $e");
    return 3000.0;
  }
}

Future<double> readDistanceOffValue() async {
  String userEmail =
      currentUserEmail;

  try {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection(deviceName)
        .doc(userEmail)
        .get();
    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>;
      return data['distanciaOff']?.toDouble() ??
          100.0; // Retorna 100.0 si no se encuentra el campo
    } else {
      printLog("Documento no encontrado");
      return 100.0;
    }
  } catch (e) {
    printLog("Error al leer de Firestore: $e");
    return 100.0;
  }
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
                      height: 50,
                      // width: double.infinity,
                      child:
                          Image.asset('assets/Biocalden/Biocalden_banner.png'),
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
                                        String userEmail = currentUserEmail;
                                        FirebaseFirestore.instance
                                            .collection(deviceName)
                                            .doc(userEmail)
                                            .delete();
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
                                                  '¡Hola! Tengo una duda comercial sobre los productos Biocalden smart: \n'),
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
                                                    'Consulta comercial calefactores smart',
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
                                                  '¡Hola! Tengo una consulta referida al área de ingenieria sobre mi equipo.\n Información del mismo:\nModelo: $deviceType\nVersión de software: $softwareVersion \nVersión de hardware: $hardwareVersion \nMi duda es la siguiente:\n'),
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
                                                    'Consulta CalefactorSmart',
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
                                        String userEmail = currentUserEmail;
                                        FirebaseFirestore.instance
                                            .collection(deviceName)
                                            .doc(userEmail)
                                            .delete();
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
                      showDialog(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                                backgroundColor:
                                    const Color.fromARGB(255, 255, 255, 255),
                                content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Contacto comercial:',
                                          style: TextStyle(
                                              color:
                                                  Color.fromARGB(255, 0, 0, 0),
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold)),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                              onPressed: () => _sendWhatsAppMessage(
                                                  '5491162234181',
                                                  '¡Hola! Tengo una duda comercial sobre los productos Biocalden smart: \n'),
                                              icon: const Icon(
                                                Icons.phone,
                                                color: Color.fromARGB(
                                                    255, 0, 0, 0),
                                                size: 20,
                                              )),
                                          // const SizedBox(width: 5),
                                          const Text('+54 9 11 6223-4181',
                                              style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0),
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
                                                    'Consulta comercial calefactores smart',
                                                    '¡Hola! mi equipo es el $deviceName y tengo la siguiente duda:\n'),
                                                icon: const Icon(
                                                  Icons.mail,
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0),
                                                  size: 20,
                                                ),
                                              ),
                                              // const SizedBox(width: 5),
                                              const Text(
                                                  'ceat@ibsanitarios.com.ar',
                                                  style: TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 0, 0, 0),
                                                      fontSize: 20))
                                            ],
                                          )),
                                      const SizedBox(height: 20),
                                      const Text('Consulta técnica:',
                                          style: TextStyle(
                                              color:
                                                  Color.fromARGB(255, 0, 0, 0),
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
                                                  '¡Hola! Tengo una consulta referida al área de ingenieria sobre mi equipo.\n Información del mismo:\nModelo: $deviceType\nVersión de software: $softwareVersion \nVersión de hardware: $hardwareVersion \nMi duda es la siguiente:\n'),
                                              icon: const Icon(
                                                Icons.mail,
                                                color: Color.fromARGB(
                                                    255, 0, 0, 0),
                                                size: 20,
                                              ),
                                            ),
                                            // const SizedBox(width: 5),
                                            const Text(
                                              'pablo@intelligentgas.com.ar',
                                              style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0),
                                                  fontSize: 20),
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      const Text('Customer service:',
                                          style: TextStyle(
                                              color:
                                                  Color.fromARGB(255, 0, 0, 0),
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
                                                color: Color.fromARGB(
                                                    255, 0, 0, 0),
                                                size: 20,
                                              )),
                                          // const SizedBox(width: 5),
                                          const Text('+54 9 11 6223-2619',
                                              style: TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0),
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
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0),
                                                  size: 20,
                                                ),
                                              ),
                                              // const SizedBox(width: 5),
                                              const Text(
                                                'service@calefactorescalden.com.ar',
                                                style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0),
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
    String deviceName = inputData?['deviceName'];

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Leer datos de Firestore
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection(deviceName)
        .doc('info')
        .get();

    if (snapshot.exists) {
      printLog('Desgloso datos');
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      GeoPoint storedLocation = data['ubicacion']; // La ubicación almacenada
      int distanceOn =
          data['distanciaOn']; // El umbral de distancia para encendido
      int distanceOff =
          data['distanciaOff']; // El umbral de distancia para apagado

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
      printLog('$distance1');

      await Future.delayed(const Duration(minutes: 2));

      Position currentPosition2 = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      printLog('$currentPosition1');

      double distance2 = Geolocator.distanceBetween(
        currentPosition2.latitude,
        currentPosition2.longitude,
        storedLocation.latitude,
        storedLocation.longitude,
      );
      printLog('$distance2');

      if (distance2.round() <= distanceOn && distance1 > distance2) {
        printLog('Usuario cerca, encendiendo');
        DocumentReference documentRef =
            FirebaseFirestore.instance.collection(deviceName).doc('info');
        await documentRef.set({'estado': true}, SetOptions(merge: true));
        //En un futuro acá agrego las notificaciones unu
      } else if (distance2.round() >= distanceOff && distance1 < distance2) {
        printLog('Usuario lejos, apagando');
        //Estas re lejos apago el calefactor
        DocumentReference documentRef =
            FirebaseFirestore.instance.collection(deviceName).doc('info');
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
