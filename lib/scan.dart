import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'aws/dynamo/dynamo.dart';
import 'aws/dynamo/dynamo_certificates.dart';
import 'aws/mqtt/mqtt.dart';
import 'stored_data.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '015773/master_detector.dart';
import 'master.dart';
import 'calefactores/master_calefactor.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  ScanPageState createState() => ScanPageState();
}

class ScanPageState extends State<ScanPage> {
  List<BluetoothDevice> devices = [];
  List<BluetoothDevice> filteredDevices = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  final EasyRefreshController _controller = EasyRefreshController(
    controlFinishRefresh: true,
  );
  final FocusNode searchFocusNode = FocusNode();
  bool toastFlag = false;
  int connectionTry = 0;

  @override
  void initState() {
    super.initState();
    startBluetoothMonitoring();
    startLocationMonitoring();

    filteredDevices = devices;

    printLog('Holis $bluetoothOn');

    getMail();

    scan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void scan() {
    printLog('Jiji');
    if (bluetoothOn) {
      printLog('Entre a escanear');
      toastFlag = false;
      try {
        FlutterBluePlus.startScan(
            withKeywords: [
              'Eléctrico',
              'Gas',
              'Detector',
              'Radiador',
              'Módulo',
              'Domótica'
            ],
            timeout: const Duration(seconds: 30),
            androidUsesFineLocation: true,
            continuousUpdates: true);
        FlutterBluePlus.scanResults.listen((results) {
          for (ScanResult result in results) {
            if (!devices
                .any((device) => device.remoteId == result.device.remoteId)) {
              setState(() {
                devices.add(result.device);
                devices
                    .sort((a, b) => a.platformName.compareTo(b.platformName));
                filteredDevices = devices;
              });
            }
          }
        });
      } catch (e, stackTrace) {
        printLog('Error al escanear $e $stackTrace');
        showToast('Error al escanear, intentelo nuevamente');
      }
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 6));
      deviceName = device.platformName;
      myDeviceid = device.remoteId.toString();

      printLog('Teoricamente estoy conectado');

      MyDevice myDevice = MyDevice();

      device.connectionState.listen((BluetoothConnectionState state) {
        printLog('Estado de conexión: $state');
        switch (state) {
          case BluetoothConnectionState.disconnected:
            {
              if (!toastFlag) {
                showToast('Dispositivo desconectado');
                toastFlag = true;
              }
              nameOfWifi = '';
              connectionFlag = false;
              alreadySubOta = false;
              printLog(
                  'Razon: ${myDevice.device.disconnectReason?.description}');
              navigatorKey.currentState?.pushReplacementNamed('/scan');
              break;
            }
          case BluetoothConnectionState.connected:
            {
              if (!connectionFlag) {
                connectionFlag = true;
                FlutterBluePlus.stopScan();
                myDevice.setup(device).then((valor) {
                  printLog('RETORNASHE $valor');
                  connectionTry = 0;
                  if (valor) {
                    navigatorKey.currentState?.pushReplacementNamed('/loading');
                  } else {
                    connectionFlag = false;
                    printLog('Fallo en el setup');
                    showToast('Error en el dispositivo, intente nuevamente');
                    myDevice.device.disconnect();
                  }
                });
              } else {
                printLog('Las chistosadas se apoderan del mundo');
              }
              break;
            }
          default:
            break;
        }
      });
    } catch (e, stackTrace) {
      if (connectionTry < 3) {
        printLog('Retry');
        connectionTry++;
        connectToDevice(device);
      } else {
        connectionTry = 0;
        if (e is FlutterBluePlusException && e.code == 133) {
          printLog('Error específico de Android con código 133: $e');
          showToast('Error de conexión, intentelo nuevamente');
        } else {
          printLog('Error al conectar: $e $stackTrace');
          showToast('Error al conectar, intentelo nuevamente');
          // handleManualError(e, stackTrace);
        }
      }
    }
  }

//! Visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E242B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF9C9D98),
        title: TextField(
          focusNode: searchFocusNode,
          controller: searchController,
          keyboardType: TextInputType.text,
          style: const TextStyle(
            color: Color(0xFFB2B5AE),
          ),
          decoration: const InputDecoration(
            icon: Icon(Icons.search),
            iconColor: Color(0xFFB2B5AE),
            hintText: "Filtrar por nombre",
            hintStyle: TextStyle(
              color: Color(0xFFB2B5AE),
            ),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              filteredDevices = devices
                  .where((device) => device.platformName
                      .toLowerCase()
                      .contains(value.toLowerCase()))
                  .toList();
            });
          },
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    backgroundColor: const Color(0xFF1E242B),
                    title: const Row(
                      children: [
                        Text(
                          'Mi perfil:',
                          style: TextStyle(
                            color: Color(0xFFB2B5AE),
                          ),
                        ),
                        Spacer(),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFB2B5AE),
                          child: Icon(Icons.person, color: Color(0xFF1E242B)),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Cuenta conectada:',
                          style: TextStyle(
                              color: Color(0xFFB2B5AE),
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currentUserEmail,
                          style: const TextStyle(
                            color: Color(0xFFB2B5AE),
                          ),
                        ),
                        const Text(
                          'Cantidad de equipos registrados:',
                          style: TextStyle(
                              color: Color(0xFFB2B5AE),
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          previusConnections.length.toString(),
                          style: const TextStyle(
                            color: Color(0xFFB2B5AE),
                          ),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        style: const ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll(
                            Color(0xFFB2B5AE),
                          ),
                        ),
                        child: const Text('Cerrar sesión'),
                        onPressed: () {
                          Amplify.Auth.signOut();
                          asking();
                          previusConnections.clear();
                          guardarLista(previusConnections);
                          for (int i = 0; i < topicsToSub.length; i++) {
                            unSubToTopicMQTT(topicsToSub[i]);
                          }
                          topicsToSub.clear();
                          saveTopicList(topicsToSub);
                          backTimer?.cancel();
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(
              Icons.person,
              color: Color(0xFF9C9D98),
            ),
          )
        ],
      ),
      drawer: MyDrawer(userMail: currentUserEmail),
      body: EasyRefresh(
        controller: _controller,
        header: const ClassicHeader(
          dragText: 'Desliza para reescanear',
          armedText:
              'Suelta para reescanear\nO desliza para arriba para cancelar',
          readyText: 'Reescaneando dispositivos',
          processingText: 'Reescaneando dispositivos',
          processedText: 'Reescaneo completo',
          showMessage: false,
          textStyle: TextStyle(color: Color(0xFFB2B5AE)),
          iconTheme: IconThemeData(color: Color(0xFF9C9D98)),
        ),
        onRefresh: () async {
          await FlutterBluePlus.stopScan();
          await Future.delayed(const Duration(seconds: 2));
          setState(() {
            devices.clear();
          });
          scan();
          _controller.finishRefresh();
        },
        child: filteredDevices.isEmpty
            ? ListView(
                children: const [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Deslice el dedo hacia abajo para buscar nuevos dispositivos cercanos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB2B5AE),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: filteredDevices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Row(children: [
                      Text(
                        nicknamesMap[filteredDevices[index].platformName] ??
                            filteredDevices[index].platformName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB2B5AE),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.bluetooth, color: Color(0xFFB2B5AE)),
                      // const SizedBox(width: double.infinity),
                      if (filteredDevices[index]
                          .platformName
                          .contains('Detector')) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset('assets/IntelligentGas/G.png'),
                          ),
                        ),
                      ] else if (filteredDevices[index]
                          .platformName
                          .contains('Radiador')) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: Image.asset('assets/Silema/WB_logo.png'),
                          ),
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            // child: Icon(Bio.bio, color: Colors.green)
                            child: Image.asset('assets/Biocalden/B_negra.png'),
                          ),
                        )
                      ],
                    ]),
                    subtitle: Text(
                      nicknamesMap[filteredDevices[index].platformName] != null
                          ? filteredDevices[index].platformName
                          : filteredDevices[index].remoteId.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF9C9D98),
                      ),
                    ),
                    onTap: () {
                      connectToDevice(filteredDevices[index]);
                      showToast('Intentando conectarse al dispositivo...');
                    },
                  );
                },
              ),
      ),
    );
  }
}

