import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_022000iot_user/5773/master_detector.dart';
import 'package:project_022000iot_user/master.dart';

class DetectorPage extends StatefulWidget {
  const DetectorPage({super.key});
  @override
  DetectorPageState createState() => DetectorPageState();
}

class DetectorPageState extends State<DetectorPage> {
  late String nickname;
  bool werror = false;
  bool alert = false;
  String _textToShow = '';
  bool online = true;

  @override
  void initState() {
    super.initState();
    nickname = nicknamesMap[deviceName] ?? deviceName;
    _subscribeToWorkCharacteristic();
    subscribeToWifiStatus();
    listenAlert();
  }

  void listenAlert() {
    printLog('hago listen');
    FirebaseFirestore.instance
        .collection(deviceName)
        .doc('info')
        .snapshots()
        .listen((event) {
      printLog('Prueba firestore ${event.data()}');
      printLog(event.data()!['alert']);

      if (event.data()!['alert'] == true) {
        printLog('realsito');
        setState(() {
          _textToShow = 'PELIGRO';
          alert = true;
        });
      } else {
        printLog('falsito');
        setState(() {
          _textToShow = 'AIRE PURO';
          alert = false;
        });
      }
    });
  }

  void updateWifiValues(List<int> data) {
    var fun = utf8.decode(data); //Wifi status | wifi ssid | ble status(users)
    fun = fun.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    printLog(fun);
    var parts = fun.split(':');
    if (parts[0] == 'WCS_CONNECTED') {
      nameOfWifi = parts[1];
      isWifiConnected = true;
      printLog('sis $isWifiConnected');
      setState(() {
        textState = 'CONECTADO';
        statusColor = Colors.green;
        wifiIcon = Icons.wifi;
        errorMessage = '';
        errorSintax = '';
        werror = false;
      });
    } else if (parts[0] == 'WCS_DISCONNECTED') {
      isWifiConnected = false;
      printLog('non $isWifiConnected');

      setState(() {
        textState = 'DESCONECTADO';
        statusColor = Colors.red;
        wifiIcon = Icons.wifi_off;
      });

      if (parts[0] == 'WCS_DISCONNECTED' && atemp == true) {
        //If comes from subscription, parts[1] = reason of error.
        setState(() {
          wifiIcon = Icons.warning_amber_rounded;
        });

        werror = true;

        if (parts[1] == '202' || parts[1] == '15') {
          errorMessage = 'Contraseña incorrecta';
        } else if (parts[1] == '201') {
          errorMessage = 'La red especificada no existe';
        } else if (parts[1] == '1') {
          errorMessage = 'Error desconocido';
        } else {
          errorMessage = parts[1];
        }

        errorSintax = getWifiErrorSintax(int.parse(parts[1]));
      }
    }

    setState(() {});
  }

  void subscribeToWifiStatus() async {
    printLog('Se subscribio a wifi');
    await myDevice.toolsUuid.setNotifyValue(true);

    final wifiSub =
        myDevice.toolsUuid.onValueReceived.listen((List<int> status) {
      updateWifiValues(status);
    });

    myDevice.device.cancelWhenDisconnected(wifiSub);
  }

  void _subscribeToWorkCharacteristic() async {
    await myDevice.workUuid.setNotifyValue(true);

    final workSub =
        myDevice.workUuid.onValueReceived.listen((List<int> status) {
      printLog('Cositas: $status');
      setState(() {
        ppmCO = status[5] + (status[6] << 8);
        ppmCH4 = status[7] + (status[8] << 8);
        printLog('Parte baja CO: ${status[9]} // Parte alta CO: ${status[10]}');
        printLog('PPMCO: $ppmCO');
        printLog('Parte baja CH4: ${status[11]} // Parte alta CH4: ${status[12]}');
        printLog('PPMCH4: $ppmCH4');
      });
    });

    myDevice.device.cancelWhenDisconnected(workSub);
  }

