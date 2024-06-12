import 'dart:async';
import 'dart:convert';
import 'package:biocalden_smart_life/aws/dynamo/dynamo.dart';

import '../aws/dynamo/dynamo_certificates.dart';
import '/stored_data.dart';
import 'package:flutter/material.dart';
import '/master.dart';

// VARIABLES //

bool alreadySubOta = false;
List<int> varsValues = [];
bool alreadySubTools = false;
double distOnValue = 0.0;
double distOffValue = 0.0;
bool turnOn = false;
Map<String, bool> isTaskScheduled = {};
bool trueStatus = false;
bool userConnected = false;
late bool nightMode;
late bool canControlDistance;
late List<String> pikachu;

// FUNCIONES //

// CLASES //

//*-Drawer-*//Menú lateral con dispositivos

class DeviceDrawer extends StatefulWidget {
  final bool night;
  final String device;
  const DeviceDrawer({super.key, required this.night, required this.device});

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
    timeData();
    nightState = widget.night;
    printLog('NightMode status: $nightState');
  }

  void timeData() async {
    fechaSeleccionada = await cargarFechaGuardada(widget.device);
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

      result = double.parse(parts[3]) * 2 * double.parse(costController.text);

      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        loading = false;
      });
    } else {
      showToast('Primero debes ingresar un valor kW/h');
    }
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
                          Image.asset('assets/Biocalden/BiocaldenBanner.png'),
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
                          guardarFecha(widget.device).then(
                              (value) => fechaSeleccionada = DateTime.now());
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
                          : const Icon(Icons.light_mode,
                              color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 20),
                    if (deviceOwner) ...[
                      ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 189, 189, 189)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 255, 255, 255))),
                        onPressed: () {
                          if (owner != '') {
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
                                      onPressed: () {
                                        try {
                                          putOwner(
                                              service,
                                              command(deviceType),
                                              extractSerialNumber(
                                                  widget.device),
                                              '');
                                          ownedDevices.remove(deviceName);
                                          saveOwnedDevices(ownedDevices);
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
                          } else {
                            try {
                              putOwner(
                                  service,
                                  command(deviceType),
                                  extractSerialNumber(widget.device),
                                  currentUserEmail);
                              setState(() {
                                owner = currentUserEmail;
                              });
                            } catch (e, s) {
                              printLog('Error al agregar owner $e Trace: $s');
                              showToast('Error al agregar el administrador.');
                            }
                          }
                        },
                        child: owner != ''
                            ? const Text(
                                'Dejar de ser dueño\n del equipo',
                                textAlign: TextAlign.center,
                              )
                            : const Text(
                                'Reclamar propiedad\n del equipo',
                                textAlign: TextAlign.center,
                              ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (currentUserEmail == owner) ...[
                        ElevatedButton(
                          style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                              Color.fromARGB(255, 189, 189, 189),
                            ),
                            foregroundColor: MaterialStatePropertyAll(
                              Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                          onPressed: () {
                            showDialog<void>(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext dialogContext) {
                                  TextEditingController admins =
                                      TextEditingController();
                                  return AlertDialog(
                                      backgroundColor:
                                          const Color.fromARGB(255, 37, 34, 35),
                                      title: const Text(
                                        'Administradores secundarios:',
                                        style: TextStyle(
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                            fontWeight: FontWeight.bold),
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: admins,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                    255, 255, 255, 255),
                                              ),
                                              onSubmitted: (value) {
                                                if (adminDevices.length < 3) {
                                                  adminDevices
                                                      .add(admins.text.trim());
                                                  putSecondaryAdmins(
                                                      service,
                                                      command(deviceType),
                                                      extractSerialNumber(
                                                          widget.device),
                                                      adminDevices);
                                                  Navigator.of(dialogContext)
                                                      .pop();
                                                } else {
                                                  showToast(
                                                      "El máximo son 3 usuarios");
                                                }
                                              },
                                              decoration: InputDecoration(
                                                  labelText:
                                                      'Agrega el correo electronico',
                                                  labelStyle: const TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 255, 255, 255),
                                                  ),
                                                  enabledBorder:
                                                      const UnderlineInputBorder(
                                                    borderSide: BorderSide(),
                                                  ),
                                                  focusedBorder:
                                                      const UnderlineInputBorder(
                                                    borderSide: BorderSide(),
                                                  ),
                                                  suffixIcon: IconButton(
                                                      onPressed: () {
                                                        if (adminDevices
                                                                .length <
                                                            3) {
                                                          adminDevices.add(
                                                              admins.text
                                                                  .trim());
                                                          putSecondaryAdmins(
                                                              service,
                                                              command(
                                                                  deviceType),
                                                              extractSerialNumber(
                                                                  widget
                                                                      .device),
                                                              adminDevices);
                                                          Navigator.of(
                                                                  dialogContext)
                                                              .pop();
                                                        } else {
                                                          showToast(
                                                              "El máximo son 3 usuarios");
                                                        }
                                                      },
                                                      icon: const Icon(
                                                        Icons.add,
                                                        color: Color.fromARGB(
                                                            255, 255, 255, 255),
                                                      ))),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            if (adminDevices.isNotEmpty) ...[
                                              for (int i = 0;
                                                  i < adminDevices.length;
                                                  i++) ...[
                                                ListTile(
                                                  title: SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: Text(
                                                      adminDevices[i],
                                                      style: const TextStyle(
                                                        color: Color.fromARGB(
                                                            255, 255, 255, 255),
                                                      ),
                                                    ),
                                                  ),
                                                  trailing: IconButton(
                                                      onPressed: () {
                                                        adminDevices.remove(
                                                            adminDevices[i]);
                                                        putSecondaryAdmins(
                                                            service,
                                                            command(deviceType),
                                                            extractSerialNumber(
                                                                widget.device),
                                                            adminDevices);
                                                        Navigator.of(
                                                                dialogContext)
                                                            .pop();
                                                      },
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Color.fromARGB(
                                                              255,
                                                              255,
                                                              255,
                                                              255))),
                                                )
                                              ]
                                            ] else ...[
                                              const Text(
                                                'Actualmente no hay ninguna cuenta agregada...',
                                                style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 255, 255, 255),
                                                    fontWeight:
                                                        FontWeight.normal),
                                              )
                                            ]
                                          ],
                                        ),
                                      ));
                                });
                          },
                          child: const Text(
                            'Añadir administradores\n secundarios',
                            textAlign: TextAlign.center,
                          ),
                        )
                      ]
                    ]
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
                  showContactInfo(context);
                },
                child: const Text('CONTACTANOS'),
              ),
            ),
          ],
        ));
  }
}

