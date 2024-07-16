import 'dart:convert';
import 'package:flutter/cupertino.dart';

import '/stored_data.dart';
import 'package:flutter/material.dart';
import 'master_detector.dart';
import '/master.dart';

class DetectorPage extends StatefulWidget {
  const DetectorPage({super.key});
  @override
  DetectorPageState createState() => DetectorPageState();
}

class DetectorPageState extends State<DetectorPage> {
  late String nickname;
  bool werror = false;
  bool alert = false;
  String _textToShow = 'AIRE PURO';
  bool online =
      globalDATA['${command(deviceName)}/${extractSerialNumber(deviceName)}']![
              'cstate'] ??
          false;

  @override
  void initState() {
    super.initState();

    nickname = nicknamesMap[deviceName] ?? deviceName;
    _subscribeToWorkCharacteristic();
    subscribeToWifiStatus();
    updateWifiValues(toolsValues);
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
    printLog('Me suscribí a work');
    final workSub =
        myDevice.workUuid.onValueReceived.listen((List<int> status) {
      printLog('Cositas: $status');
      setState(() {
        alert = status[4] == 1;
        ppmCO = status[5] + (status[6] << 8);
        ppmCH4 = status[7] + (status[8] << 8);
        picoMaxppmCO = status[9] + (status[10] << 8);
        picoMaxppmCH4 = status[11] + (status[12] << 8);
        promedioppmCO = status[17] + (status[18] << 8);
        promedioppmCH4 = status[19] + (status[20] << 8);
        daysToExpire = status[21] + (status[22] << 8);
        printLog('Parte baja CO: ${status[9]} // Parte alta CO: ${status[10]}');
        printLog('PPMCO: $ppmCO');
        printLog(
            'Parte baja CH4: ${status[11]} // Parte alta CH4: ${status[12]}');
        printLog('PPMCH4: $ppmCH4');
        printLog('Alerta: $alert');
        _textToShow = alert ? 'PELIGRO' : 'AIRE PURO';
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
          backgroundColor: const Color(0xFFE6FEFF),
          title: const Text(
            'Editar identificación del dispositivo',
            style: TextStyle(color: Color(0xFF000000)),
          ),
          content: TextField(
            style: const TextStyle(color: Color(0xFF000000)),
            cursorColor: const Color(0xFFFFFFFF),
            controller: nicknameController,
            decoration: const InputDecoration(
              hintText: "Introduce tu nueva identificación del dispositivo",
              hintStyle: TextStyle(color: Color(0xFF000000)),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF000000)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF000000)),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: const ButtonStyle(
                foregroundColor: MaterialStatePropertyAll(
                  Color(0xFF1DA3A9),
                ),
              ),
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el AlertDialog
              },
            ),
            TextButton(
              style: const ButtonStyle(
                foregroundColor: MaterialStatePropertyAll(
                  Color(0xFF1DA3A9),
                ),
              ),
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
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return android
        ? PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFFE6FEFF),
                    content: Row(
                      children: [
                        const CircularProgressIndicator(
                            color: Color(0xFF1DA3A9)),
                        Container(
                            margin: const EdgeInsets.only(left: 15),
                            child: const Text(
                              "Desconectando...",
                              style: TextStyle(
                                  color: Color(0xFF000000)),
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
              backgroundColor: const Color(0xFF01121C),
              appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFF1DA3A9),
                  title: GestureDetector(
                    onTap: () async {
                      await _showEditNicknameDialog(context);
                      setupToken(command(deviceName),
                          extractSerialNumber(deviceName), deviceName);
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
              drawer: const DrawerDetector(),
              body: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                          height: 100,
                          width: width - 50,
                          decoration: BoxDecoration(
                            color: alert
                                ? Colors.red
                                : const Color(0xFF004B51),
                            borderRadius: BorderRadius.circular(20),
                            border: const Border(
                              bottom: BorderSide(
                                  color: Color(0xFF18B2C7),
                                  width: 5),
                              right: BorderSide(
                                  color: Color(0xFF18B2C7),
                                  width: 5),
                              left: BorderSide(
                                  color: Color(0xFF18B2C7),
                                  width: 5),
                              top: BorderSide(
                                  color: Color(0xFF18B2C7),
                                  width: 5),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _textToShow,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: alert ? Colors.white : Colors.green,
                                  fontSize: height * 0.05),
                            ),
                          )),
                      const SizedBox(
                        height: 20,
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              height: 220,
                              width: (width / 2) - 15,
                              decoration: BoxDecoration(
                                color: const Color(0xFF004B51),
                                borderRadius: BorderRadius.circular(20),
                                border: const Border(
                                  bottom: BorderSide(
                                      color: Color(0xFF18B2C7),
                                      width: 5),
                                  right: BorderSide(
                                      color: Color(0xFF18B2C7),
                                      width: 5),
                                  left: BorderSide(
                                      color: Color(0xFF18B2C7),
                                      width: 5),
                                  top: BorderSide(
                                      color: Color(0xFF18B2C7),
                                      width: 5),
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 0,
                                    ),
                                    const Text(
                                      'GAS',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Color(0xFFFFFFFF),
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      'Atmósfera\n Explosiva',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            Color(0xFFFFFFFF),
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '${(ppmCH4 / 500).round()}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color:
                                            Color(0xFFFFFFFF),
                                        fontSize: 45,
                                      ),
                                    ),
                                    const Text(
                                      'LIE',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            Color(0xFFFFFFFF),
                                        fontSize: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Container(
                              height: 220,
                              width: (width / 2) - 15,
                              decoration: BoxDecoration(
                                color: const Color(0xFF004B51),
                                borderRadius: BorderRadius.circular(20),
                                border: const Border(
                                  bottom: BorderSide(
                                      color: Color(0xFF18B2C7),
                                      width: 5),
                                  right: BorderSide(
                                      color: Color(0xFF18B2C7),
                                      width: 5),
                                  left: BorderSide(
                                      color: Color(0xFF18B2C7),
                                      width: 5),
                                  top: BorderSide(
                                      color: Color(0xFF18B2C7),
                                      width: 5),
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 0,
                                    ),
                                    const Text(
                                      'CO',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: Color(0xFFFFFFFF),
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      'Monóxido de\ncarbono',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            Color(0xFFFFFFFF),
                                        fontSize: 15,
                                      ),
                                    ),
                                    Text(
                                      '$ppmCO',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color:
                                            Color(0xFFFFFFFF),
                                        fontSize: 45,
                                      ),
                                    ),
                                    const Text(
                                      'PPM',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            Color(0xFFFFFFFF),
                                        fontSize: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF004B51),
                              borderRadius: BorderRadius.circular(50),
                              border: const Border(
                                bottom: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                right: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                left: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                top: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Text(
                                    'Pico máximo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color:
                                            Color(0xFFFFFFFF),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'PPM CH4',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '$picoMaxppmCH4',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 30,
                                    ),
                                  ),
                                  const Text(
                                    'PPM',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF004B51),
                              borderRadius: BorderRadius.circular(50),
                              border: const Border(
                                bottom: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                right: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                left: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                top: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Text(
                                    'Pico máximo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color:
                                            Color(0xFFFFFFFF),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'PPM CO',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '$picoMaxppmCO',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 30,
                                    ),
                                  ),
                                  const Text(
                                    'PPM',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF004B51),
                              borderRadius: BorderRadius.circular(50),
                              border: const Border(
                                bottom: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                right: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                left: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                top: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Text(
                                    'Promedio',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color:
                                            Color(0xFFFFFFFF),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'PPM CH4',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '$promedioppmCH4',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 30,
                                    ),
                                  ),
                                  const Text(
                                    'PPM',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFF004B51),
                              borderRadius: BorderRadius.circular(50),
                              border: const Border(
                                bottom: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                right: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                left: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                                top: BorderSide(
                                    color: Color(0xFF18B2C7),
                                    width: 5),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  const Text(
                                    'Promedio',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color:
                                            Color(0xFFFFFFFF),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Text(
                                    'PPM CO',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '$promedioppmCO',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 30,
                                    ),
                                  ),
                                  const Text(
                                    'PPM',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Container(
                          height: 150,
                          width: width - 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF004B51),
                            borderRadius: BorderRadius.circular(20),
                            border: const Border(
                              bottom: BorderSide(
                                  color: Color(0xFF18B2C7),
                                  width: 5),
                              right: BorderSide(
                                  color: Color(0xFF18B2C7),
                                  width: 5),
                              left: BorderSide(
                                  color: Color(0xFF18B2C7),
                                  width: 5),
                              top: BorderSide(
                                  color: Color(0xFF18B2C7),
                                  width: 5),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Estado: ',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            Color(0xFFFFFFFF),
                                        fontSize: 25,
                                      ),
                                    ),
                                    Text(online ? 'EN LINEA' : 'DESCONECTADO',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: online
                                                ? Colors.green
                                                : Colors.red,
                                            fontSize: 25,
                                            fontWeight: FontWeight.bold))
                                  ],
                                ),
                              ),
                              Text(
                                'El certificado del sensor\n caduca en: $daysToExpire dias',
                                style: const TextStyle(
                                    fontSize: 15.0, color: Colors.white),
                              ),
                            ],
                          )),
                    ],
                  ),
                ),
              ),
            ),
          )
        :
        //!-------------------------------------IOS Widget-------------------------------------!\\
        PopScope(
            canPop: false,
            onPopInvoked: (didPop) {
              showCupertinoDialog(
                context: context,
                builder: (context) {
                  return CupertinoAlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const CupertinoActivityIndicator(),
                            Container(
                              margin: const EdgeInsets.only(left: 15),
                              child: const Text(
                                "Desconectando...",
                                style: TextStyle(color: CupertinoColors.black),
                              ),
                            ),
                          ],
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
            child: CupertinoPageScaffold(
              backgroundColor: const Color(0xFF01121C),
              navigationBar: CupertinoNavigationBar(
                backgroundColor: CupertinoColors.systemGrey.withOpacity(0.0),
                middle: GestureDetector(
                  onTap: () async {
                    await _showEditNicknameDialog(context);
                    setupToken(command(deviceName),
                        extractSerialNumber(deviceName), deviceName);
                  },
                  child: Row(
                    children: [
                      Text(
                        nickname,
                        style: const TextStyle(
                            color: Color(0xFF1DA3A9)),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        CupertinoIcons.pencil,
                        size: 20,
                        color: CupertinoColors.systemBlue,
                      ),
                    ],
                  ),
                ),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    wifiText(context);
                  },
                  child: const Icon(
                    CupertinoIcons.wifi,
                    size: 24.0,
                    color: CupertinoColors.systemBlue,
                    semanticLabel: 'Icono de wifi',
                  ),
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        height: 100,
                        width: width - 50,
                        decoration: BoxDecoration(
                          color: alert
                              ? CupertinoColors.systemRed
                              : const Color(0xFF004B51),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF18B2C7),
                            width: 5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _textToShow,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: alert
                                  ? CupertinoColors.white
                                  : CupertinoColors.activeGreen,
                              fontSize: height * 0.05,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  height: 220,
                                  width: (width / 2) - 15,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF004B51),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF18B2C7),
                                      width: 5,
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 0,
                                        ),
                                        const Text(
                                          'GAS',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Color(0xFFFFFFFF),
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const Text(
                                          'Atmósfera\n Explosiva',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '${(ppmCH4 / 500).round()}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontSize: 45,
                                          ),
                                        ),
                                        const Text(
                                          'LIE',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontSize: 30,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Container(
                                  height: 220,
                                  width: (width / 2) - 15,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF004B51),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF18B2C7),
                                      width: 5,
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          height: 0,
                                        ),
                                        const Text(
                                          'CO',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              color: Color(0xFFFFFFFF),
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const Text(
                                          'Monóxido de\ncarbono',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '$ppmCO',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontSize: 45,
                                          ),
                                        ),
                                        const Text(
                                          'PPM',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFFFFFFFF),
                                            fontSize: 30,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 15,
                                ),
                                Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 150,
                                        width: 150,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF004B51),
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          border: Border.all(
                                            color: const Color(0xFF18B2C7),
                                            width: 5,
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              const Text(
                                                'Pico máximo',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Color(0xFFFFFFFF),
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const Text(
                                                'PPM CH4',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                '$picoMaxppmCH4',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 30,
                                                ),
                                              ),
                                              const Text(
                                                'PPM',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Container(
                                          height: 150,
                                          width: 150,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF004B51),
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            border: Border.all(
                                              color: const Color(0xFF18B2C7),
                                              width: 5,
                                            ),
                                          ),
                                          child: SingleChildScrollView(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const SizedBox(
                                                  height: 10,
                                                ),
                                                const Text(
                                                  'Pico máximo',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      color: Color(0xFFFFFFFF),
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const Text(
                                                  'PPM CO',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Color(0xFFFFFFFF),
                                                    fontSize: 15,
                                                  ),
                                                ),
                                                Text(
                                                  '$picoMaxppmCO',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Color(0xFFFFFFFF),
                                                    fontSize: 30,
                                                  ),
                                                ),
                                                const Text('PPM',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Color(0xFFFFFFFF),
                                                      fontSize: 15,
                                                    ))
                                              ],
                                            ),
                                          ))
                                    ]),
                                const SizedBox(
                                  height: 15,
                                ),
                                Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 150,
                                        width: 150,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF004B51),
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          border: Border.all(
                                            color: const Color(0xFF18B2C7),
                                            width: 5,
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              const Text(
                                                'Promedio',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Color(0xFFFFFFFF),
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const Text(
                                                'PPM CH4',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                '$promedioppmCH4',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 30,
                                                ),
                                              ),
                                              const Text(
                                                'PPM',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 5,
                                      ),
                                      Container(
                                        height: 150,
                                        width: 150,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF004B51),
                                          borderRadius:
                                              BorderRadius.circular(50),
                                          border: Border.all(
                                            color: const Color(0xFF18B2C7),
                                            width: 5,
                                          ),
                                        ),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              const Text(
                                                'Promedio',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: Color(0xFFFFFFFF),
                                                    fontSize: 15,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const Text(
                                                'PPM CO',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 15,
                                                ),
                                              ),
                                              Text(
                                                '$promedioppmCO',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 30,
                                                ),
                                              ),
                                              const Text(
                                                'PPM',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Color(0xFFFFFFFF),
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 15,
                                      ),
                                      Container(
                                          height: 150,
                                          width: width - 50,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF004B51),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFF18B2C7),
                                              width: 5,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SingleChildScrollView(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Estado: ',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        color: Color(0xFFFFFFFF),
                                                        fontSize: 25,
                                                      ),
                                                    ),
                                                    Text(
                                                        online
                                                            ? 'EN LINEA'
                                                            : 'DESCONECTADO',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                            color: online
                                                                ? CupertinoColors
                                                                    .activeGreen
                                                                : Colors.red,
                                                            fontSize: 25,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                'El certificado del sensor\n caduca en: $daysToExpire dias',
                                                style: const TextStyle(
                                                    fontSize: 15.0,
                                                    color: Colors.white),
                                              ),
                                            ],
                                          )),
                                    ])
                              ]))
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
