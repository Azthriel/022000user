import 'dart:async';
import 'dart:convert';
import '../aws/dynamo/dynamo.dart';
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
  final String device;
  const DeviceDrawer({super.key, required this.device});

  @override
  DeviceDrawerState createState() => DeviceDrawerState();
}

class DeviceDrawerState extends State<DeviceDrawer> {
  final TextEditingController costController = TextEditingController();
  late bool loading;
  bool buttonPressed = false;
  double result = 0.0;
  DateTime? fechaSeleccionada;
  String measure = deviceType == '022000' ? 'KW/h' : 'M³/h';
  String tiempo = '';

  @override
  void initState() {
    super.initState();
    timeData();
    printLog('NightMode status: $nightMode');
  }

  void timeData() async {
    fechaSeleccionada = await cargarFechaGuardada(widget.device);
    List<int> list = await myDevice.varsUuid.read(timeout: 2);
    tiempo = utf8.decode(list).split(':')[3];
    printLog('Tiempo: $tiempo');
  }

  void makeCompute() async {
    if (tiempo != '') {
      if (costController.text.isNotEmpty) {
        setState(() {
          buttonPressed = true;
          loading = true;
        });
        printLog('Estoy haciendo calculaciones misticas');

        result =
            double.parse(tiempo) * 2 * double.parse(costController.text.trim());

        await Future.delayed(const Duration(seconds: 1));

        printLog('Calculaciones terminadas');

        setState(() {
          loading = false;
        });
      } else {
        showToast('Primero debes ingresar un valor kW/h');
      }
    } else {
      showToast(
          'Error al hacer el calculo\n Por favor cierra y vuelve a abrir el menú');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: const Color(0xFF252223),
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
                              color: Color(0xFFFFFFFF)),
                          cursorColor: const Color(0xFFBDBDBD),
                          decoration: InputDecoration(
                            labelText: 'Ingresa valor $measure',
                            labelStyle: const TextStyle(
                                color: Color(0xFFFFFFFF)),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFFBDBDBD)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFFBDBDBD)),
                            ),
                          ),
                        )),
                    const SizedBox(height: 10),
                    if (buttonPressed) ...[
                      Visibility(
                          visible: loading,
                          child: const CircularProgressIndicator(
                              color: Color(0xFFFFFFFF))),
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
                                Color(0xFFBDBDBD)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color(0xFFFFFFFF))),
                        onPressed: makeCompute,
                        child: const Text('Hacer calculo')),
                    ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color(0xFFBDBDBD)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color(0xFFFFFFFF))),
                        onPressed: () {
                          guardarFecha(widget.device).then(
                              (value) => fechaSeleccionada = DateTime.now());
                          String data = '${command(deviceName)}[10](0)';
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
                    const SizedBox(height: 5),
                    Transform.scale(
                      scale: 1.5,
                      child: Switch(
                        activeColor: const Color(0xFFBDBDBD),
                        activeTrackColor:
                            const Color(0xFFFFFFFF),
                        inactiveThumbColor:
                            const Color(0xFFFFFFFF),
                        inactiveTrackColor:
                            const Color(0xFFBDBDBD),
                        trackOutlineColor: const MaterialStatePropertyAll(
                            Color(0xFFBDBDBD)),
                        thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return const Icon(Icons.nights_stay,
                                  color: Colors.white);
                            } else {
                              return const Icon(Icons.wb_sunny,
                                  color: Color(0xFFBDBDBD));
                            }
                          },
                        ),
                        value: nightMode,
                        onChanged: (value) {
                          setState(() {
                            nightMode = !nightMode;
                            printLog('Estado: $nightMode');
                            int fun = nightMode ? 1 : 0;
                            String data = '${command(deviceName)}[9]($fun)';
                            printLog(data);
                            myDevice.toolsUuid.write(data.codeUnits);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (deviceOwner) ...[
                      ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color(0xFFBDBDBD)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color(0xFFFFFFFF))),
                        onPressed: () {
                          if (owner != '') {
                            showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  backgroundColor:
                                      const Color(0xFF252223),
                                  title: const Text(
                                    '¿Dejar de ser administrador del calefactor?',
                                    style: TextStyle(
                                        color:
                                            Color(0xFFFFFFFF)),
                                  ),
                                  content: const Text(
                                    'Esto hará que otras personas puedan conectarse al dispositivo y modificar sus parámetros',
                                    style: TextStyle(
                                        color:
                                            Color(0xFFFFFFFF)),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      style: const ButtonStyle(
                                          foregroundColor:
                                              MaterialStatePropertyAll(
                                                  Color(0xFFFFFFFF))),
                                      child: const Text('Cancelar'),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                    TextButton(
                                      style: const ButtonStyle(
                                          foregroundColor:
                                              MaterialStatePropertyAll(
                                                  Color(0xFFFFFFFF))),
                                      child: const Text('Aceptar'),
                                      onPressed: () {
                                        try {
                                          putOwner(
                                              service,
                                              command(deviceName),
                                              extractSerialNumber(
                                                  widget.device),
                                              '');
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
                                  command(deviceName),
                                  extractSerialNumber(widget.device),
                                  currentUserEmail);
                              setState(() {
                                owner = currentUserEmail;
                              });
                            } catch (e, s) {
                              printLog('Error al agregar owner $e Trace: $s');
                              showToast('Error al agregar el propietario.');
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
                              Color(0xFFBDBDBD),
                            ),
                            foregroundColor: MaterialStatePropertyAll(
                              Color(0xFFFFFFFF),
                            ),
                          ),
                          onPressed: () async {
                            adminDevices = await getSecondaryAdmins(
                                service,
                                command(deviceName),
                                extractSerialNumber(deviceName));
                            showDialog<void>(
                                context: navigatorKey.currentContext!,
                                barrierDismissible: true,
                                builder: (BuildContext dialogContext) {
                                  TextEditingController admins =
                                      TextEditingController();
                                  return AlertDialog(
                                      backgroundColor:
                                          const Color(0xFF252223),
                                      title: const Text(
                                        'Administradores secundarios:',
                                        style: TextStyle(
                                            color: Color(0xFFFFFFFF),
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
                                                color: Color(0xFFFFFFFF),
                                              ),
                                              onSubmitted: (value) {
                                                if (adminDevices.length < 3) {
                                                  adminDevices
                                                      .add(admins.text.trim());
                                                  putSecondaryAdmins(
                                                      service,
                                                      command(deviceName),
                                                      extractSerialNumber(
                                                          widget.device),
                                                      adminDevices);
                                                  Navigator.of(dialogContext)
                                                      .pop();
                                                } else {
                                                  printLog('Pago: $payAdmSec');
                                                  if (payAdmSec) {
                                                    if (adminDevices.length <
                                                        6) {
                                                      adminDevices.add(
                                                          admins.text.trim());
                                                      putSecondaryAdmins(
                                                          service,
                                                          command(deviceName),
                                                          extractSerialNumber(
                                                              widget.device),
                                                          adminDevices);
                                                      Navigator.of(
                                                              dialogContext)
                                                          .pop();
                                                    } else {
                                                      showToast(
                                                          'Alcanzaste el límite máximo');
                                                    }
                                                  } else {
                                                    Navigator.of(dialogContext)
                                                        .pop();
                                                    showAdminText();
                                                  }
                                                }
                                              },
                                              decoration: InputDecoration(
                                                  labelText:
                                                      'Agrega el correo electronico',
                                                  labelStyle: const TextStyle(
                                                    color: Color(0xFFFFFFFF),
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
                                                                  deviceName),
                                                              extractSerialNumber(
                                                                  widget
                                                                      .device),
                                                              adminDevices);
                                                          Navigator.of(
                                                                  dialogContext)
                                                              .pop();
                                                        } else {
                                                          printLog(
                                                              'Pago: $payAdmSec');
                                                          if (payAdmSec) {
                                                            if (adminDevices
                                                                    .length <
                                                                6) {
                                                              adminDevices.add(
                                                                  admins.text
                                                                      .trim());
                                                              putSecondaryAdmins(
                                                                  service,
                                                                  command(
                                                                      deviceName),
                                                                  extractSerialNumber(
                                                                      widget
                                                                          .device),
                                                                  adminDevices);
                                                              Navigator.of(
                                                                      dialogContext)
                                                                  .pop();
                                                            } else {
                                                              showToast(
                                                                  'Alcanzaste el límite máximo');
                                                            }
                                                          } else {
                                                            Navigator.of(
                                                                    dialogContext)
                                                                .pop();
                                                            showAdminText();
                                                          }
                                                        }
                                                      },
                                                      icon: const Icon(
                                                        Icons.add,
                                                        color: Color(0xFFFFFFFF),
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
                                                        color: Color(0xFFFFFFFF),
                                                      ),
                                                    ),
                                                  ),
                                                  trailing: IconButton(
                                                      onPressed: () {
                                                        adminDevices.remove(
                                                            adminDevices[i]);
                                                        putSecondaryAdmins(
                                                            service,
                                                            command(deviceName),
                                                            extractSerialNumber(
                                                                widget.device),
                                                            adminDevices);
                                                        Navigator.of(
                                                                dialogContext)
                                                            .pop();
                                                      },
                                                      icon: const Icon(
                                                          Icons.delete,
                                                          color: Color(0xFFFFFFFF))),
                                                )
                                              ]
                                            ] else ...[
                                              const Text(
                                                'Actualmente no hay ninguna cuenta agregada...',
                                                style: TextStyle(
                                                    color: Color(0xFFFFFFFF),
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
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        ElevatedButton(
                          style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                              Color(0xFFBDBDBD),
                            ),
                            foregroundColor: MaterialStatePropertyAll(
                              Color(0xFFFFFFFF),
                            ),
                          ),
                          onPressed: () {
                            if (activatedAT) {
                              saveATData(
                                service,
                                command(deviceName),
                                extractSerialNumber(deviceName),
                                false,
                                '',
                                distOnValue.round().toString(),
                                distOffValue.round().toString(),
                              );
                              setState(() {});
                            } else {
                              if (!payAT) {
                                showATText();
                              } else {
                                configAT();
                                setState(() {});
                              }
                            }
                          },
                          child: activatedAT
                              ? const Text(
                                  'Desactivar alquiler temporario',
                                  textAlign: TextAlign.center,
                                )
                              : const Text(
                                  'Activar alquiler temporario',
                                  textAlign: TextAlign.center,
                                ),
                        )
                      ]
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              'Versión de Hardware: $hardwareVersion',
              style: const TextStyle(
                  fontSize: 10.0, color: Color(0xFFFFFFFF)),
            ),
            Text(
              'Versión de SoftWare: $softwareVersion',
              style: const TextStyle(
                  fontSize: 10.0, color: Color(0xFFFFFFFF)),
            ),
            const SizedBox(
              height: 0,
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(
                        Color(0xFFBDBDBD)),
                    foregroundColor: MaterialStatePropertyAll(
                        Color(0xFFFFFFFF))),
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
  final String device;
  const SilemaDrawer({super.key, required this.device});

  @override
  SilemaDrawerState createState() => SilemaDrawerState();
}

class SilemaDrawerState extends State<SilemaDrawer> {
  final TextEditingController costController = TextEditingController();
  late bool loading;
  bool buttonPressed = false;
  double result = 0.0;
  DateTime? fechaSeleccionada;
  String tiempo = '';
  String measure = 'KW/h';

  @override
  void initState() {
    super.initState();
    timeData();
    printLog('NightMode status: $nightMode');
  }

  void timeData() async {
    fechaSeleccionada = await cargarFechaGuardada(widget.device);
    List<int> list = await myDevice.varsUuid.read(timeout: 2);
    tiempo = utf8.decode(list).split(':')[3];
    printLog('Tiempo: $tiempo');
  }

  void makeCompute() async {
    if (tiempo != '') {
      if (costController.text.isNotEmpty) {
        setState(() {
          buttonPressed = true;
          loading = true;
        });
        printLog('Estoy haciendo calculaciones misticas');

        result =
            double.parse(tiempo) * 2 * double.parse(costController.text.trim());

        await Future.delayed(const Duration(seconds: 1));

        printLog('Calculaciones terminadas');

        setState(() {
          loading = false;
        });
      } else {
        showToast('Primero debes ingresar un valor kW/h');
      }
    } else {
      showToast(
          'Error al hacer el calculo\n Por favor cierra y vuelve a abrir el menú');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
        backgroundColor: const Color(0xFFFFFFFF),
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
                              color: Color(0xFF000000)),
                          cursorColor: const Color(0xFFBDBDBD),
                          decoration: InputDecoration(
                            labelText: 'Ingresa valor $measure',
                            labelStyle: const TextStyle(
                                color: Color(0xFF000000)),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFFBDBDBD)),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFFBDBDBD)),
                            ),
                          ),
                        )),
                    const SizedBox(height: 10),
                    if (buttonPressed) ...[
                      Visibility(
                          visible: loading,
                          child: const CircularProgressIndicator(
                              color: Color(0xFF000000))),
                      Visibility(
                          visible: !loading,
                          child: Text('\$$result',
                              style: const TextStyle(
                                  fontSize: 50,
                                  color: Color(0xFF000000)))),
                    ],
                    const SizedBox(height: 10),
                    ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color(0xFF484848)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color(0xFFFFFFFF))),
                        onPressed: makeCompute,
                        child: const Text('Hacer calculo')),
                    ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color(0xFF484848)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color(0xFFFFFFFF))),
                        onPressed: () {
                          guardarFecha(widget.device).then(
                              (value) => fechaSeleccionada = DateTime.now());
                          String data = '${command(deviceName)}[10](0)';
                          myDevice.toolsUuid.write(data.codeUnits);
                        },
                        child: const Text('Reiniciar mes')),
                    fechaSeleccionada != null
                        ? Text(
                            'Ultimo reinicio: ${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF000000),
                            ),
                          )
                        : const Text(''),
                    const SizedBox(height: 20),
                    const Text(
                      'Modo actual: ',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Transform.scale(
                      scale: 1.5,
                      child: Switch(
                        activeColor: const Color(0xFF484848),
                        activeTrackColor:
                            const Color(0xFFFFFFFF),
                        inactiveThumbColor:
                            const Color(0xFFFFFFFF),
                        inactiveTrackColor:
                            const Color(0xFF484848),
                        trackOutlineColor: const MaterialStatePropertyAll(
                            Color(0xFF484848)),
                        thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return const Icon(Icons.nights_stay,
                                  color: Colors.white);
                            } else {
                              return const Icon(Icons.wb_sunny,
                                  color: Color(0xFF484848));
                            }
                          },
                        ),
                        value: nightMode,
                        onChanged: (value) {
                          setState(() {
                            nightMode = !nightMode;
                            printLog('Estado: $nightMode');
                            int fun = nightMode ? 1 : 0;
                            String data = '${command(deviceName)}[9]($fun)';
                            printLog(data);
                            myDevice.toolsUuid.write(data.codeUnits);
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 5),
                    if (deviceOwner) ...[
                      ElevatedButton(
                        style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                                Color(0xFF484848)),
                            foregroundColor: MaterialStatePropertyAll(
                                Color(0xFFFFFFFF))),
                        onPressed: () {
                          if (owner != '') {
                            showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  backgroundColor:
                                      const Color(0xFFFFFFFF),
                                  title: const Text(
                                    '¿Dejar de ser administrador del calefactor?',
                                    style: TextStyle(
                                        color: Color(0xFF000000)),
                                  ),
                                  content: const Text(
                                    'Esto hará que otras personas puedan conectarse al dispositivo y modificar sus parámetros',
                                    style: TextStyle(
                                        color: Color(0xFF000000)),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      style: const ButtonStyle(
                                          foregroundColor:
                                              MaterialStatePropertyAll(
                                                  Color(0xFF000000))),
                                      child: const Text('Cancelar'),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                    TextButton(
                                      style: const ButtonStyle(
                                          foregroundColor:
                                              MaterialStatePropertyAll(
                                                  Color(0xFF000000))),
                                      child: const Text('Aceptar'),
                                      onPressed: () {
                                        try {
                                          putOwner(
                                              service,
                                              command(deviceName),
                                              extractSerialNumber(
                                                  widget.device),
                                              '');
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
                                  command(deviceName),
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
                                  Color(0xFF484848)),
                              foregroundColor: MaterialStatePropertyAll(
                                  Color(0xFFFFFFFF))),
                          onPressed: () async {
                            adminDevices = await getSecondaryAdmins(
                                service,
                                command(deviceName),
                                extractSerialNumber(deviceName));
                            showDialog<void>(
                                context: navigatorKey.currentContext!,
                                barrierDismissible: true,
                                builder: (BuildContext dialogContext) {
                                  TextEditingController admins =
                                      TextEditingController();
                                  return AlertDialog(
                                    backgroundColor: const Color(0xFFFFFFFF),
                                    title: const Text(
                                      'Administradores secundarios:',
                                      style: TextStyle(
                                          color: Color(0xFF000000),
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
                                              color:
                                                  Color(0xFF000000),
                                            ),
                                            onSubmitted: (value) {
                                              if (adminDevices.length < 3) {
                                                adminDevices
                                                    .add(admins.text.trim());
                                                putSecondaryAdmins(
                                                    service,
                                                    command(deviceName),
                                                    extractSerialNumber(
                                                        widget.device),
                                                    adminDevices);
                                                Navigator.of(dialogContext)
                                                    .pop();
                                              } else {
                                                printLog('Pago: $payAdmSec');
                                                if (payAdmSec) {
                                                  if (adminDevices.length < 6) {
                                                    adminDevices.add(
                                                        admins.text.trim());
                                                    putSecondaryAdmins(
                                                        service,
                                                        command(deviceName),
                                                        extractSerialNumber(
                                                            widget.device),
                                                        adminDevices);
                                                    Navigator.of(dialogContext)
                                                        .pop();
                                                  } else {
                                                    showToast(
                                                        'Alcanzaste el límite máximo');
                                                  }
                                                } else {
                                                  Navigator.of(dialogContext)
                                                      .pop();
                                                  showAdminText();
                                                }
                                              }
                                            },
                                            decoration: InputDecoration(
                                                labelText:
                                                    'Agrega el correo electronico',
                                                labelStyle: const TextStyle(
                                                  color: Color(0xFF000000),
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
                                                      if (adminDevices.length <
                                                          3) {
                                                        adminDevices.add(
                                                            admins.text.trim());
                                                        putSecondaryAdmins(
                                                            service,
                                                            command(deviceName),
                                                            extractSerialNumber(
                                                                widget.device),
                                                            adminDevices);
                                                        Navigator.of(
                                                                dialogContext)
                                                            .pop();
                                                      } else {
                                                        printLog(
                                                            'Pago: $payAdmSec');
                                                        if (payAdmSec) {
                                                          if (adminDevices
                                                                  .length <
                                                              6) {
                                                            adminDevices.add(
                                                                admins.text
                                                                    .trim());
                                                            putSecondaryAdmins(
                                                                service,
                                                                command(
                                                                    deviceName),
                                                                extractSerialNumber(
                                                                    widget
                                                                        .device),
                                                                adminDevices);
                                                            Navigator.of(
                                                                    dialogContext)
                                                                .pop();
                                                          } else {
                                                            showToast(
                                                                'Alcanzaste el límite máximo');
                                                          }
                                                        } else {
                                                          Navigator.of(
                                                                  dialogContext)
                                                              .pop();
                                                          showAdminText();
                                                        }
                                                      }
                                                    },
                                                    icon: const Icon(
                                                      Icons.add,
                                                      color: Color(0xFF000000),
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
                                                      color: Color(0xFF000000),
                                                    ),
                                                  ),
                                                ),
                                                trailing: IconButton(
                                                    onPressed: () {
                                                      adminDevices.remove(
                                                          adminDevices[i]);
                                                      putSecondaryAdmins(
                                                          service,
                                                          command(deviceName),
                                                          extractSerialNumber(
                                                              widget.device),
                                                          adminDevices);
                                                      Navigator.of(
                                                              dialogContext)
                                                          .pop();
                                                    },
                                                    icon: const Icon(
                                                        Icons.delete,
                                                        color: Color(0xFF000000))),
                                              )
                                            ]
                                          ] else ...[
                                            const Text(
                                              'Actualmente no hay ninguna cuenta agregada...',
                                              style: TextStyle(
                                                  color: Color(0xFF000000),
                                                  fontWeight:
                                                      FontWeight.normal),
                                            )
                                          ]
                                        ],
                                      ),
                                    ),
                                  );
                                });
                          },
                          child: const Text(
                            'Añadir administradores\n secundarios',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        ElevatedButton(
                          style: const ButtonStyle(
                            backgroundColor: MaterialStatePropertyAll(
                              Color(0xFF484848),
                            ),
                            foregroundColor: MaterialStatePropertyAll(
                              Color(0xFFFFFFFF),
                            ),
                          ),
                          onPressed: () {
                            if (activatedAT) {
                              saveATData(
                                service,
                                command(deviceName),
                                extractSerialNumber(deviceName),
                                false,
                                '',
                                distOnValue.round().toString(),
                                distOffValue.round().toString(),
                              );
                              setState(() {});
                            } else {
                              if (!payAT) {
                                showATText();
                              } else {
                                configAT();
                                setState(() {});
                              }
                            }
                          },
                          child: activatedAT
                              ? const Text(
                                  'Desactivar alquiler temporario',
                                  textAlign: TextAlign.center,
                                )
                              : const Text(
                                  'Activar alquiler temporario',
                                  textAlign: TextAlign.center,
                                ),
                        )
                      ]
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Text(
              'Versión de Hardware: $hardwareVersion',
              style: const TextStyle(
                  fontSize: 10.0, color: Color(0xFF484848)),
            ),
            Text(
              'Versión de SoftWare: $softwareVersion',
              style: const TextStyle(
                  fontSize: 10.0, color: Color(0xFF484848)),
            ),
            const SizedBox(
              height: 0,
            ),
            Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                    style: const ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(
                            Color(0xFF484848)),
                        foregroundColor: MaterialStatePropertyAll(
                            Color(0xFFFFFFFF))),
                    onPressed: () {
                      showSilemaContactInfo(context);
                    },
                    child: const Text('CONTACTANOS'))),
          ],
        ));
  }
}
