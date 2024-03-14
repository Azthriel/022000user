// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:biocalden_smart_life/master.dart';
import 'package:biocalden_smart_life/calefactores/master_calefactor.dart';

//CONTROL TAB // On Off y set temperatura

class RadiadorPage extends StatefulWidget {
  const RadiadorPage({super.key});
  @override
  RadiadorPageState createState() => RadiadorPageState();
}

class RadiadorPageState extends State<RadiadorPage> {
  var parts2 = utf8.decode(varsValues).split(':');
  late double tempValue;
  late String nickname;
  bool werror = false;

  @override
  void initState() {
    super.initState();
    printLog(parts2);
    nickname = nicknamesMap[deviceName] ?? deviceName;
    tempValue = double.parse(parts2[0]);

    printLog('Valor temp: $tempValue');
    printLog('¿Encendido? $turnOn');
    updateWifiValues(toolsValues);
    subscribeToWifiStatus();
    subscribeTrueStatus();
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

    final regex = RegExp(r'\((\d+)\)');
    final match = regex.firstMatch(parts[2]);
    int users = int.parse(match!.group(1).toString());
    printLog('Hay $users conectados');
    userConnected = users > 1 && lastUser != 1;
    lastUser = users;

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

  void subscribeTrueStatus() async {
    printLog('Me subscribo a vars');
    await myDevice.varsUuid.setNotifyValue(true);

    final trueStatusSub =
        myDevice.varsUuid.onValueReceived.listen((List<int> status) {
      var parts = utf8.decode(status).split(':');
      setState(() {
        if (parts[0] == '1') {
          trueStatus = true;
        } else {
          trueStatus = false;
        }
      });
    });

    myDevice.device.cancelWhenDisconnected(trueStatusSub);
  }

  void sendTemperature(int temp) {
    String data = '${command(deviceType)}[7]($temp)';
    myDevice.toolsUuid.write(data.codeUnits);
  }

  void turnDeviceOn(bool on) async {
    int fun = on ? 1 : 0;
    String data = '${command(deviceType)}[11]($fun)';
    myDevice.toolsUuid.write(data.codeUnits);
    try {
      DocumentReference documentRef =
          FirebaseFirestore.instance.collection(deviceName).doc('info');
      await documentRef.set({'estado': on}, SetOptions(merge: true));
    } catch (e, s) {
      printLog('Error al enviar valor a firebase $e $s');
    }
  }

  void sendValueOffToFirestore() async {
    try {
      String userEmail =
          currentUserEmail;
      DocumentReference documentRef =
          FirebaseFirestore.instance.collection(deviceName).doc(userEmail);
      await documentRef
          .set({'distanciaOff': distOffValue.round()}, SetOptions(merge: true));
    } catch (e, s) {
      printLog('Error al enviar valor a firebase $e $s');
    }
  }

  void sendValueOnToFirestore() async {
    try {
      String userEmail =
          currentUserEmail;
      DocumentReference documentRef =
          FirebaseFirestore.instance.collection(deviceName).doc(userEmail);
      await documentRef
          .set({'distanciaOn': distOnValue.round()}, SetOptions(merge: true));
    } catch (e, s) {
      printLog('Error al enviar valor a firebase $e $s');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      showToast('La ubicación esta desactivada\nPor favor enciendala');
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }
    // Cuando los permisos están OK, obtenemos la ubicación actual
    return await Geolocator.getCurrentPosition();
  }

  Future<void> _showEditNicknameDialog(BuildContext context) async {
    TextEditingController nicknameController =
        TextEditingController(text: nickname);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: const Text(
            'Editar identificación del dispositivo',
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
          content: TextField(
            style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            cursorColor: const Color.fromARGB(255, 189, 189, 189),
            controller: nicknameController,
            decoration: const InputDecoration(
              hintText: "Introduce tu nueva identificación del dispositivo",
              hintStyle: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
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
                  foregroundColor:
                      MaterialStatePropertyAll(Color.fromARGB(255, 0, 0, 0))),
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
              },
            ),
            TextButton(
              style: const ButtonStyle(
                  foregroundColor:
                      MaterialStatePropertyAll(Color.fromARGB(255, 0, 0, 0))),
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

  void controlTask(bool value) async {
    setState(() {
      isTaskScheduled = value;
    });
    if (isTaskScheduled) {
      // Programar la tarea.
      try {
        showToast('Recuerda tener la ubicación encendida.');

        Position position = await _determinePosition();
        String userEmail =
            currentUserEmail;
        DocumentReference documentRef =
            FirebaseFirestore.instance.collection(deviceName).doc(userEmail);
        await documentRef.set(
            {'ubicacion': GeoPoint(position.latitude, position.longitude)},
            SetOptions(merge: true));

        scheduleBackgroundTask(userEmail, deviceName);
      } catch (e) {
        showToast('Error al iniciar control por distancia.');
        printLog('Error al setear la ubicación $e');
      }
    } else {
      // Cancelar la tarea.
      showToast('Se cancelo el control por distancia');
      cancelPeriodicTask();
    }
  }

  Future<bool> verifyPermission() async {
    var permissionStatus4 = await Permission.locationAlways.status;
    if (!permissionStatus4.isGranted) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            title: const Text(
              'Habilita la ubicación todo el tiempo',
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
            ),
            content: const Text(
                'Calefactor Smart utiliza tu ubicación, incluso cuando la app esta cerrada o en desuso, para poder encender o apagar el calefactor en base a tu distancia con el mismo.',
                style: TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
            actions: <Widget>[
              TextButton(
                style: const ButtonStyle(
                    foregroundColor: MaterialStatePropertyAll(
                        Color.fromARGB(255, 0, 0, 0))),
                child: const Text('Habilitar'),
                onPressed: () async {
                  var permissionStatus4 =
                      await Permission.locationAlways.request();

                  if (!permissionStatus4.isGranted) {
                    await Permission.locationAlways.request();
                  }
                  permissionStatus4 = await Permission.locationAlways.status;

                  Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
                },
              ),
            ],
          );
        },
      );
    }

    permissionStatus4 = await Permission.locationAlways.status;

    if (permissionStatus4.isGranted) {
      return true;
    } else {
      return false;
    }
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
                backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                content: Row(
                  children: [
                    const CircularProgressIndicator(
                        color: Color.fromARGB(255, 0, 0, 0)),
                    Container(
                        margin: const EdgeInsets.only(left: 15),
                        child: const Text(
                          "Desconectando...",
                          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
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
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            appBar: AppBar(
                backgroundColor: Colors.transparent,
                foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                title: GestureDetector(
                  onTap: () async {
                    await _showEditNicknameDialog(context);
                  },
                  child: Text(nickname),
                ),
                actions: userConnected
                    ? null
                    : deviceOwner
                        ? <Widget>[
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
                                      backgroundColor: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      title: Row(children: [
                                        const Text.rich(TextSpan(
                                            text: 'Estado de conexión: ',
                                            style: TextStyle(
                                              color:
                                                  Color.fromARGB(255, 0, 0, 0),
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
                                                          255, 0, 0, 0)))),
                                              const SizedBox(height: 10),
                                              Text.rich(
                                                TextSpan(
                                                    text:
                                                        'Sintax: $errorSintax',
                                                    style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Color.fromARGB(
                                                            255, 0, 0, 0))),
                                              ),
                                            ],
                                            const SizedBox(height: 10),
                                            Row(children: [
                                              const Text.rich(TextSpan(
                                                  text: 'Red actual: ',
                                                  style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromARGB(
                                                          255, 0, 0, 0)))),
                                              Text.rich(TextSpan(
                                                  text: nameOfWifi,
                                                  style: const TextStyle(
                                                      fontSize: 20,
                                                      color: Color.fromARGB(
                                                          255, 0, 0, 0)))),
                                            ]),
                                            const SizedBox(height: 10),
                                            const Text.rich(TextSpan(
                                                text:
                                                    'Ingrese los datos de WiFi',
                                                style: TextStyle(
                                                    fontSize: 20,
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0),
                                                    fontWeight:
                                                        FontWeight.bold))),
                                            IconButton(
                                              icon: const Icon(Icons.qr_code),
                                              iconSize: 50,
                                              color: const Color.fromARGB(
                                                  255, 0, 0, 0),
                                              onPressed: () async {
                                                PermissionStatus
                                                    permissionStatusC =
                                                    await Permission.camera
                                                        .request();
                                                if (!permissionStatusC
                                                    .isGranted) {
                                                  await Permission.camera
                                                      .request();
                                                }
                                                permissionStatusC =
                                                    await Permission
                                                        .camera.status;
                                                if (permissionStatusC
                                                    .isGranted) {
                                                  openQRScanner(navigatorKey
                                                      .currentContext!);
                                                }
                                              },
                                            ),
                                            TextField(
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0)),
                                              cursorColor: const Color.fromARGB(
                                                  255, 189, 189, 189),
                                              decoration: const InputDecoration(
                                                hintText: 'Nombre de la red',
                                                hintStyle: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0)),
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 189, 189, 189)),
                                                ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 189, 189, 189)),
                                                ),
                                              ),
                                              onChanged: (value) {
                                                wifiName = value;
                                              },
                                            ),
                                            TextField(
                                              style: const TextStyle(
                                                  color: Color.fromARGB(
                                                      255, 0, 0, 0)),
                                              cursorColor: const Color.fromARGB(
                                                  255, 189, 189, 189),
                                              decoration: const InputDecoration(
                                                hintText: 'Contraseña',
                                                hintStyle: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0)),
                                                enabledBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 189, 189, 189)),
                                                ),
                                                focusedBorder:
                                                    UnderlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 189, 189, 189)),
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
                                              foregroundColor:
                                                  MaterialStatePropertyAll(
                                                      Color.fromARGB(
                                                          255, 0, 0, 0))),
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
                          ]
                        : null),
            drawer: userConnected
                ? null
                : deviceOwner
                    ? SilemaDrawer(
                        night: nightMode,
                      )
                    : null,
            body: SingleChildScrollView(
              child: Center(
                child: userConnected
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 50,
                            ),
                            Text(
                                'Actualmente hay un usuario usando el radiador',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 28,
                                    color: Color.fromARGB(255, 0, 0, 0))),
                            Text('Espere a que se desconecte para poder usarla',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 28,
                                    color: Color.fromARGB(255, 0, 0, 0))),
                            SizedBox(
                              height: 20,
                            ),
                            CircularProgressIndicator(
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          deviceOwner
                              ? const SizedBox(height: 0)
                              : const Text('Estado:',
                                  style: TextStyle(
                                      fontSize: 30,
                                      color: Color.fromARGB(255, 0, 0, 0))),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text.rich(TextSpan(
                                    text: turnOn
                                        ? trueStatus
                                            ? 'Calentando'
                                            : 'Encendido'
                                        : 'Apagado',
                                    style: TextStyle(
                                        color: turnOn
                                            ? trueStatus
                                                ? Colors.amber[600]
                                                : Colors.green
                                            : Colors.red,
                                        fontSize: 30))),
                                if (trueStatus) ...[
                                  Icon(Icons.flash_on_rounded,
                                      size: 30, color: Colors.amber[600]),
                                ]
                              ]),
                          if (deviceOwner) ...[
                            const SizedBox(height: 30),
                            Transform.scale(
                              scale: 3.0,
                              child: Switch(
                                activeColor:
                                    const Color.fromARGB(255, 189, 189, 189),
                                activeTrackColor:
                                    const Color.fromARGB(255, 72, 72, 72),
                                inactiveThumbColor:
                                    const Color.fromARGB(255, 72, 72, 72),
                                inactiveTrackColor:
                                    const Color.fromARGB(255, 189, 189, 189),
                                value: turnOn,
                                onChanged: (value) {
                                  turnDeviceOn(value);
                                  setState(() {
                                    turnOn = value;
                                  });
                                },
                              ),
                            ),
                          ],
                          const SizedBox(height: 50),
                          const Text('Temperatura de corte:',
                              style: TextStyle(
                                  fontSize: 25,
                                  color: Color.fromARGB(255, 0, 0, 0))),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text.rich(TextSpan(
                                  text: tempValue.round().toString(),
                                  style: const TextStyle(
                                      fontSize: 30,
                                      color: Color.fromARGB(255, 0, 0, 0)))),
                              const Text.rich(TextSpan(
                                  text: '°C',
                                  style: TextStyle(
                                      fontSize: 30,
                                      color: Color.fromARGB(255, 0, 0, 0)))),
                            ],
                          ),
                          if (deviceOwner) ...[
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 50.0,
                                thumbColor:
                                    const Color.fromARGB(255, 72, 72, 72),
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 0.0,
                                ),
                              ),
                              child: Slider(
                                activeColor:
                                    const Color.fromARGB(255, 72, 72, 72),
                                inactiveColor:
                                    const Color.fromARGB(255, 189, 189, 189),
                                value: tempValue,
                                onChanged: (value) {
                                  setState(() {
                                    tempValue = value;
                                  });
                                },
                                onChangeEnd: (value) {
                                  printLog('$value');
                                  sendTemperature(value.round());
                                },
                                min: 10,
                                max: 40,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Activar control\n por distancia:',
                                      style: TextStyle(
                                          fontSize: 25,
                                          color: Color.fromARGB(255, 0, 0, 0))),
                                  const SizedBox(width: 30),
                                  Transform.scale(
                                    scale: 1.5,
                                    child: Switch(
                                      activeColor: const Color.fromARGB(
                                          255, 189, 189, 189),
                                      activeTrackColor:
                                          const Color.fromARGB(255, 72, 72, 72),
                                      inactiveThumbColor:
                                          const Color.fromARGB(255, 72, 72, 72),
                                      inactiveTrackColor: const Color.fromARGB(
                                          255, 189, 189, 189),
                                      value: isTaskScheduled,
                                      onChanged: (value) {
                                        verifyPermission().then((result) {
                                          if (result == true) {
                                            saveControlValue(value);
                                            controlTask(value);
                                          } else {
                                            showToast(
                                                'Permitir ubicación todo el tiempo\nPara poder usar el control por distancia');
                                            openAppSettings();
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ]),
                            const SizedBox(height: 25),
                            if (isTaskScheduled) ...[
                              const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Distancia de apagado',
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Color.fromARGB(255, 0, 0, 0)))
                                  ]),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text.rich(TextSpan(
                                      text: distOffValue.round().toString(),
                                      style: const TextStyle(
                                          fontSize: 30,
                                          color: Color.fromARGB(255, 0, 0, 0)))),
                                  const Text.rich(TextSpan(
                                      text: 'Metros',
                                      style: TextStyle(
                                          fontSize: 30,
                                          color: Color.fromARGB(255, 0, 0, 0)))),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 30.0,
                                  thumbColor: const Color.fromARGB(255, 72, 72, 72),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 0.0,
                                  ),
                                ),
                                child: Slider(
                                activeColor:
                                    const Color.fromARGB(255, 72, 72, 72),
                                inactiveColor:
                                    const Color.fromARGB(255, 189, 189, 189),
                                  value: distOffValue,
                                  divisions: 20,
                                  onChanged: (value) {
                                    setState(() {
                                      distOffValue = value;
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    printLog('Valor enviado: ${value.round()}');
                                    sendValueOffToFirestore();
                                  },
                                  min: 100,
                                  max: 300,
                                ),
                              ),
                              const SizedBox(height: 0),
                              const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Distancia de encendido',
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Color.fromARGB(255, 0, 0, 0)))
                                  ]),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text.rich(TextSpan(
                                      text: distOnValue.round().toString(),
                                      style: const TextStyle(
                                          fontSize: 30,
                                          color: Color.fromARGB(255, 0, 0, 0)))),
                                  const Text.rich(TextSpan(
                                      text: 'Metros',
                                      style: TextStyle(
                                          fontSize: 30,
                                          color: Color.fromARGB(255, 0, 0, 0)))),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 30.0,
                                  thumbColor: const Color.fromARGB(255, 72, 72, 72),
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 0.0,
                                  ),
                                ),
                                child: Slider(
                                activeColor:
                                    const Color.fromARGB(255, 72, 72, 72),
                                inactiveColor:
                                    const Color.fromARGB(255, 189, 189, 189),
                                  value: distOnValue,
                                  divisions: 20,
                                  onChanged: (value) {
                                    setState(() {
                                      distOnValue = value;
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    printLog('Valor enviado: ${value.round()}');
                                    sendValueOnToFirestore();
                                  },
                                  min: 3000,
                                  max: 5000,
                                ),
                              ),
                            ]
                          ] else ...[
                            const SizedBox(height: 30),
                            const Text('Modo actual: ',
                                style: TextStyle(
                                    fontSize: 25, color: Color.fromARGB(255, 0, 0, 0))),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  nightMode = !nightMode;
                                  printLog('Estado: $nightMode');
                                  int fun = nightMode ? 1 : 0;
                                  String data =
                                      '${command(deviceType)}[9]($fun)';
                                  printLog(data);
                                  myDevice.toolsUuid.write(data.codeUnits);
                                });
                              },
                              icon: nightMode
                                  ? const Icon(Icons.nightlight,
                                      color: Color.fromARGB(255, 0, 0, 0), size: 50)
                                  : const Icon(Icons.wb_sunny,
                                      color: Color.fromARGB(255, 0, 0, 0), size: 50),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            const Text(
                                'Actualmente no eres el administador del equipo.\nNo puedes modificar los parámetros',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 25, color: Color.fromARGB(255, 0, 0, 0))),
                          ],
                        ],
                      ),
              ),
            )));
  }
}