  Future<void> _showEditNicknameDialog(BuildContext context) async {
    TextEditingController nicknameController =
        TextEditingController(text: nickname);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 37, 34, 35),
          title: const Text(
            'Editar identificación del dispositivo',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          content: TextField(
            style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
            cursorColor: const Color.fromARGB(255, 189, 189, 189),
            controller: nicknameController,
            decoration: const InputDecoration(
              hintText: "Introduce tu nueva identificación del dispositivo",
              hintStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(255, 189, 189, 189)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Color.fromARGB(255, 189, 189, 189)),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: const ButtonStyle(
                  foregroundColor: MaterialStatePropertyAll(
                      Color.fromARGB(255, 255, 255, 255))),
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
              },
            ),
            TextButton(
              style: const ButtonStyle(
                  foregroundColor: MaterialStatePropertyAll(
                      Color.fromARGB(255, 255, 255, 255))),
              child: const Text('Guardar'),
              onPressed: () {
                setState(() {
                  String newNickname = nicknameController.text;
                  nickname = newNickname;
                  nicknamesMap[deviceName] = newNickname; // Actualizar el mapa
                  saveNicknamesMap(nicknamesMap);
                  printLog('$nicknamesMap');
                });
                Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color.fromARGB(255, 37, 34, 35),
              content: Row(
                children: [
                  const CircularProgressIndicator(
                      color: Color.fromARGB(255, 255, 255, 255)),
                  Container(
                      margin: const EdgeInsets.only(left: 15),
                      child: const Text(
                        "Desconectando...",
                        style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255)),
                      )),
                ],
              ),
            );
          },
        );
        Future.delayed(const Duration(seconds: 2), () async {
          printLog('aca estoy');
          await myDevice.device.disconnect();
          navigatorKey.currentState?.pop();
          navigatorKey.currentState?.pushReplacementNamed('/scan');
        });

        return; // Retorna según la lógica de tu app
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 37, 34, 35),
        appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: const Color.fromARGB(255, 255, 255, 255),
            title: GestureDetector(
              onTap: () async {
                await _showEditNicknameDialog(context);
              },
              child: Text(nickname),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  wifiIcon,
                  size: 24.0,
                  semanticLabel: 'Icono de wifi',
                ),
                onPressed: () {
                  showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: const Color.fromARGB(255, 37, 34, 35),
                        title: Row(children: [
                          const Text.rich(TextSpan(
                              text: 'Estado de conexión: ',
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontSize: 14,
                              ))),
                          Text.rich(TextSpan(
                              text: textState,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)))
                        ]),
                        content: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (werror) ...[
                                Text.rich(TextSpan(
                                    text: 'Error: $errorMessage',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: Color.fromARGB(
                                            255, 255, 255, 255)))),
                                const SizedBox(height: 10),
                                Text.rich(
                                  TextSpan(
                                      text: 'Sintax: $errorSintax',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: Color.fromARGB(
                                              255, 255, 255, 255))),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Row(children: [
                                const Text.rich(TextSpan(
                                    text: 'Red actual: ',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color.fromARGB(
                                            255, 255, 255, 255)))),
                                Text.rich(TextSpan(
                                    text: nameOfWifi,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        color: Color.fromARGB(
                                            255, 255, 255, 255)))),
                              ]),
                              const SizedBox(height: 10),
                              const Text.rich(TextSpan(
                                  text: 'Ingrese los datos de WiFi',
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      fontWeight: FontWeight.bold))),
                              IconButton(
                                icon: const Icon(Icons.qr_code),
                                iconSize: 50,
                                color: const Color.fromARGB(255, 255, 255, 255),
                                onPressed: () async {
                                  PermissionStatus permissionStatusC =
                                      await Permission.camera.request();
                                  if (!permissionStatusC.isGranted) {
                                    await Permission.camera.request();
                                  }
                                  permissionStatusC =
                                      await Permission.camera.status;
                                  if (permissionStatusC.isGranted) {
                                    openQRScanner(navigatorKey.currentContext!);
                                  }
                                },
                              ),
                              TextField(
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255)),
                                cursorColor:
                                    const Color.fromARGB(255, 189, 189, 189),
                                decoration: const InputDecoration(
                                  hintText: 'Nombre de la red',
                                  hintStyle: TextStyle(
                                      color:
                                          Color.fromARGB(255, 255, 255, 255)),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 189, 189, 189)),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 189, 189, 189)),
                                  ),
                                ),
                                onChanged: (value) {
                                  wifiName = value;
                                },
                              ),
                              TextField(
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255)),
                                cursorColor:
                                    const Color.fromARGB(255, 189, 189, 189),
                                decoration: const InputDecoration(
                                  hintText: 'Contraseña',
                                  hintStyle: TextStyle(
                                      color:
                                          Color.fromARGB(255, 255, 255, 255)),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 189, 189, 189)),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                        color:
                                            Color.fromARGB(255, 189, 189, 189)),
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
                            style: const ButtonStyle(
                                foregroundColor: MaterialStatePropertyAll(
                                    Color.fromARGB(255, 255, 255, 255))),
                            child: const Text('Aceptar'),
                            onPressed: () {
                              sendWifitoBle();
                              navigatorKey.currentState?.pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ]),
        drawer: const DrawerDetector(),
        body: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 50,
              ),
              Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: alert
                        ? Colors.red
                        : Theme.of(context).primaryColorLight,
                    borderRadius: BorderRadius.circular(20),
                    border: const Border(
                      bottom: BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255), width: 5),
                      right: BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255), width: 5),
                      left: BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255), width: 5),
                      top: BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255), width: 5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _textToShow,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: alert ? Colors.white : Colors.green,
                          fontSize: 60),
                    ),
                  )),
              const SizedBox(
                height: 50,
              ),
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  border: const Border(
                    bottom: BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255), width: 5),
                    right: BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255), width: 5),
                    left: BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255), width: 5),
                    top: BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255), width: 5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'GAS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Atmósfera Explosiva',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${(ppmCH4 / 500).round()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 50,
                      ),
                    ),
                    const Text(
                      'LIE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  border: const Border(
                    bottom: BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255), width: 5),
                    right: BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255), width: 5),
                    left: BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255), width: 5),
                    top: BorderSide(
                        color: Color.fromARGB(255, 255, 255, 255), width: 5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'CO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Monóxido de carbono',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '$ppmCO',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 50,
                      ),
                    ),
                    const Text(
                      'PPM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255),
                        fontSize: 30,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(20),
                    border: const Border(
                      bottom: BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255), width: 5),
                      right: BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255), width: 5),
                      left: BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255), width: 5),
                      top: BorderSide(
                          color: Color.fromARGB(255, 255, 255, 255), width: 5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Estado: ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 30,
                        ),
                      ),
                      Text(online ? 'EN LINEA' : 'DESCONECTADO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: online ? Colors.green : Colors.red,
                              fontSize: 30,
                              fontWeight: FontWeight.bold))
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
