import 'dart:convert';

import 'package:biocalden_smart_life/027313/master_relay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../aws/dynamo/dynamo.dart';
import '../aws/dynamo/dynamo_certificates.dart';
import '../aws/mqtt/mqtt.dart';
import '../master.dart';
import '../stored_data.dart';

class RelayPage extends StatefulWidget {
  const RelayPage({Key? key}) : super(key: key);

  @override
  RelayPageState createState() => RelayPageState();
}

class RelayPageState extends State<RelayPage> {
  late String nickname;

  List<bool> isSelected = [true, false]; // NA by default

  @override
  initState() {
    super.initState();
    if (deviceOwner) {
      if (vencimientoAdmSec < 10 && vencimientoAdmSec > 0) {
        showPaymentTest(true, vencimientoAdmSec, navigatorKey.currentContext!);
      }

      if (vencimientoAT < 10 && vencimientoAT > 0) {
        showPaymentTest(false, vencimientoAT, navigatorKey.currentContext!);
      }
    }
    nickname = nicknamesMap[deviceName] ?? deviceName;
    isNA = relayNA.contains(deviceName);
    printLog('Soy NA? $isNA');
    updateWifiValues(toolsValues);
    subscribeToWifiStatus();
    printLog('¿Encendido? $turnOn');
    subscribeTrueStatus();
  }

