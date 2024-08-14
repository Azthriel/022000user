import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../aws/dynamo/dynamo.dart';
import '../aws/dynamo/dynamo_certificates.dart';
import '/020010/master_ionout.dart';
import '/master.dart';
import '/stored_data.dart';
import 'package:flutter/material.dart';

class IODevices extends StatefulWidget {
  const IODevices({super.key});
  @override
  IODevicesState createState() => IODevicesState();
}

class IODevicesState extends State<IODevices> {
  late String nickname;
  var parts = utf8.decode(ioValues).split('/');

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
    updateWifiValues(toolsValues);
    subscribeToWifiStatus();
    subToIO();
    processValues(ioValues);
    notificationMap.putIfAbsent(
        '${command(deviceName)}/${extractSerialNumber(deviceName)}',
        () => List<bool>.filled(4, false));
  }

  void updateWifiValues(List<int> data) {
    var fun =
        utf8.decode(data); //Wifi status | wifi ssid | ble status | nickname
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

  void processValues(List<int> values) {
    var parts = utf8.decode(values).split('/');
    valores = parts;
    tipo.clear();
    estado.clear();
    common.clear();
    alertIO.clear();

    for (int i = 0; i < parts.length; i++) {
      var equipo = parts[i].split(':');
      tipo.add(equipo[0] == '0' ? 'Salida' : 'Entrada');
      estado.add(equipo[1]);
      common.add(equipo[2]);
      alertIO.add(estado[i] != common[i]);

      printLog(
          'En la posición $i el modo es ${tipo[i]} y su estado es ${estado[i]}');
      globalDATA
          .putIfAbsent(
              '${command(deviceName)}/${extractSerialNumber(deviceName)}',
              () => {})
          .addAll({'io$i': parts[i]});
    }

    saveGlobalData(globalDATA);
    setState(() {});
  }

  void subToIO() async {
    await myDevice.ioUuid.setNotifyValue(true);
    printLog('Subscrito a IO');

    var ioSub = myDevice.ioUuid.onValueReceived.listen((event) {
      printLog('Cambio en IO');
      processValues(event);
    });

    myDevice.device.cancelWhenDisconnected(ioSub);
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
                  if (notificationMap[
                          '${command(deviceName)}/${extractSerialNumber(deviceName)}']!
                      .contains(true)) {
                    for (int index = 0;
                        index <
                            notificationMap[
                                    '${command(deviceName)}/${extractSerialNumber(deviceName)}']!
                                .length;
                        index++) {
                      var noti = notificationMap[
                          '${command(deviceName)}/${extractSerialNumber(deviceName)}']!;
                      if (noti[index]) {
                        String nick =
                            '${nicknamesMap[deviceName] ?? deviceName}/-/${subNicknamesMap['$deviceName/-/$index'] ?? '${tipo[index]} $index'}';
                        // printLog('Nick: $nick');
                        setupIOToken(nick, index, command(deviceName),
                            extractSerialNumber(deviceName), deviceName);
                      }
                    }
                  }
                });
                Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditSubNicknameDialog(
      BuildContext context, int index) async {
    TextEditingController subNicknameController = TextEditingController();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xff1f1d20),
          title: const Text(
            'Editar identificación del sub Módulo',
            style: TextStyle(
              color: Color(0xffa79986),
            ),
          ),
          content: TextField(
            style: const TextStyle(
              color: Color(0xffa79986),
            ),
            cursorColor: const Color(0xffa79986),
            controller: subNicknameController,
            decoration: const InputDecoration(
              hintText: "Introduce el apodo",
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
                  String newNickname = subNicknameController.text;
                  subNicknamesMap.addAll({'$deviceName/-/$index': newNickname});
                  saveSubNicknamesMap(subNicknamesMap);
                  printLog('$subNicknamesMap');
                  String nick =
                      '${nicknamesMap[deviceName] ?? deviceName}/-/${subNicknamesMap['$deviceName/-/$index'] ?? '${tipo[index]} $index'}';
                  setupIOToken(nick, index, command(deviceName),
                      extractSerialNumber(deviceName), deviceName);
                });
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
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
        drawer: deviceOwner ? const DrawerIO() : null,
        body: deviceOwner || secondaryAdmin
            ? ListView.builder(
                itemCount: parts.length,
                itemBuilder: (context, int index) {
                  bool entrada = tipo[index] == 'Entrada';
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffa79986),
                          borderRadius: BorderRadius.circular(20),
                          border: const Border(
                            bottom:
                                BorderSide(color: Color(0xff4b2427), width: 5),
                            right:
                                BorderSide(color: Color(0xff4b2427), width: 5),
                            left:
                                BorderSide(color: Color(0xff4b2427), width: 5),
                            top: BorderSide(color: Color(0xff4b2427), width: 5),
                          ),
                        ),
                        width: width - 50,
                        height: 220,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  width: 20,
                                ),
                                GestureDetector(
                                    onTap: () async {
                                      await _showEditSubNicknameDialog(
                                          context, index);
                                    },
                                    child: Row(
                                      children: [
                                        Text(
                                          subNicknamesMap[
                                                  '$deviceName/-/$index'] ??
                                              '${tipo[index]} $index',
                                          style: const TextStyle(
                                              color: Color(0xff3e3d38),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 30),
                                          textAlign: TextAlign.start,
                                        ),
                                        const SizedBox(
                                          width: 3,
                                        ),
                                        const Icon(
                                          Icons.edit,
                                          size: 20,
                                          color: Color(0xff3e3d38),
                                        )
                                      ],
                                    )),
                                const Spacer(),
                                Text(
                                  'Tipo: ${tipo[index]}',
                                  style: const TextStyle(
                                      color: Color(0xff3e3d38),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(
                                  width: 20,
                                ),
                              ],
                            ),
                            entrada
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        height: 10,
                                      ),
                                      alertIO[index]
                                          ? const Icon(
                                              Icons.new_releases,
                                              color: Color(0xffcb3234),
                                              size: 80,
                                            )
                                          : const Icon(
                                              Icons.new_releases,
                                              color: Color(0xff9b9b9b),
                                              size: 80,
                                            ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                          ),
                                          notificationMap[
                                                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                                                  index]
                                              ? const Text(
                                                  '¿Desactivar notificaciones?',
                                                  style: TextStyle(
                                                      color: Color(0xff3e3d38),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15),
                                                  textAlign: TextAlign.center,
                                                )
                                              : const Text(
                                                  '¿Activar notificaciones?',
                                                  style: TextStyle(
                                                      color: Color(0xff3e3d38),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15),
                                                  textAlign: TextAlign.center,
                                                ),
                                          const Spacer(),
                                          IconButton(
                                            onPressed: () {
                                              if (notificationMap[
                                                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                                                  index]) {
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: true,
                                                  builder: (dialogContext) {
                                                    return AlertDialog(
                                                      backgroundColor:
                                                          const Color(
                                                              0xff1f1d20),
                                                      content: const Text(
                                                        "¿Seguro que quieres desactivar las notificaciones?",
                                                        style: TextStyle(
                                                          color:
                                                              Color(0xffa79986),
                                                          fontSize: 30,
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () async {
                                                            List<String>
                                                                tokens =
                                                                await getIOTokens(
                                                                    service,
                                                                    command(
                                                                        deviceName),
                                                                    extractSerialNumber(
                                                                        deviceName),
                                                                    index);
                                                            tokens.remove(
                                                                tokensOfDevices[
                                                                    '$deviceName$index']);
                                                            putIOTokens(
                                                                service,
                                                                command(
                                                                    deviceName),
                                                                extractSerialNumber(
                                                                    deviceName),
                                                                tokens,
                                                                index);
                                                            showToast(
                                                                'Notificación desactivada');
                                                            setState(() {
                                                              notificationMap[
                                                                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                                                                  index] = false;
                                                            });
                                                            saveNotificationMap(
                                                                notificationMap);
                                                            Navigator.of(
                                                                    navigatorKey
                                                                        .currentContext!)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                            "Desactivar",
                                                            style: TextStyle(
                                                              color: Color(
                                                                  0xffa79986),
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    );
                                                  },
                                                );
                                              } else {
                                                String nick =
                                                    '${nicknamesMap[deviceName] ?? deviceName}/-/${subNicknamesMap['$deviceName/-/$index'] ?? '${tipo[index]} $index'}';
                                                setupIOToken(
                                                    nick,
                                                    index,
                                                    command(deviceName),
                                                    extractSerialNumber(
                                                        deviceName),
                                                    deviceName);
                                                showToast(
                                                    'Notificación activada');
                                                setState(() {
                                                  notificationMap[
                                                          '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                                                      index] = true;
                                                });
                                                saveNotificationMap(
                                                    notificationMap);
                                              }
                                            },
                                            icon: notificationMap[
                                                        '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                                                    index]
                                                ? const Icon(
                                                    Icons.notifications_active,
                                                    color: Color(0xff4b2427),
                                                  )
                                                : const Icon(
                                                    Icons
                                                        .notification_add_rounded,
                                                    color: Color(0xff4b2427),
                                                  ),
                                          ),
                                          const SizedBox(
                                            width: 20,
                                          ),
                                        ],
                                      )
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(
                                        height: 50,
                                      ),
                                      Transform.scale(
                                        scale: 2.5,
                                        child: Switch(
                                          trackOutlineColor:
                                              const WidgetStatePropertyAll(
                                                  Color(0xff4b2427)),
                                          activeColor: const Color(0xff803e2f),
                                          activeTrackColor:
                                              const Color(0xff4b2427),
                                          inactiveThumbColor:
                                              const Color(0xff4b2427),
                                          inactiveTrackColor:
                                              const Color(0xff803e2f),
                                          value: estado[index] == '1',
                                          onChanged: (value) {
                                            controlOut(value, index);
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                            const SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  );
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Actualmente no eres el administador del equipo.\nNo puedes modificar los parámetros',
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
    );
  }
}

//!-------------------------------------IOS Widget-------------------------------------!\\

class IOSIODevices extends StatefulWidget {
  const IOSIODevices({super.key});
  @override
  IOSIODevicesState createState() => IOSIODevicesState();
}

class IOSIODevicesState extends State<IOSIODevices>
    //!DE ACA
    with
        SingleTickerProviderStateMixin {
  TextEditingController passController = TextEditingController();
  late String nickname;
  //!HASTA ACA
  var parts = utf8.decode(ioValues).split('/');

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
    updateWifiValues(toolsValues);
    subscribeToWifiStatus();
    subToIO();
    processValues(ioValues);
    notificationMap.putIfAbsent(
        '${command(deviceName)}/${extractSerialNumber(deviceName)}',
        () => List<bool>.filled(4, false));
  }

  void updateWifiValues(List<int> data) {
    var fun =
        utf8.decode(data); //Wifi status | wifi ssid | ble status | nickname
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

  void processValues(List<int> values) {
    var parts = utf8.decode(values).split('/');
    valores = parts;
    tipo.clear();
    estado.clear();
    common.clear();
    alertIO.clear();

    for (int i = 0; i < parts.length; i++) {
      var equipo = parts[i].split(':');
      tipo.add(equipo[0] == '0' ? 'Salida' : 'Entrada');
      estado.add(equipo[1]);
      common.add(equipo[2]);
      alertIO.add(estado[i] != common[i]);

      printLog(
          'En la posición $i el modo es ${tipo[i]} y su estado es ${estado[i]}');
      globalDATA
          .putIfAbsent(
              '${command(deviceName)}/${extractSerialNumber(deviceName)}',
              () => {})
          .addAll({'io$i': parts[i]});
    }

    saveGlobalData(globalDATA);
    setState(() {});
  }

  void subToIO() async {
    await myDevice.ioUuid.setNotifyValue(true);
    printLog('Subscrito a IO');

    var ioSub = myDevice.ioUuid.onValueReceived.listen((event) {
      printLog('Cambio en IO');
      processValues(event);
    });

    myDevice.device.cancelWhenDisconnected(ioSub);
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
                  if (notificationMap[
                          '${command(deviceName)}/${extractSerialNumber(deviceName)}']!
                      .contains(true)) {
                    for (int index = 0;
                        index <
                            notificationMap[
                                    '${command(deviceName)}/${extractSerialNumber(deviceName)}']!
                                .length;
                        index++) {
                      var noti = notificationMap[
                          '${command(deviceName)}/${extractSerialNumber(deviceName)}']!;
                      if (noti[index]) {
                        String nick =
                            '${nicknamesMap[deviceName] ?? deviceName}/-/${subNicknamesMap['$deviceName/-/$index'] ?? '${tipo[index]} $index'}';
                        // printLog('Nick: $nick');
                        setupIOToken(nick, index, command(deviceName),
                            extractSerialNumber(deviceName), deviceName);
                      }
                    }
                  }
                });
                Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCupertinoEditSubNicknameDialog(
      BuildContext context, int index) async {
    TextEditingController subNicknameController = TextEditingController();

    return showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text(
            'Editar identificación del sub Módulo',
            style: TextStyle(
              color: CupertinoColors.label,
            ),
          ),
          content: CupertinoTextField(
            style: const TextStyle(
              color: CupertinoColors.label,
            ),
            cursorColor: const Color(0xffa79986),
            controller: subNicknameController,
            placeholder: "Introduce el apodo",
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
            CupertinoButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: CupertinoColors.label,
                ),
              ),
            ),
            CupertinoButton(
              onPressed: () {
                setState(() {
                  String newNickname = subNicknameController.text;
                  subNicknamesMap.addAll({'$deviceName/-/$index': newNickname});
                  saveSubNicknamesMap(subNicknamesMap);
                  printLog('$subNicknamesMap');
                  String nick =
                      '${nicknamesMap[deviceName] ?? deviceName}/-/${subNicknamesMap['$deviceName/-/$index'] ?? '${tipo[index]} $index'}';
                  // printLog('Nick: $nick');
                  setupIOToken(nick, index, command(deviceName),
                      extractSerialNumber(deviceName), deviceName);
                });
                Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
              },
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: CupertinoColors.label, // Cambia el color del texto
                ),
              ),
            )
          ],
        );
      },
    );
  }

