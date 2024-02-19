import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:project_022000iot_user/5773/master_detector.dart';
import 'package:project_022000iot_user/master.dart';
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
  late EasyRefreshController _controller;
  final FocusNode searchFocusNode = FocusNode();
  bool toastFlag = false;

  @override
  void initState() {
    super.initState();
    startBluetoothMonitoring();
    startLocationMonitoring();

    // setupMqtt5773();
    // setupMqtt022000();
    // setupMqtt027000();

    loadNicknamesMap().then((loadedMap) {
      setState(() {
        nicknamesMap = loadedMap;
      });
    });
    filteredDevices = devices;
    _controller = EasyRefreshController(
      controlFinishRefresh: true,
    );
    scan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }



  void scan() async {
    if (bluetoothOn) {
      printLog('Entre a escanear');
      toastFlag = false;
      try {
        await FlutterBluePlus.startScan(
            withKeywords: ['Eléctrico', 'Gas', 'Detector', 'Calefactor'],
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
              printLog('Razon: ${myDevice.device.disconnectReason?.description}');
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

//! Visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 34, 35),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: TextField(
          focusNode: searchFocusNode,
          controller: searchController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          decoration: const InputDecoration(
            icon: Icon(Icons.search),
            iconColor: Color.fromARGB(255, 255, 255, 255),
            hintText: "Filtrar por nombre",
            hintStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
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
                      backgroundColor: const Color.fromARGB(255, 37, 34, 35),
                      title: const Text(
                        '¿Estas seguro que quieres cerrar sesión?',
                        style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255)),
                      ),
                      actions: <Widget>[
                        TextButton(
                          style: const ButtonStyle(
                              foregroundColor: MaterialStatePropertyAll(
                                  Color.fromARGB(255, 255, 255, 255))),
                          child: const Text('Cerrar sesión'),
                          onPressed: () async {
                            auth.signOut();
                            Navigator.of(dialogContext)
                                .pop(); // Cierra el AlertDialog
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.exit_to_app))
        ],
      ),
      drawer: MyDrawer(
          userMail: FirebaseAuth.instance.currentUser?.email ??
              'usuario_desconocido'),
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
          textStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          iconTheme: IconThemeData(color: Color.fromARGB(255, 255, 255, 255)),
        ),
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 2));
          await FlutterBluePlus.stopScan();
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
                          'Deslice el dedo hacia abajo para buscar nuevos dispositivos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255),
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
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.bluetooth, color: Colors.white)
                    ]),
                    subtitle: Text(
                      nicknamesMap[filteredDevices[index].platformName] != null
                          ? filteredDevices[index].platformName
                          : filteredDevices[index].remoteId.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color.fromARGB(255, 189, 189, 189),
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
        } else {
          navigatorKey.currentState?.pushReplacementNamed('/detector');
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
      }
      DocumentReference documentRef =
          FirebaseFirestore.instance.collection(deviceName).doc('info');
      await documentRef.set({'tipo': deviceType}, SetOptions(merge: true));

      //Si es un calefactor
      if (deviceType == '022000' || deviceType == '027000') {
        varsValues = await myDevice.varsUuid.read();
        var parts2 = utf8.decode(varsValues).split(':');
        printLog('$parts2');
        turnOn = parts2[1] == '1';
        trueStatus = parts2[3] == '1';
        nightMode = parts2[4] == '1';
        printLog('Estado: $turnOn');

        await documentRef.set({'estado': turnOn}, SetOptions(merge: true));
        var parts3 = utf8.decode(toolsValues).split(':');
        final regex = RegExp(r'\((\d+)\)');
        final match = regex.firstMatch(parts3[2]);
        int users = int.parse(match!.group(1).toString());
        printLog('Hay $users conectados');
        userConnected = users > 1;
        lastUser = users;

        String userEmail =
            FirebaseAuth.instance.currentUser?.email ?? 'usuario_desconocido';
        var parts = utf8.decode(infoValues).split(':');
        if (parts[4] == 'NA') {
          deviceOwner = true;
          String mailData = '022000_IOT[5]($userEmail)';
          myDevice.toolsUuid.write(mailData.codeUnits);
          distOffValue = await readDistanceOffValue();
          distOnValue = await readDistanceOnValue();
          isTaskScheduled = await loadControlValue();
          sendOwner();
        } else if (parts[4] == userEmail) {
          deviceOwner = true;
          distOffValue = await readDistanceOffValue();
          distOnValue = await readDistanceOnValue();
          isTaskScheduled = await loadControlValue();
          sendOwner();
        } else {
          deviceOwner = false;
        }
      } else {
        //Si soy un detector
        workValues = await myDevice.workUuid.read();
        printLog('Valores work: $workValues');

        ppmCO = workValues[5] + (workValues[6] << 8);
        ppmCH4 = workValues[7] + (workValues[8] << 8);
        setupToken();
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      printLog('Error en la precarga $e $stackTrace');
      showToast('Error en la precarga');
      // handleManualError(e, stackTrace);
      return Future.value(false);
    }
  }

//!Visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 34, 35),
      body: Center(
          child: Stack(
        children: <Widget>[
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              SizedBox(height: 20),
              Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Cargando...',
                    style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
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
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  )),
              const SizedBox(height: 20),
            ],
          ),
        ],
      )),
    );
  }
}