  void updateWifiValues(List<int> data) {
    var fun = utf8.decode(data); //Wifi status | wifi ssid | ble status(users)
    fun = fun.replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    printLog(fun);
    var parts = fun.split(':');
    if (parts[0] == 'WCS_CONNECTED') {
      atemp = false;
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

      nameOfWifi = '';

      setState(() {
        textState = 'DESCONECTADO';
        statusColor = Colors.red;
        wifiIcon = Icons.wifi_off;
      });

      if (atemp) {
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

  Future<void> _showEditNicknameDialog(BuildContext context) async {
    TextEditingController nicknameController =
        TextEditingController(text: nickname);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff1f1d20),
          title: const Text(
            'Editar identificación del dispositivo',
            style: TextStyle(
              color: Color(0xffa79986),
            ),
          ),
          content: TextField(
            style: const TextStyle(
              color: Color(0xffa79986),
            ),
            cursorColor: const Color(0xffa79986),
            controller: nicknameController,
            decoration: const InputDecoration(
              hintText: "Introduce tu nueva identificación del dispositivo",
              hintStyle: TextStyle(
                color: Color(0xffa79986),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xffa79986),
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Color(0xffa79986),
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: const ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  Color(0xffa79986),
                ),
              ),
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
              },
            ),
            TextButton(
              style: const ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  Color(0xffa79986),
                ),
              ),
              child: const Text('Guardar'),
              onPressed: () {
                setState(() {
                  String newNickname = nicknameController.text;
                  nickname = newNickname;
                  nicknamesMap.addAll({deviceName: newNickname});
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

  Future<void> _showCupertinoEditNicknameDialog(BuildContext context) async {
    TextEditingController nicknameController =
        TextEditingController(text: nickname);

    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text(
            'Editar identificación del dispositivo',
            style: TextStyle(
              color: CupertinoColors.label,
            ),
          ),
          content: CupertinoTextField(
            style: const TextStyle(
              color: CupertinoColors.label,
            ),
            cursorColor: const Color(0xffa79986),
            controller: nicknameController,
            placeholder: "Introduce tu nueva identificación del dispositivo",
            placeholderStyle: const TextStyle(
              color: CupertinoColors.label,
            ),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.label,
                ),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: const ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  CupertinoColors.label,
                ),
              ),
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
              },
            ),
            TextButton(
              style: const ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(
                  CupertinoColors.label,
                ),
              ),
              child: const Text('Guardar'),
              onPressed: () {
                setState(() {
                  String newNickname = nicknameController.text;
                  nickname = newNickname;
                  nicknamesMap.addAll({deviceName: newNickname});
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

  void subscribeTrueStatus() async {
    printLog('Me subscribo a vars');
    await myDevice.varsUuid.setNotifyValue(true);

    final trueStatusSub =
        myDevice.varsUuid.onValueReceived.listen((List<int> status) {
      var parts = utf8.decode(status).split(':');
      setState(() {
        turnOn = parts[0] == '1';
      });
    });

    myDevice.device.cancelWhenDisconnected(trueStatusSub);
  }

  void turnDeviceOn(bool on) {
    int fun = on ? 1 : 0;
    String data = '${command(deviceName)}[11]($fun)';
    myDevice.toolsUuid.write(data.codeUnits);
    deviceSerialNumber = extractSerialNumber(deviceName);
    globalDATA['${command(deviceName)}/$deviceSerialNumber']!['w_status'] = on;
    saveGlobalData(globalDATA);
    String topic = 'devices_rx/${command(deviceName)}/$deviceSerialNumber';
    String topic2 = 'devices_tx/${command(deviceName)}/$deviceSerialNumber';
    String message = jsonEncode({"w_status": on});
    sendMessagemqtt(topic, message);
    sendMessagemqtt(topic2, message);
  }

  Future<bool> verifyPermission() async {
    try {
      var permissionStatus4 = await Permission.locationAlways.status;
      if (!permissionStatus4.isGranted) {
        await showDialog<void>(
          context: navigatorKey.currentContext ?? context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              backgroundColor: const Color(0xFF252223),
              title: const Text(
                'Habilita la ubicación todo el tiempo',
                style: TextStyle(color: Color(0xFFFFFFFF)),
              ),
              content: Text(
                '$appName utiliza tu ubicación, incluso cuando la app esta cerrada o en desuso, para poder encender o apagar el calefactor en base a tu distancia con el mismo.',
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  style: const ButtonStyle(
                    foregroundColor: WidgetStatePropertyAll(
                      Color(0xFFFFFFFF),
                    ),
                  ),
                  child: const Text('Habilitar'),
                  onPressed: () async {
                    try {
                      var permissionStatus4 =
                          await Permission.locationAlways.request();

                      if (!permissionStatus4.isGranted) {
                        await Permission.locationAlways.request();
                      }
                      permissionStatus4 =
                          await Permission.locationAlways.status;
                    } catch (e, s) {
                      printLog(e);
                      printLog(s);
                    }
                    Navigator.of(navigatorKey.currentContext ?? context).pop();
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
    } catch (e, s) {
      printLog('Error al habilitar la ubi: $e');
      printLog(s);
      return false;
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

  void controlTask(bool value, String device) async {
    setState(() {
      isTaskScheduled.addAll({device: value});
    });
    if (isTaskScheduled[device]!) {
      // Programar la tarea.
      try {
        showToast('Recuerda tener la ubicación encendida.');
        String data = '${command(deviceName)}[5](1)';
        myDevice.toolsUuid.write(data.codeUnits);
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
          await backService.isRunning()
              ? null
              : await backService.startService();
          backService.invoke('distanceControl');
          printLog('Servicio iniciado a las ${DateTime.now()}');
        }
      } catch (e) {
        showToast('Error al iniciar control por distancia.');
        printLog('Error al setear la ubicación $e');
      }
    } else {
      // Cancelar la tarea.
      showToast('Se cancelo el control por distancia');
      String data = '${command(deviceName)}[5](0)';
      myDevice.toolsUuid.write(data.codeUnits);
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

//!Visual
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, A) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xff1f1d20),
              content: Row(
                children: [
                  const CircularProgressIndicator(color: Color(0xffa79986)),
                  Container(
                    margin: const EdgeInsets.only(left: 15),
                    child: const Text(
                      "Desconectando...",
                      style: TextStyle(
                        color: Color(0xffa79986),
                      ),
                    ),
                  ),
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
        backgroundColor: const Color(0xff1f1d20),
        appBar: AppBar(
            backgroundColor: const Color(0xff4b2427),
            foregroundColor: const Color(0xffa79986),
            leading: !android
                ? IconButton(
                    onPressed: () {
                      showCupertinoDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return CupertinoAlertDialog(
                            content: Row(
                              children: [
                                const CupertinoActivityIndicator(
                                    color: CupertinoColors.label),
                                Container(
                                    margin: const EdgeInsets.only(left: 15),
                                    child: const Text("Desconectando...",
                                        style: TextStyle(
                                            color: CupertinoColors.label))),
                              ],
                            ),
                          );
                        },
                      );
                      Future.delayed(const Duration(seconds: 2), () async {
                        printLog('aca estoy');
                        await myDevice.device.disconnect();
                        navigatorKey.currentState?.pop();
                        navigatorKey.currentState
                            ?.pushReplacementNamed('/scan');
                      });
                    },
                    icon: const Icon(Icons.arrow_back_ios))
                : null,
            title: GestureDetector(
              onTap: () async {
                android
                    ? await _showEditNicknameDialog(context)
                    : await _showCupertinoEditNicknameDialog(context);
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
            actions: <Widget>[
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
            ]),
        drawer: deviceOwner ? const RelayDrawer() : null,
        body: Center(
          child: deviceOwner || secondaryAdmin
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      turnOn
                          ? isNA
                              ? 'CERRADO'
                              : 'ABIERTO'
                          : isNA
                              ? 'ABIERTO'
                              : 'CERRADO',
                      style: const TextStyle(
                          color: Color(0xffa79986), fontSize: 30),
                    ),
                    const SizedBox(height: 30),
                    Transform.scale(
                      scale: 3.0,
                      child: Switch(
                        trackOutlineColor:
                            const WidgetStatePropertyAll(Color(0xff4b2427)),
                        activeColor: const Color(0xffa79986),
                        activeTrackColor: const Color(0xff4b2427),
                        inactiveThumbColor: const Color(0xff4b2427),
                        inactiveTrackColor: const Color(0xffa79986),
                        value: turnOn,
                        onChanged: (value) {
                          turnDeviceOn(value);
                          setState(() {
                            turnOn = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 50),
                    const Divider(),
                    if (canControlDistance) ...[
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Activar control\n por distancia:',
                                style: TextStyle(
                                    fontSize: 25, color: Color(0xffa79986))),
                            const SizedBox(width: 30),
                            Transform.scale(
                              scale: 1.5,
                              child: Switch(
                                trackOutlineColor: const WidgetStatePropertyAll(
                                    Color(0xff4b2427)),
                                activeColor: const Color(0xffa79986),
                                activeTrackColor: const Color(0xff4b2427),
                                inactiveThumbColor: const Color(0xff4b2427),
                                inactiveTrackColor: const Color(0xffa79986),
                                value: isTaskScheduled[deviceName] ?? false,
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
                                      fontSize: 20, color: Color(0xffa79986)))
                            ]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: distOffValue.round().toString(),
                                style: const TextStyle(
                                  fontSize: 30,
                                  color: Color(0xffa79986),
                                ),
                              ),
                            ),
                            const Text.rich(
                              TextSpan(
                                text: 'Metros',
                                style: TextStyle(
                                  fontSize: 30,
                                  color: Color(0xffa79986),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 30.0,
                            thumbColor: const Color(0xff4b2427),
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 16.0,
                                disabledThumbRadius: 16.0,
                                elevation: 0.0,
                                pressedElevation: 0.0),
                          ),
                          child: Slider(
                            activeColor: const Color(0xff4b2427),
                            inactiveColor: const Color(0xffa79986),
                            value: distOffValue,
                            divisions: 20,
                            onChanged: (value) {
                              setState(() {
                                distOffValue = value;
                              });
                            },
                            onChangeEnd: (value) async {
                              printLog('Valor enviado: ${value.round()}');
                              putDistanceOff(
                                  service,
                                  command(deviceName),
                                  extractSerialNumber(deviceName),
                                  value.toString());
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
                                      fontSize: 20, color: Color(0xffa79986)))
                            ]),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text.rich(
                              TextSpan(
                                text: distOnValue.round().toString(),
                                style: const TextStyle(
                                  fontSize: 30,
                                  color: Color(0xffa79986),
                                ),
                              ),
                            ),
                            const Text.rich(
                              TextSpan(
                                text: 'Metros',
                                style: TextStyle(
                                  fontSize: 30,
                                  color: Color(0xffa79986),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 30.0,
                            thumbColor: const Color(0xff4b2427),
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 16.0,
                                disabledThumbRadius: 16.0,
                                elevation: 0.0,
                                pressedElevation: 0.0),
                          ),
                          child: Slider(
                            activeColor: const Color(0xff4b2427),
                            inactiveColor: const Color(0xffa79986),
                            value: distOnValue,
                            divisions: 20,
                            onChanged: (value) {
                              setState(() {
                                distOnValue = value;
                              });
                            },
                            onChangeEnd: (value) {
                              printLog('Valor enviado: ${value.round()}');
                              putDistanceOn(
                                  service,
                                  command(deviceName),
                                  extractSerialNumber(deviceName),
                                  value.toString());
                            },
                            min: 3000,
                            max: 5000,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ]
                    ]
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No sos el dueño del equipo.\nNo puedes modificar los parámetros',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 25, color: Color(0xffa79986)),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: const ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          Color(0xff4b2427),
                        ),
                        foregroundColor: WidgetStatePropertyAll(
                          Color(0xffa79986),
                        ),
                      ),
                      onPressed: () async {
                        var phoneNumber = '5491162232619';
                        var message =
                            'Hola, te hablo en relación a mi equipo $deviceName.\nEste mismo me dice que no soy administrador.\n*Datos del equipo:*\nCódigo de producto: ${command(deviceName)}\nNúmero de serie: ${extractSerialNumber(deviceName)}\nAdministrador actúal: ${utf8.decode(infoValues).split(':')[4]}';
                        var whatsappUrl =
                            "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeFull(message)}";
                        Uri uri = Uri.parse(whatsappUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          showToast('No se pudo abrir WhatsApp');
                        }
                      },
                      child: const Text('Servicio técnico'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