//LOADING PAGE

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});
  @override
  LoadState createState() => LoadState();
}

class LoadState extends State<LoadingPage> {
  MyDevice myDevice = MyDevice();

  @override
  void initState() {
    super.initState();
    printLog('HOSTIAAAAAAAAAAAAAAAAAAAAAAAA');
    precharge().then((precharge) {
      if (precharge == true) {
        showToast('Dispositivo conectado exitosamente');
        if (deviceType == '022000' || deviceType == '027000') {
          navigatorKey.currentState?.pushReplacementNamed('/calefactor');
        } else if (deviceType == '041220') {
          navigatorKey.currentState?.pushReplacementNamed('/radiador');
        } else if (deviceType == '015773') {
          navigatorKey.currentState?.pushReplacementNamed('/detector');
        } else if (deviceType == '020010') {
          navigatorKey.currentState?.pushReplacementNamed('/io');
        }
      } else {
        showToast('Error en el dispositivo, intente nuevamente');
        myDevice.device.disconnect();
      }
    });
  }

  Future<bool> precharge() async {
    try {
      printLog('Estoy precargando');
      await myDevice.device.requestMtu(255);
      toolsValues = await myDevice.toolsUuid.read();
      printLog('Valores tools: $toolsValues');
      printLog('Valores info: $infoValues');
      if (!previusConnections.contains(deviceName)) {
        previusConnections.add(deviceName);
        guardarLista(previusConnections);
        topicsToSub.add(
            'devices_tx/${command(deviceName)}/${extractSerialNumber(deviceName)}');
        saveTopicList(topicsToSub);
        subToTopicMQTT(
            'devices_tx/${command(deviceName)}/${extractSerialNumber(deviceName)}');
      }
      deviceSerialNumber = extractSerialNumber(deviceName);

      await queryItems(service, command(deviceName), deviceSerialNumber);

      //Si es un calefactor
      if (deviceType == '022000' ||
          deviceType == '027000' ||
          deviceType == '041220') {
        varsValues = await myDevice.varsUuid.read();
        var parts2 = utf8.decode(varsValues).split(':');
        printLog('Valores Vars: $parts2');
        var list = await loadDevicesForDistanceControl();
        canControlDistance =
            list.contains(deviceName) ? true : parts2[0] == '0';
        printLog(
            'Puede utilizar el control por distancia: $canControlDistance');
        turnOn = parts2[2] == '1';
        trueStatus = parts2[4] == '1';
        nightMode = parts2[5] == '1';
        printLog('Estado: $turnOn');

        var parts3 = utf8.decode(toolsValues).split(':');
        final regex = RegExp(r'\((\d+)\)');
        final match = regex.firstMatch(parts3[2]);
        int users = int.parse(match!.group(1).toString());
        printLog('Hay $users conectados');
        userConnected = users > 1;
        lastUser = users;
        owner = globalDATA[
                    '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                'owner'] ??
            '';
        printLog('Owner actual: $owner');
        adminDevices = await getSecondaryAdmins(
            service, command(deviceName), extractSerialNumber(deviceName));
        printLog('Administradores: $adminDevices');

        if (owner != '') {
          if (owner == currentUserEmail) {
            deviceOwner = true;
          } else {
            deviceOwner = false;
            if (userConnected) {
            } else {
              if (adminDevices.contains(currentUserEmail)) {
                secondaryAdmin = true;
              } else {
                secondaryAdmin = false;
              }
            }
          }
        } else {
          deviceOwner = true;
        }

        await analizePayment(
            command(deviceName), extractSerialNumber(deviceName));

        if (payAT) {
          activatedAT = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']
                  ?['AT'] ??
              false;
          tenant = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']
                  ?['tenant'] ==
              currentUserEmail;
        } else {
          activatedAT = false;
          tenant = false;
        }

        if (canControlDistance) {
          distOffValue = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                  'distanceOff'] ??
              100.0;
          distOnValue = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                  'distanceOn'] ??
              3000.0;
          isTaskScheduled = await loadControlValue();
        }

        globalDATA
            .putIfAbsent(
                '${command(deviceName)}/${extractSerialNumber(deviceName)}',
                () => {})
            .addAll({"w_status": turnOn});
        globalDATA
            .putIfAbsent(
                '${command(deviceName)}/${extractSerialNumber(deviceName)}',
                () => {})
            .addAll({"f_status": trueStatus});

        saveGlobalData(globalDATA);
      } else if (deviceType == '015773') {
        //Si soy un detector
        workValues = await myDevice.workUuid.read();
        printLog('Valores work: $workValues');

        ppmCO = workValues[5] + (workValues[6] << 8);
        ppmCH4 = workValues[7] + (workValues[8] << 8);
        picoMaxppmCO = workValues[9] + (workValues[10] << 8);
        picoMaxppmCH4 = workValues[11] + (workValues[12] << 8);
        promedioppmCO = workValues[17] + (workValues[18] << 8);
        promedioppmCH4 = workValues[19] + (workValues[20] << 8);
        daysToExpire = workValues[21] + (workValues[22] << 8);

        globalDATA
            .putIfAbsent(
                '${command(deviceName)}/${extractSerialNumber(deviceName)}',
                () => {})
            .addAll({"ppmCO": ppmCO});
        globalDATA
            .putIfAbsent(
                '${command(deviceName)}/${extractSerialNumber(deviceName)}',
                () => {})
            .addAll({"ppmCH4": ppmCH4});
        globalDATA
            .putIfAbsent(
                '${command(deviceName)}/${extractSerialNumber(deviceName)}',
                () => {})
            .addAll({"alert": workValues[4] == 1});
        saveGlobalData(globalDATA);
        setupToken(
            command(deviceName), extractSerialNumber(deviceName), deviceName);
      } else if (deviceType == '020010') {
        ioValues = await myDevice.ioUuid.read();
        printLog('Valores IO: $ioValues');

        owner = globalDATA[
                    '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                'owner'] ??
            '';
        printLog('Owner actual: $owner');
        adminDevices = await getSecondaryAdmins(
            service, command(deviceName), extractSerialNumber(deviceName));
        printLog('Administradores: $adminDevices');

        if (owner != '') {
          if (owner == currentUserEmail) {
            deviceOwner = true;
          } else {
            deviceOwner = false;
            if (userConnected) {
            } else {
              if (adminDevices.contains(currentUserEmail)) {
                secondaryAdmin = true;
              } else {
                secondaryAdmin = false;
              }
            }
          }
        } else {
          deviceOwner = true;
        }

        await analizePayment(
            command(deviceName), extractSerialNumber(deviceName));

        if (payAT) {
          activatedAT = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']
                  ?['AT'] ??
              false;
          tenant = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']
                  ?['tenant'] ==
              currentUserEmail;
        } else {
          activatedAT = false;
          tenant = false;
        }
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      printLog('Error en la precarga $e $stackTrace');
      showToast('Error en la precarga');
      // handleManualError('$e', '$stackTrace');
      return Future.value(false);
    }
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E242B),
      body: Center(
        child: Stack(
          children: <Widget>[
            const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color(0xFFB2B5AE),
                ),
                SizedBox(height: 20),
                Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Cargando...',
                      style: TextStyle(color: Color(0xFFB2B5AE)),
                    )),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      'Versión $appVersionNumber',
                      style: const TextStyle(
                          color: Color(0xFF9C9D98), fontSize: 12),
                    )),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//!-------------------------------------IOS Widget-------------------------------------!\\