//!Visual

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return DefaultTextStyle(
        style: const TextStyle(
          fontSize: 16.0,
        ),
        child: PopScope(
          canPop: false,
          onPopInvoked: (didPop) {
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
                              style: TextStyle(color: CupertinoColors.label))),
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
                title: GestureDetector(
                  onTap: () async {
                    await _showCupertinoEditNicknameDialog(context);
                  },
                  child: Row(
                    children: [
                      Text(nickname),
                      const SizedBox(
                        width: 3,
                      ),
                      const Icon(
                        CupertinoIcons.pencil,
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
                      cupertinoWifiText(context);
                    },
                  ),
                ]),
            drawer: deviceOwner ? const IOSDrawerIO() : null,
            body: deviceOwner || secondaryAdmin
                ? ListView.builder(
                    itemCount: parts.length,
                    itemBuilder: (context, int index) {
                      bool entrada = tipo[index] == 'Entrada';
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 10,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xffa79986),
                              borderRadius: BorderRadius.circular(20),
                              border: const Border(
                                bottom: BorderSide(
                                    color: Color(0xff4b2427), width: 5),
                                right: BorderSide(
                                    color: Color(0xff4b2427), width: 5),
                                left: BorderSide(
                                    color: Color(0xff4b2427), width: 5),
                                top: BorderSide(
                                    color: Color(0xff4b2427), width: 5),
                              ),
                            ),
                            width: width - 50,
                            height: 220,
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                    ),
                                    GestureDetector(
                                        onTap: () async {
                                          await _showCupertinoEditSubNicknameDialog(
                                              context, index);
                                        },
                                        child: Row(
                                          children: [
                                            Text(
                                              subNicknamesMap[
                                                      '$deviceName/-/$index'] ??
                                                  '${tipo[index]} $index',
                                              style: const TextStyle(
                                                  color: Color(0xff3e3d38),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 30),
                                              textAlign: TextAlign.start,
                                            ),
                                            const SizedBox(
                                              width: 3,
                                            ),
                                            const Icon(
                                              CupertinoIcons.pencil,
                                              color: Color(0xff3e3d38),
                                            )
                                          ],
                                        )),
                                    const Spacer(),
                                    Text(
                                      'Tipo: ${tipo[index]}',
                                      style: const TextStyle(
                                          color: Color(0xff3e3d38),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(
                                      width: 20,
                                    ),
                                  ],
                                ),
                                entrada
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          alertIO[index]
                                              ? const Icon(
                                                  CupertinoIcons
                                                      .exclamationmark_circle_fill,
                                                  color: Color(0xffcb3234),
                                                  size: 80,
                                                )
                                              : const Icon(
                                                  CupertinoIcons
                                                      .exclamationmark_circle_fill,
                                                  color: Color(0xFF8F8E8E),
                                                  size: 80,
                                                ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              const SizedBox(
                                                width: 20,
                                              ),
                                              notificationMap[
                                                          '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                                                      index]
                                                  ? const Text(
                                                      '¿Desactivar notificaciones?',
                                                      style: TextStyle(
                                                          color:
                                                              Color(0xff3e3d38),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                      textAlign:
                                                          TextAlign.center,
                                                    )
                                                  : const Text(
                                                      '¿Activar notificaciones?',
                                                      style: TextStyle(
                                                          color:
                                                              Color(0xff3e3d38),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 15),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                              const Spacer(),
                                              IconButton(
                                                  onPressed: () {
                                                    if (notificationMap[
                                                            '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                                                        index]) {
                                                      showCupertinoDialog(
                                                        context: context,
                                                        barrierDismissible:
                                                            true,
                                                        builder:
                                                            (dialogContext) {
                                                          return CupertinoAlertDialog(
                                                            content: const Text(
                                                              "¿Seguro que quieres desactivar las notificaciones?",
                                                              style: TextStyle(
                                                                color:
                                                                    CupertinoColors
                                                                        .label,
                                                                fontSize: 30,
                                                              ),
                                                            ),
                                                            actions: [
                                                              CupertinoButton(
                                                                onPressed:
                                                                    () async {
                                                                  List<String>
                                                                      tokens =
                                                                      await getIOTokens(
                                                                          service,
                                                                          command(
                                                                              deviceName),
                                                                          extractSerialNumber(
                                                                              deviceName),
                                                                          index);
                                                                  tokens.remove(
                                                                      tokensOfDevices[
                                                                          '$deviceName$index']);
                                                                  putIOTokens(
                                                                      service,
                                                                      command(
                                                                          deviceName),
                                                                      extractSerialNumber(
                                                                          deviceName),
                                                                      tokens,
                                                                      index);
                                                                  showToast(
                                                                      'Notificación desactivada');
                                                                  setState(() {
                                                                    notificationMap[
                                                                            '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                                                                        index] = false;
                                                                  });
                                                                  saveNotificationMap(
                                                                      notificationMap);
                                                                  Navigator.of(
                                                                          navigatorKey
                                                                              .currentContext!)
                                                                      .pop();
                                                                },
                                                                child:
                                                                    const Text(
                                                                  "Desactivar",
                                                                  style:
                                                                      TextStyle(
                                                                    color: CupertinoColors
                                                                        .label,
                                                                  ),
                                                                ),
                                                              )
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    } else {
                                                      String nick =
                                                          '${nicknamesMap[deviceName] ?? deviceName}/-/${subNicknamesMap['$deviceName/-/$index'] ?? '${tipo[index]} $index'}';
                                                      setupIOToken(
                                                          nick,
                                                          index,
                                                          command(deviceName),
                                                          extractSerialNumber(
                                                              deviceName),
                                                          deviceName);
                                                      showToast(
                                                          'Notificación activada');
                                                      setState(() {
                                                        notificationMap[
                                                                '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                                                            index] = true;
                                                      });
                                                      saveNotificationMap(
                                                          notificationMap);
                                                    }
                                                  },
                                                  icon: notificationMap[
                                                              '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                                                          index]
                                                      ? const Icon(
                                                          CupertinoIcons
                                                              .bell_slash_fill,
                                                          color:
                                                              Color(0xff4b2427),
                                                        )
                                                      : const Icon(
                                                          CupertinoIcons
                                                              .bell_fill,
                                                          color:
                                                              Color(0xff4b2427),
                                                        )),
                                              const SizedBox(
                                                width: 20,
                                              ),
                                            ],
                                          )
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            height: 50,
                                          ),
                                          Transform.scale(
                                            scale: 2.5,
                                            child: CupertinoSwitch(
                                              trackColor: const Color(
                                                  0xff803e2f), // Color del track cuando está inactivo
                                              activeColor:
                                                  const Color(0xff4b2427),
                                              value: estado[index] == '1',
                                              onChanged: (value) {
                                                controlOut(value, index);
                                              },
                                            ),
                                          )
                                        ],
                                      ),
                                const SizedBox(
                                  height: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      );
                    },
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Actualmente no eres el administador del equipo.\nNo puedes modificar los parámetros',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 25, color: Color(0xffa79986)),
                      ),
                      const SizedBox(height: 10),
                      CupertinoButton(
                        color: const Color(0xff4b2427),
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
        ));
  }
}
