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
                foregroundColor: WidgetStatePropertyAll(
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
                foregroundColor: WidgetStatePropertyAll(
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
    return PopScope(
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
                  const CircularProgressIndicator(color: Color(0xFF1DA3A9)),
                  Container(
                      margin: const EdgeInsets.only(left: 15),
                      child: const Text(
                        "Desconectando...",
                        style: TextStyle(color: Color(0xFF000000)),
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
                setupToken(command(deviceName), extractSerialNumber(deviceName),
                    deviceName);
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
                      color: alert ? Colors.red : const Color(0xFF004B51),
                      borderRadius: BorderRadius.circular(20),
                      border: const Border(
                        bottom: BorderSide(color: Color(0xFF18B2C7), width: 5),
                        right: BorderSide(color: Color(0xFF18B2C7), width: 5),
                        left: BorderSide(color: Color(0xFF18B2C7), width: 5),
                        top: BorderSide(color: Color(0xFF18B2C7), width: 5),
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
                            bottom:
                                BorderSide(color: Color(0xFF18B2C7), width: 5),
                            right:
                                BorderSide(color: Color(0xFF18B2C7), width: 5),
                            left:
                                BorderSide(color: Color(0xFF18B2C7), width: 5),
                            top: BorderSide(color: Color(0xFF18B2C7), width: 5),
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
                          border: const Border(
                            bottom:
                                BorderSide(color: Color(0xFF18B2C7), width: 5),
                            right:
                                BorderSide(color: Color(0xFF18B2C7), width: 5),
                            left:
                                BorderSide(color: Color(0xFF18B2C7), width: 5),
                            top: BorderSide(color: Color(0xFF18B2C7), width: 5),
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
                          bottom:
                              BorderSide(color: Color(0xFF18B2C7), width: 5),
                          right: BorderSide(color: Color(0xFF18B2C7), width: 5),
                          left: BorderSide(color: Color(0xFF18B2C7), width: 5),
                          top: BorderSide(color: Color(0xFF18B2C7), width: 5),
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
                                  color: Color(0xFFFFFFFF),
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
                          bottom:
                              BorderSide(color: Color(0xFF18B2C7), width: 5),
                          right: BorderSide(color: Color(0xFF18B2C7), width: 5),
                          left: BorderSide(color: Color(0xFF18B2C7), width: 5),
                          top: BorderSide(color: Color(0xFF18B2C7), width: 5),
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
                                  color: Color(0xFFFFFFFF),
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
                          bottom:
                              BorderSide(color: Color(0xFF18B2C7), width: 5),
                          right: BorderSide(color: Color(0xFF18B2C7), width: 5),
                          left: BorderSide(color: Color(0xFF18B2C7), width: 5),
                          top: BorderSide(color: Color(0xFF18B2C7), width: 5),
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
                                  color: Color(0xFFFFFFFF),
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
                          bottom:
                              BorderSide(color: Color(0xFF18B2C7), width: 5),
                          right: BorderSide(color: Color(0xFF18B2C7), width: 5),
                          left: BorderSide(color: Color(0xFF18B2C7), width: 5),
                          top: BorderSide(color: Color(0xFF18B2C7), width: 5),
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
                                  color: Color(0xFFFFFFFF),
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
                        bottom: BorderSide(color: Color(0xFF18B2C7), width: 5),
                        right: BorderSide(color: Color(0xFF18B2C7), width: 5),
                        left: BorderSide(color: Color(0xFF18B2C7), width: 5),
                        top: BorderSide(color: Color(0xFF18B2C7), width: 5),
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
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 25,
                                ),
                              ),
                              Text(online ? 'EN LINEA' : 'DESCONECTADO',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: online ? Colors.green : Colors.red,
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
    );
  }
}

//!-------------------------------------IOS Widget-------------------------------------!\\

class IOSDetector extends StatefulWidget {
  const IOSDetector({super.key});

  @override
  State<IOSDetector> createState() => IOSDetectorState();
}

class IOSDetectorState extends State<IOSDetector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _drawerAnimation;
  final double _drawerWidth = 250.0;
  bool _isDragging = false;
  double _sliderValue = 50.0;
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
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _drawerAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
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
            style: TextStyle(color: Color(0xFF000000)),
          ),
          content: CupertinoTextField(
            style: const TextStyle(color: Color(0xFF000000)),
            cursorColor: const Color(
                0xFF000000), // Aquí se cambia el color del cursor a negro
            controller: nicknameController,
            placeholder: "Introduce tu nueva identificación del dispositivo",
            placeholderStyle: const TextStyle(color: Color(0xFF000000)),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF000000)),
              ),
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(); // Cierra el CupertinoAlertDialog
              },
              textStyle: const TextStyle(color: Color(0xFF1DA3A9)),
              child: const Text('Cancelar'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                setState(() {
                  String newNickname = nicknameController.text;
                  nickname = newNickname;
                  nicknamesMap[deviceName] = newNickname; // Actualizar el mapa
                  saveNicknamesMap(nicknamesMap);
                  printLog('$nicknamesMap');
                });
                Navigator.of(dialogContext)
                    .pop(); // Cierra el CupertinoAlertDialog
              },
              textStyle: const TextStyle(color: Color(0xFF1DA3A9)),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _toggleDrawer() {
    if (_controller.isDismissed) {
      _controller.forward();
    } else if (_controller.isCompleted) {
      _controller.reverse();
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isDragging) {
      final double delta = details.primaryDelta! / _drawerWidth;
      _controller.value += delta;
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _isDragging = false;
    if (_controller.value > 0.5) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _sendValueToBle(int value) async {
    try {
      final data = [value];
      myDevice.lightUuid.write(data, withoutResponse: true);
    } catch (e, stackTrace) {
      printLog('Error al mandar el valor del brillo $e $stackTrace');
      // handleManualError(e, stackTrace);
    }
  }

  void _updateSliderValue(double localPosition) {
    setState(() {
      _sliderValue = (300 - localPosition) / 3;
      if (_sliderValue < 0) {
        _sliderValue = 0;
      } else if (_sliderValue > 100) {
        _sliderValue = 100;
      }
    });

    _sendValueToBle(_sliderValue.toInt());
  }

  Widget _buildCustomSlider() {
    return Container(
      width: 60,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: CupertinoColors.systemFill,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragUpdate: (DragUpdateDetails details) {
          _updateSliderValue(details.localPosition.dy);
        },
        onTapDown: (TapDownDetails details) {
          _updateSliderValue(details.localPosition.dy);
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              children: [
                Expanded(
                  flex: 100 - _sliderValue.toInt(),
                  child: Container(),
                ),
                Expanded(
                  flex: _sliderValue.toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DA3A9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Icon(
                _sliderValue > 50
                    ? CupertinoIcons.sun_max_fill
                    : CupertinoIcons.moon_fill,
                color: CupertinoColors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return CupertinoAlertDialog(
              content: Row(
                children: [
                  const CupertinoActivityIndicator(color: Color(0xFF1DA3A9)),
                  Container(
                      margin: const EdgeInsets.only(left: 15),
                      child: const Text(
                        "Desconectando...",
                        style: TextStyle(color: Color(0xFF000000)),
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
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF01121C),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: CupertinoColors.systemGrey.withOpacity(0.0),
          middle: GestureDetector(
            onTap: () async {
              await _showCupertinoEditNicknameDialog(context);
              setupToken(command(deviceName), extractSerialNumber(deviceName),
                  deviceName);
            },
            child: Row(
              children: [
                Text(
                  nickname,
                  style:
                      const TextStyle(fontSize: 20, color: Color(0xFF1DA3A9)),
                ),
                const SizedBox(width: 3),
                const Icon(
                  CupertinoIcons.pencil,
                  size: 20,
                  color: CupertinoColors.white,
                ),
              ],
            ),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              cupertinoWifiText(context);
            },
            child: const Icon(
              CupertinoIcons.wifi,
              size: 24.0,
              color: CupertinoColors.white,
              semanticLabel: 'Icono de wifi',
            ),
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              _toggleDrawer();
            },
            child: const Icon(
              CupertinoIcons.bars,
              size: 24.0,
              color: CupertinoColors.white,
              semanticLabel: 'Icono de barras',
            ),
          ),
        ),
        child: GestureDetector(
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: Stack(
            children: <Widget>[
              Center(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 100,
                      ),
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
                          child: DefaultTextStyle(
                            style: TextStyle(
                              textBaseline: TextBaseline.alphabetic,
                              color: alert ? Colors.white : Colors.green,
                              fontSize: height * 0.05,
                            ),
                            child: Text(
                              _textToShow,
                              selectionColor: Colors.transparent,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
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
                                      color: Color(0xFF18B2C7), width: 5),
                                  right: BorderSide(
                                      color: Color(0xFF18B2C7), width: 5),
                                  left: BorderSide(
                                      color: Color(0xFF18B2C7), width: 5),
                                  top: BorderSide(
                                      color: Color(0xFF18B2C7), width: 5),
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    const DefaultTextStyle(
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      child: Text(
                                        'GAS',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const DefaultTextStyle(
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      child: Text(
                                        'Atmósfera\n Explosiva',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    DefaultTextStyle(
                                      style: const TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 45,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      child: Text(
                                        '${(ppmCH4 / 500).round()}',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const DefaultTextStyle(
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      child: Text(
                                        'LIE',
                                        textAlign: TextAlign.center,
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
                                      color: Color(0xFF18B2C7), width: 5),
                                  right: BorderSide(
                                      color: Color(0xFF18B2C7), width: 5),
                                  left: BorderSide(
                                      color: Color(0xFF18B2C7), width: 5),
                                  top: BorderSide(
                                      color: Color(0xFF18B2C7), width: 5),
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    const DefaultTextStyle(
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      child: Text(
                                        'CO',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const DefaultTextStyle(
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      child: Text(
                                        'Monóxido de\ncarbono',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    DefaultTextStyle(
                                      style: const TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 45,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      child: Text(
                                        '$ppmCO',
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const DefaultTextStyle(
                                      style: TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      child: Text(
                                        'PPM',
                                        textAlign: TextAlign.center,
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
                                    color: Color(0xFF18B2C7), width: 5),
                                right: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                                left: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                                top: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'Pico máximo',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'PPM CH4',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DefaultTextStyle(
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      '$picoMaxppmCH4',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'PPM',
                                      textAlign: TextAlign.center,
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
                                    color: Color(0xFF18B2C7), width: 5),
                                right: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                                left: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                                top: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'Pico máximo',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'PPM CO',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DefaultTextStyle(
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      '$picoMaxppmCO',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'PPM',
                                      textAlign: TextAlign.center,
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
                                    color: Color(0xFF18B2C7), width: 5),
                                right: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                                left: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                                top: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'Promedio',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'PPM CH4',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DefaultTextStyle(
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      '$promedioppmCH4',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'PPM',
                                      textAlign: TextAlign.center,
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
                                    color: Color(0xFF18B2C7), width: 5),
                                right: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                                left: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                                top: BorderSide(
                                    color: Color(0xFF18B2C7), width: 5),
                              ),
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    height: 20,
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'Promedio',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'PPM CO',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DefaultTextStyle(
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      '$promedioppmCO',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      'PPM',
                                      textAlign: TextAlign.center,
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
                          border: Border.all(
                            color: const Color(0xFF18B2C7),
                            width: 5,
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
                                  const DefaultTextStyle(
                                    style: TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 25,
                                    ),
                                    child: Text(
                                      'Estado: ',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  DefaultTextStyle(
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    child: Text(
                                      online ? 'EN LINEA' : 'DESCONECTADO',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: online
                                            ? CupertinoColors.activeGreen
                                            : Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DefaultTextStyle(
                              style: const TextStyle(
                                fontSize: 15.0,
                                color: Colors.white,
                              ),
                              child: Text(
                                'El certificado del sensor\n caduca en: $daysToExpire días',
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SlideTransition(
                position: _drawerAnimation,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height,
                  color: const Color(0xFF01121C),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),
                        SizedBox(
                          height: 50,
                          child: Image.asset(
                              'assets/IntelligentGas/IntelligentGasFlyerCL.png'),
                        ),
                        Icon(
                          CupertinoIcons.lightbulb_fill,
                          size: 150,
                          color: CupertinoColors.systemYellow
                              .withOpacity(_sliderValue / 100),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        _buildCustomSlider(),
                        const SizedBox(
                          height: 30,
                        ),
                        DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 20.0,
                            color: CupertinoColors.white,
                            backgroundColor: Colors.transparent,
                          ),
                          child: Text(
                            'Nivel del brillo: ${_sliderValue.toStringAsFixed(0)}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                        DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 15.0,
                            color: CupertinoColors.white,
                            backgroundColor: Colors.transparent,
                          ),
                          child: Text(
                            'Versión de Hardware: $hardwareVersion',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        DefaultTextStyle(
                          style: const TextStyle(
                            fontSize: 15.0,
                            color: CupertinoColors.white,
                            backgroundColor: Colors.transparent,
                          ),
                          child: Text(
                            'Versión de SoftWare: $softwareVersion',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        CupertinoButton(
                          color: const Color(0xFF1DA3A9),
                          borderRadius: BorderRadius.circular(18.0),
                          onPressed: () {
                            showCupertinoContactInfo(context);
                          },
                          child: const Text('CONTACTANOS',
                              style: TextStyle(
                                  fontSize: 15.0,
                                  color: CupertinoColors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