class IOSScanPage extends StatefulWidget {
  const IOSScanPage({super.key});
  @override
  IOSScanPageState createState() => IOSScanPageState();
}

class IOSScanPageState extends State<IOSScanPage> {
  List<BluetoothDevice> devices = [];
  List<BluetoothDevice> filteredDevices = [];
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  final EasyRefreshController _controller = EasyRefreshController(
    controlFinishRefresh: true,
  );
  final FocusNode searchFocusNode = FocusNode();
  bool toastFlag = false;
  int connectionTry = 0;

  @override
  void initState() {
    super.initState();
    startBluetoothMonitoring();
    startLocationMonitoring();

    filteredDevices = devices;

    printLog('Holis $bluetoothOn');

    getMail();

    scan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void scan() {
    printLog('Jiji');
    if (bluetoothOn) {
      printLog('Entre a escanear');
      toastFlag = false;
      try {
        FlutterBluePlus.startScan(
            withKeywords: [
              'Eléctrico',
              'Gas',
              'Detector',
              'Radiador',
              'Módulo',
              'Domótica'
            ],
            timeout: const Duration(seconds: 30),
            androidUsesFineLocation: true,
            continuousUpdates: true);
        FlutterBluePlus.scanResults.listen((results) {
          for (ScanResult result in results) {
            if (!devices
                .any((device) => device.remoteId == result.device.remoteId)) {
              setState(() {
                devices.add(result.device);
                devices
                    .sort((a, b) => a.platformName.compareTo(b.platformName));
                filteredDevices = devices;
              });
            }
          }
        });
      } catch (e, stackTrace) {
        printLog('Error al escanear $e $stackTrace');
        showToast('Error al escanear, intentelo nuevamente');
      }
    }
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(timeout: const Duration(seconds: 6));
      deviceName = device.platformName;
      myDeviceid = device.remoteId.toString();

      printLog('Teoricamente estoy conectado');

      MyDevice myDevice = MyDevice();

      device.connectionState.listen((BluetoothConnectionState state) {
        printLog('Estado de conexión: $state');
        switch (state) {
          case BluetoothConnectionState.disconnected:
            {
              if (!toastFlag) {
                showToast('Dispositivo desconectado');
                toastFlag = true;
              }
              nameOfWifi = '';
              connectionFlag = false;
              alreadySubOta = false;
              printLog(
                  'Razon: ${myDevice.device.disconnectReason?.description}');
              navigatorKey.currentState?.pushReplacementNamed('/scan');
              break;
            }
          case BluetoothConnectionState.connected:
            {
              if (!connectionFlag) {
                connectionFlag = true;
                FlutterBluePlus.stopScan();
                myDevice.setup(device).then((valor) {
                  printLog('RETORNASHE $valor');
                  connectionTry = 0;
                  if (valor) {
                    navigatorKey.currentState?.pushReplacementNamed('/loading');
                  } else {
                    connectionFlag = false;
                    printLog('Fallo en el setup');
                    showToast('Error en el dispositivo, intente nuevamente');
                    myDevice.device.disconnect();
                  }
                });
              } else {
                printLog('Las chistosadas se apoderan del mundo');
              }
              break;
            }
          default:
            break;
        }
      });
    } catch (e, stackTrace) {
      if (connectionTry < 3) {
        printLog('Retry');
        connectionTry++;
        connectToDevice(device);
      } else {
        connectionTry = 0;
        if (e is FlutterBluePlusException && e.code == 133) {
          printLog('Error específico de Android con código 133: $e');
          showToast('Error de conexión, intentelo nuevamente');
        } else {
          printLog('Error al conectar: $e $stackTrace');
          showToast('Error al conectar, intentelo nuevamente');
          // handleManualError(e, stackTrace);
        }
      }
    }
  }

//! Visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E242B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF9C9D98),
        title: CupertinoTextField(
          focusNode: searchFocusNode,
          controller: searchController,
          keyboardType: TextInputType.text,
          style: const TextStyle(
            color: Color(0xFFB2B5AE),
          ),
          placeholder: "Filtrar por nombre",
          placeholderStyle: const TextStyle(
            color: Color(0xFFB2B5AE),
          ),
          prefix: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              CupertinoIcons.search,
              color: Color(0xFFB2B5AE),
            ),
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
          ),
          onChanged: (value) {
            setState(() {
              filteredDevices = devices
                  .where((device) => device.platformName
                      .toLowerCase()
                      .contains(value.toLowerCase()))
                  .toList();
            });
          },
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              showCupertinoDialog<void>(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext dialogContext) {
                  return CupertinoAlertDialog(
                    title: const Row(
                      children: [
                        Text(
                          'Mi perfil:',
                          style: TextStyle(
                            color: CupertinoColors.label,
                          ),
                        ),
                        Spacer(),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Color(0xFFB2B5AE),
                          child: Icon(Icons.person, color: Color(0xFF1E242B)),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                      ],
                    ),
                    content: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Cuenta conectada:',
                          style: TextStyle(
                              color: CupertinoColors.label,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currentUserEmail,
                          style: const TextStyle(
                            color: CupertinoColors.label,
                          ),
                        ),
                        const Text(
                          'Cantidad de equipos registrados:',
                          style: TextStyle(
                              color: CupertinoColors.label,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          previusConnections.length.toString(),
                          style: const TextStyle(
                            color: CupertinoColors.label,
                          ),
                        ),
                      ],
                    ),
                    actions: <Widget>[
                      TextButton(
                        style: const ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll(
                            CupertinoColors.label,
                          ),
                        ),
                        child: const Text('Cerrar sesión'),
                        onPressed: () {
                          Amplify.Auth.signOut();
                          asking();
                          previusConnections.clear();
                          guardarLista(previusConnections);
                          for (int i = 0; i < topicsToSub.length; i++) {
                            unSubToTopicMQTT(topicsToSub[i]);
                          }
                          topicsToSub.clear();
                          saveTopicList(topicsToSub);
                          backTimer?.cancel();
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(
              CupertinoIcons.person,
              color: Color(0xFF9C9D98),
            ),
          )
        ],
      ),
      drawer: MyDrawer(userMail: currentUserEmail),
      body: EasyRefresh(
        controller: _controller,
        header: const ClassicHeader(
          dragText: 'Desliza para reescanear',
          armedText:
              'Suelta para reescanear\nO desliza para arriba para cancelar',
          readyText: 'Reescaneando dispositivos',
          processingText: 'Reescaneando dispositivos',
          processedText: 'Reescaneo completo',
          showMessage: false,
          textStyle: TextStyle(color: Color(0xFFB2B5AE)),
          iconTheme: IconThemeData(color: Color(0xFF9C9D98)),
        ),
        onRefresh: () async {
          await FlutterBluePlus.stopScan();
          await Future.delayed(const Duration(seconds: 2));
          setState(() {
            devices.clear();
          });
          scan();
          _controller.finishRefresh();
        },
        child: filteredDevices.isEmpty
            ? ListView(
                children: const [
                  Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Deslice el dedo hacia abajo para buscar nuevos dispositivos cercanos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB2B5AE),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                itemCount: filteredDevices.length,
                itemBuilder: (context, index) {
                  return CupertinoListTile(
                    backgroundColorActivated: const Color(0xFF454749),
                    title: Row(children: [
                      Text(
                        nicknamesMap[filteredDevices[index].platformName] ??
                            filteredDevices[index].platformName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB2B5AE),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.bluetooth, color: Color(0xFFB2B5AE)),
                      const SizedBox(height: 40),
                      // const SizedBox(width: double.infinity),
                      if (filteredDevices[index]
                          .platformName
                          .contains('Detector')) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            child: Image.asset('assets/IntelligentGas/G.png'),
                          ),
                        ),
                      ] else if (filteredDevices[index]
                          .platformName
                          .contains('Radiador')) ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: Image.asset('assets/Silema/WB_logo.png'),
                          ),
                        ),
                      ] else ...[
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            height: 20,
                            width: 20,
                            // child: Icon(Bio.bio, color: Colors.green)
                            child: Image.asset('assets/Biocalden/B_negra.png'),
                          ),
                        )
                      ],
                    ]),
                    subtitle: Text(
                      nicknamesMap[filteredDevices[index].platformName] != null
                          ? filteredDevices[index].platformName
                          : filteredDevices[index].remoteId.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF9C9D98),
                      ),
                    ),
                    onTap: () {
                      connectToDevice(filteredDevices[index]);
                      showToast('Intentando conectarse al dispositivo...');
                    },
                  );
                },
              ),
      ),
    );
  }
}