class SilemaDrawer extends StatefulWidget {
  final bool night;
  final String device;
  const SilemaDrawer({super.key, required this.night, required this.device});

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
    timeData();
    nightState = widget.night;
    printLog('NightMode status: $nightState');
  }

  void timeData() async {
    fechaSeleccionada = await cargarFechaGuardada(widget.device);
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

      result = double.parse(parts[3]) * 2 * double.parse(costController.text);

      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        loading = false;
      });
    } else {
      showToast('Primero debes ingresar un valor kW/h');
    }
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
                          guardarFecha(widget.device).then(
                              (value) => fechaSeleccionada = DateTime.now());
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
                          : const Icon(Icons.light_mode,
                              color: Color.fromARGB(255, 0, 0, 0), size: 40),
                    ),
                    const SizedBox(height: 20),
                    if (deviceOwner) ...[
                      ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 72, 72, 72)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color.fromARGB(255, 255, 255, 255))),
                        onPressed: () {
                          if (owner != '') {
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
                                                  Color.fromARGB(
                                                      255, 0, 0, 0))),
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
                                                      255, 0, 0, 0))),
                                      child: const Text('Aceptar'),
                                      onPressed: () {
                                        try {
                                          putOwner(
                                              service,
                                              command(deviceType),
                                              extractSerialNumber(
                                                  widget.device),
                                              '');
                                          ownedDevices.remove(deviceName);
                                          saveOwnedDevices(ownedDevices);
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
                          } else {
                            try {
                              putOwner(
                                  service,
                                  command(deviceType),
                                  extractSerialNumber(widget.device),
                                  currentUserEmail);
                              setState(() {
                                owner = currentUserEmail;
                              });
                            } catch (e, s) {
                              printLog('Error al agregar owner $e Trace: $s');
                              showToast('Error al agregar el administrador.');
                            }
                          }
                        },
                        child: owner != ''
                            ? const Text(
                                'Dejar de ser dueño\n del equipo',
                                textAlign: TextAlign.center,
                              )
                            : const Text(
                                'Reclamar propiedad\n del equipo',
                                textAlign: TextAlign.center,
                              ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      if (currentUserEmail == owner) ...[
                        ElevatedButton(
                          style: const ButtonStyle(
                              backgroundColor: MaterialStatePropertyAll(
                                  Color.fromARGB(255, 72, 72, 72)),
                              foregroundColor: MaterialStatePropertyAll(
                                  Color.fromARGB(255, 255, 255, 255))),
                          onPressed: () {
                            showDialog<void>(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext dialogContext) {
                                  TextEditingController admins =
                                      TextEditingController();
                                  return AlertDialog(
                                      backgroundColor: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      title: const Text(
                                        'Administradores secundarios:',
                                        style: TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontWeight: FontWeight.bold),
                                      ),
                                      content: SingleChildScrollView(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: admins,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                    255, 0, 0, 0),
                                              ),
                                              onSubmitted: (value) {
                                                if (adminDevices.length < 3) {
                                                  adminDevices
                                                      .add(admins.text.trim());
                                                  putSecondaryAdmins(
                                                      service,
                                                      command(deviceType),
                                                      extractSerialNumber(
                                                          widget.device),
                                                      adminDevices);
                                                  Navigator.of(dialogContext)
                                                      .pop();
                                                } else {
                                                  showToast(
                                                      "El máximo son 3 usuarios");
                                                }
                                              },
                                              decoration: InputDecoration(
                                                  labelText:
                                                      'Agrega el correo electronico',
                                                  labelStyle: const TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0),
                                                  ),
                                                  enabledBorder:
                                                      const UnderlineInputBorder(
                                                    borderSide: BorderSide(),
                                                  ),
                                                  focusedBorder:
                                                      const UnderlineInputBorder(
                                                    borderSide: BorderSide(),
                                                  ),
                                                  suffixIcon: IconButton(
                                                      onPressed: () {
                                                        if (adminDevices
                                                                .length <
                                                            3) {
                                                          adminDevices.add(
                                                              admins.text
                                                                  .trim());
                                                          putSecondaryAdmins(
                                                              service,
                                                              command(
                                                                  deviceType),
                                                              extractSerialNumber(
                                                                  widget
                                                                      .device),
                                                              adminDevices);
                                                          Navigator.of(
                                                                  dialogContext)
                                                              .pop();
                                                        } else {
                                                          showToast(
                                                              "El máximo son 3 usuarios");
                                                        }
                                                      },
                                                      icon: const Icon(
                                                        Icons.add,
                                                        color: Color.fromARGB(
                                                            255, 0, 0, 0),
                                                      ))),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            if (adminDevices.isNotEmpty) ...[
                                              for (int i = 0;
                                                  i < adminDevices.length;
                                                  i++) ...[
                                                ListTile(
                                                  title: SingleChildScrollView(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    child: Text(
                                                      adminDevices[i],
                                                      style: const TextStyle(
                                                        color: Color.fromARGB(
                                                            255, 0, 0, 0),
                                                      ),
                                                    ),
                                                  ),
                                                  trailing: IconButton(
                                                      onPressed: () {
                                                        adminDevices.remove(
                                                            adminDevices[i]);
                                                        putSecondaryAdmins(
                                                            service,
                                                            command(deviceType),
                                                            extractSerialNumber(
                                                                widget.device),
                                                            adminDevices);
                                                        Navigator.of(
                                                                dialogContext)
                                                            .pop();
                                                      },
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Color.fromARGB(
                                                              255, 0, 0, 0))),
                                                )
                                              ]
                                            ] else ...[
                                              const Text(
                                                'Actualmente no hay ninguna cuenta agregada...',
                                                style: TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 0, 0, 0),
                                                    fontWeight:
                                                        FontWeight.normal),
                                              )
                                            ]
                                          ],
                                        ),
                                      ));
                                });
                          },
                          child: const Text(
                            'Añadir administradores\n secundarios',
                            textAlign: TextAlign.center,
                          ),
                        )
                      ]
                    ]
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
                      showContactInfo(context);
                    },
                    child: const Text('CONTACTANOS'))),
          ],
        ));
  }
}
