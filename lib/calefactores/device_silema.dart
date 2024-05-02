// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:biocalden_smart_life/aws/mqtt/mqtt.dart';
import 'package:biocalden_smart_life/stored_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
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
      printLog('Llegaron cositas wifi');
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
    globalDATA['${productCode[deviceName]}/$deviceSerialNumber']!['w_status'] =
        on;
    saveGlobalData(globalDATA);
    try {
      String topic =
          'devices_rx/${productCode[deviceName]}/$deviceSerialNumber';
      String topic2 =
          'devices_tx/${productCode[deviceName]}/$deviceSerialNumber';
      String message = jsonEncode({'w_status': on});
      sendMessagemqtt(topic, message);
      sendMessagemqtt(topic2, message);
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

  void controlTask(bool value, String device) async {
    setState(() {
      isTaskScheduled.addAll({device: value});
    });
    if (isTaskScheduled[device]!) {
      // Programar la tarea.
      try {
        showToast('Recuerda tener la ubicación encendida.');
        List<String> deviceControl = await loadDevicesForDistanceControl();
        deviceControl.add(deviceName);
        saveDevicesForDistanceControl(deviceControl);
        printLog(
            'Hay ${deviceControl.length} equipos con el control x distancia');
        Position position = await _determinePosition();
        Map<String, double> maplatitude = await loadLatitude();
        maplatitude.addAll({deviceName: position.latitude});
        savePositionLatitude(maplatitude);
        Map<String, double> maplongitude = await loadLongitud();
        maplongitude.addAll({deviceName: position.longitude});
        savePositionLongitud(maplongitude);

        if (deviceControl.length == 1) {
          await initializeService();
          final backService = FlutterBackgroundService();
          await backService.startService();
          printLog('Servicio iniciado a las ${DateTime.now()}');
        }
      } catch (e) {
        showToast('Error al iniciar control por distancia.');
        printLog('Error al setear la ubicación $e');
      }
    } else {
      // Cancelar la tarea.
      showToast('Se cancelo el control por distancia');
      List<String> deviceControl = await loadDevicesForDistanceControl();
      deviceControl.remove(deviceName);
      saveDevicesForDistanceControl(deviceControl);
      printLog(
          'Quedan ${deviceControl.length} equipos con el control x distancia');
      Map<String, double> maplatitude = await loadLatitude();
      maplatitude.remove(deviceName);
      savePositionLatitude(maplatitude);
      Map<String, double> maplongitude = await loadLongitud();
      maplongitude.remove(deviceName);
      savePositionLongitud(maplongitude);

      if (deviceControl.isEmpty) {
        final backService = FlutterBackgroundService();
        backService.invoke("stopService");
        backTimer?.cancel();
        printLog('Servicio apagado');
      }
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
            content: Text(
                '$appName utiliza tu ubicación, incluso cuando la app esta cerrada o en desuso, para poder encender o apagar el calefactor en base a tu distancia con el mismo.',
                style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
            actions: <Widget>[
              TextButton(
                style: const ButtonStyle(
                    foregroundColor:
                        MaterialStatePropertyAll(Color.fromARGB(255, 0, 0, 0))),
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
                  child: Row(
                    children: [
                      Text(nickname),
                      const SizedBox(
                        width: 3,
                      ),
                      const Icon(
                        Icons.edit,
                        size: 20,
                      )
                    ],
                  ),
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
                                wifiText(context);
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
                                      value:
                                          isTaskScheduled[deviceName] ?? false,
                                      onChanged: (value) {
                                        verifyPermission().then((result) {
                                          if (result == true) {
                                            isTaskScheduled
                                                .addAll({deviceName: value});
                                            saveControlValue(isTaskScheduled);
                                            controlTask(value, deviceName);
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
                            if (isTaskScheduled[deviceName] ?? false) ...[
                              const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Distancia de apagado',
                                        style: TextStyle(
                                            fontSize: 20,
                                            color:
                                                Color.fromARGB(255, 0, 0, 0)))
                                  ]),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text.rich(TextSpan(
                                      text: distOffValue.round().toString(),
                                      style: const TextStyle(
                                          fontSize: 30,
                                          color:
                                              Color.fromARGB(255, 0, 0, 0)))),
                                  const Text.rich(TextSpan(
                                      text: 'Metros',
                                      style: TextStyle(
                                          fontSize: 30,
                                          color:
                                              Color.fromARGB(255, 0, 0, 0)))),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 30.0,
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
                                  value: distOffValue,
                                  divisions: 20,
                                  onChanged: (value) {
                                    setState(() {
                                      distOffValue = value;
                                    });
                                  },
                                  onChangeEnd: (value) async {
                                    printLog('Valor enviado: ${value.round()}');
                                    Map<String, double> mapOFF =
                                        await loadDistanceOFF();
                                    mapOFF.addAll({deviceName: value});
                                    saveDistanceOFF(mapOFF);
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
                                            color:
                                                Color.fromARGB(255, 0, 0, 0)))
                                  ]),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text.rich(TextSpan(
                                      text: distOnValue.round().toString(),
                                      style: const TextStyle(
                                          fontSize: 30,
                                          color:
                                              Color.fromARGB(255, 0, 0, 0)))),
                                  const Text.rich(TextSpan(
                                      text: 'Metros',
                                      style: TextStyle(
                                          fontSize: 30,
                                          color:
                                              Color.fromARGB(255, 0, 0, 0)))),
                                ],
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 30.0,
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
                                  value: distOnValue,
                                  divisions: 20,
                                  onChanged: (value) {
                                    setState(() {
                                      distOnValue = value;
                                    });
                                  },
                                  onChangeEnd: (value) async {
                                    printLog('Valor enviado: ${value.round()}');
                                    Map<String, double> mapON =
                                        await loadDistanceON();
                                    mapON.addAll({deviceName: value});
                                    saveDistanceON(mapON);
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
                                    fontSize: 25,
                                    color: Color.fromARGB(255, 0, 0, 0))),
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
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      size: 50)
                                  : const Icon(Icons.wb_sunny,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                      size: 50),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            const Text(
                                'Actualmente no eres el administador del equipo.\nNo puedes modificar los parámetros',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 25,
                                    color: Color.fromARGB(255, 0, 0, 0))),
                          ],
                        ],
                      ),
              ),
            )));
  }
}