//*-PROVIDER-*// Actualización de data

//LOADING PAGE

class IOSLoadingPage extends StatefulWidget {
  const IOSLoadingPage({super.key});
  @override
  IOSLoadState createState() => IOSLoadState();
}

class IOSLoadState extends State<IOSLoadingPage> {
  MyDevice myDevice = MyDevice();

  @override
  void initState() {
    super.initState();
    printLog('HOSTIAAAAAAAAAAAAAAAAAAAAAAAA');
    precharge().then((precharge) {
      if (precharge == true) {
        showToast('Dispositivo conectado exitosamente');
        if (deviceType == '022000' || deviceType == '027000') {
          navigatorKey.currentState?.pushReplacementNamed('/calefactor');
        } else if (deviceType == '041220') {
          navigatorKey.currentState?.pushReplacementNamed('/radiador');
        } else if (deviceType == '015773') {
          navigatorKey.currentState?.pushReplacementNamed('/detector');
        } else if (deviceType == '020010') {
          navigatorKey.currentState?.pushReplacementNamed('/io');
        }
      } else {
        showToast('Error en el dispositivo, intente nuevamente');
        myDevice.device.disconnect();
      }
    });
  }

  Future<bool> precharge() async {
    try {
      printLog('Estoy precargando');
      await myDevice.device.requestMtu(255);
      toolsValues = await myDevice.toolsUuid.read();
      printLog('Valores tools: $toolsValues');
      printLog('Valores info: $infoValues');
      if (!previusConnections.contains(deviceName)) {
        previusConnections.add(deviceName);
        guardarLista(previusConnections);
        topicsToSub.add(
            'devices_tx/${command(deviceName)}/${extractSerialNumber(deviceName)}');
        saveTopicList(topicsToSub);
        subToTopicMQTT(
            'devices_tx/${command(deviceName)}/${extractSerialNumber(deviceName)}');
      }
      deviceSerialNumber = extractSerialNumber(deviceName);

      await queryItems(service, command(deviceName), deviceSerialNumber);

      //Si es un calefactor
      if (deviceType == '022000' ||
          deviceType == '027000' ||
          deviceType == '041220') {
        varsValues = await myDevice.varsUuid.read();
        var parts2 = utf8.decode(varsValues).split(':');
        printLog('$parts2');
        var list = await loadDevicesForDistanceControl();
        canControlDistance =
            list.contains(deviceName) ? true : parts2[0] == '0';
        printLog(
            'Puede utilizar el control por distancia: $canControlDistance');
        turnOn = parts2[2] == '1';
        trueStatus = parts2[4] == '1';
        nightMode = parts2[5] == '1';
        printLog('Estado: $turnOn');

        var parts3 = utf8.decode(toolsValues).split(':');
        final regex = RegExp(r'\((\d+)\)');
        final match = regex.firstMatch(parts3[2]);
        int users = int.parse(match!.group(1).toString());
        printLog('Hay $users conectados');
        userConnected = users > 1;
        lastUser = users;
        owner = globalDATA[
                    '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                'owner'] ??
            '';
        printLog('Owner actual: $owner');
        adminDevices = await getSecondaryAdmins(
            service, command(deviceName), extractSerialNumber(deviceName));
        printLog('Administradores: $adminDevices');

        if (owner != '') {
          if (owner == currentUserEmail) {
            deviceOwner = true;
          } else {
            deviceOwner = false;
            if (userConnected) {
            } else {
              if (adminDevices.contains(currentUserEmail)) {
                secondaryAdmin = true;
              } else {
                secondaryAdmin = false;
              }
            }
          }
        } else {
          deviceOwner = true;
        }

        await analizePayment(
            command(deviceName), extractSerialNumber(deviceName));

        if (payAT) {
          activatedAT = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']
                  ?['AT'] ??
              false;
          tenant = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']
                  ?['tenant'] ==
              currentUserEmail;
        } else {
          activatedAT = false;
          tenant = false;
        }

        if (canControlDistance) {
          distOffValue = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                  'distanceOff'] ??
              100.0;
          distOnValue = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                  'distanceOn'] ??
              3000.0;
          isTaskScheduled = await loadControlValue();
        }

        globalDATA
            .putIfAbsent(
                '${command(deviceName)}/${extractSerialNumber(deviceName)}',
                () => {})
            .addAll({"w_status": turnOn});
        globalDATA
            .putIfAbsent(
                '${command(deviceName)}/${extractSerialNumber(deviceName)}',
                () => {})
            .addAll({"f_status": trueStatus});

        saveGlobalData(globalDATA);
      } else if (deviceType == '015773') {
        //Si soy un detector
        workValues = await myDevice.workUuid.read();
        printLog('Valores work: $workValues');

        ppmCO = workValues[5] + (workValues[6] << 8);
        ppmCH4 = workValues[7] + (workValues[8] << 8);
        picoMaxppmCO = workValues[9] + (workValues[10] << 8);
        picoMaxppmCH4 = workValues[11] + (workValues[12] << 8);
        promedioppmCO = workValues[17] + (workValues[18] << 8);
        promedioppmCH4 = workValues[19] + (workValues[20] << 8);
        daysToExpire = workValues[21] + (workValues[22] << 8);

        globalDATA
            .putIfAbsent(
                '${command(deviceName)}/${extractSerialNumber(deviceName)}',
                () => {})
            .addAll({"ppmCO": ppmCO});
        globalDATA
            .putIfAbsent(
                '${command(deviceName)}/${extractSerialNumber(deviceName)}',
                () => {})
            .addAll({"ppmCH4": ppmCH4});
        globalDATA
            .putIfAbsent(
                '${command(deviceName)}/${extractSerialNumber(deviceName)}',
                () => {})
            .addAll({"alert": workValues[4] == 1});
        saveGlobalData(globalDATA);
        setupToken(
            command(deviceName), extractSerialNumber(deviceName), deviceName);
      } else if (deviceType == '020010') {
        ioValues = await myDevice.ioUuid.read();
        printLog('Valores IO: $ioValues');

        owner = globalDATA[
                    '${command(deviceName)}/${extractSerialNumber(deviceName)}']![
                'owner'] ??
            '';
        printLog('Owner actual: $owner');
        adminDevices = await getSecondaryAdmins(
            service, command(deviceName), extractSerialNumber(deviceName));
        printLog('Administradores: $adminDevices');

        if (owner != '') {
          if (owner == currentUserEmail) {
            deviceOwner = true;
          } else {
            deviceOwner = false;
            if (userConnected) {
            } else {
              if (adminDevices.contains(currentUserEmail)) {
                secondaryAdmin = true;
              } else {
                secondaryAdmin = false;
              }
            }
          }
        } else {
          deviceOwner = true;
        }

        await analizePayment(
            command(deviceName), extractSerialNumber(deviceName));

        if (payAT) {
          activatedAT = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']
                  ?['AT'] ??
              false;
          tenant = globalDATA[
                      '${command(deviceName)}/${extractSerialNumber(deviceName)}']
                  ?['tenant'] ==
              currentUserEmail;
        } else {
          activatedAT = false;
          tenant = false;
        }
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      printLog('Error en la precarga $e $stackTrace');
      showToast('Error en la precarga');
      // handleManualError('$e', '$stackTrace');
      return Future.value(false);
    }
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
        style: const TextStyle(
          fontSize: 16.0,
        ),
        child: CupertinoPageScaffold(
          backgroundColor: const Color(0xFF1E242B),
          child: Center(
              child: Stack(
            children: <Widget>[
              const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoActivityIndicator(
                    color: Color(0xFFB2B5AE),
                  ),
                  SizedBox(height: 20),
                  Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Cargando...',
                        style: TextStyle(color: Color(0xFFB2B5AE)),
                      )),
                ],
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        'Versión $appVersionNumber',
                        style: const TextStyle(
                            color: Color(0xFF9C9D98), fontSize: 12),
                      )),
                  const SizedBox(height: 20),
                ],
              ),
            ],
          )),
        ));
  }
}
