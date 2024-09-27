import 'package:biocalden_smart_life/stored_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../aws/dynamo/dynamo.dart';
import '../aws/dynamo/dynamo_certificates.dart';
import '../master.dart';

List<String> relayNA = [];
bool isNA = false;

class RelayDrawer extends StatefulWidget {
  const RelayDrawer({Key? key}) : super(key: key);

  @override
  RelayDrawerState createState() => RelayDrawerState();
}

class RelayDrawerState extends State<RelayDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xff1f1d20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            height: 50,
          ),
          SizedBox(
            height: 50,
            // width: double.infinity,
            child: Image.asset('assets/Biocalden/BiocaldenBanner.png'),
          ),
          const Spacer(),
          const SizedBox(
            height: 20,
          ),
          const Text(
            'El relé esta\n configurado como:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: Color(0xffa79986),
            ),
          ),
          Text(
            isNA ? 'NA' : 'NC',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 25,
              color: Color(0xffa79986),
            ),
          ),
          Text(
            isNA ? 'Normal abierto' : 'Normal cerrado',
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xffa79986),
            ),
          ),
          const SizedBox(height: 5),
          ElevatedButton(
            style: const ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Color(0xff4b2427),
              ),
              foregroundColor: WidgetStatePropertyAll(
                Color(0xffa79986),
              ),
            ),
            child: const Text('Cambiar'),
            onPressed: () {
              printLog('Init NA $isNA');
              setState(() {
                isNA ? isNA = false : isNA = true;
                isNA ? relayNA.add(deviceName) : relayNA.remove(deviceName);
              });
              printLog(isNA ? 'Paso a NA' : 'Paso a NC');
              printLog(relayNA);
              saveRelayNA(relayNA);
              myDevice.device.disconnect();
              showToast('Estado cambiado');
            },
          ),
          const SizedBox(height: 20),
          if (deviceOwner) ...[
            ElevatedButton(
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Color(0xff4b2427),
                ),
                foregroundColor: WidgetStatePropertyAll(
                  Color(0xffa79986),
                ),
              ),
              onPressed: () {
                if (owner != '') {
                  android
                      ? showDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext dialogContext) {
                            return AlertDialog(
                              backgroundColor: const Color(0xff1f1d20),
                              title: const Text(
                                '¿Dejar de ser administrador del calefactor?',
                                style: TextStyle(
                                  color: Color(0xffa79986),
                                ),
                              ),
                              content: const Text(
                                'Esto hará que otras personas puedan conectarse al dispositivo y modificar sus parámetros',
                                style: TextStyle(
                                  color: Color(0xffa79986),
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
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                                TextButton(
                                  style: const ButtonStyle(
                                    foregroundColor: WidgetStatePropertyAll(
                                      Color(0xffa79986),
                                    ),
                                  ),
                                  child: const Text('Aceptar'),
                                  onPressed: () {
                                    try {
                                      putOwner(service, command(deviceName),
                                          extractSerialNumber(deviceName), '');
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
                        )
                      : showCupertinoDialog<void>(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext dialogContext) {
                            return CupertinoAlertDialog(
                              title: const Text(
                                '¿Dejar de ser administrador del calefactor?',
                                style: TextStyle(
                                  color: CupertinoColors.label,
                                ),
                              ),
                              content: const Text(
                                'Esto hará que otras personas puedan conectarse al dispositivo y modificar sus parámetros',
                                style: TextStyle(
                                  color: CupertinoColors.label,
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
                                    Navigator.of(dialogContext).pop();
                                  },
                                ),
                                TextButton(
                                  style: const ButtonStyle(
                                    foregroundColor: WidgetStatePropertyAll(
                                      CupertinoColors.label,
                                    ),
                                  ),
                                  child: const Text('Aceptar'),
                                  onPressed: () {
                                    try {
                                      putOwner(service, command(deviceName),
                                          extractSerialNumber(deviceName), '');
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
                    putOwner(service, command(deviceName),
                        extractSerialNumber(deviceName), currentUserEmail);
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
                  backgroundColor: WidgetStatePropertyAll(
                    Color(0xff4b2427),
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    Color(0xffa79986),
                  ),
                ),
                onPressed: () async {
                  adminDevices = await getSecondaryAdmins(service,
                      command(deviceName), extractSerialNumber(deviceName));
                  android
                      ? showDialog<void>(
                          context: navigatorKey.currentContext!,
                          barrierDismissible: true,
                          builder: (BuildContext dialogContext) {
                            TextEditingController admins =
                                TextEditingController();
                            return AlertDialog(
                              backgroundColor: const Color(0xff1f1d20),
                              title: const Text(
                                'Administradores secundarios:',
                                style: TextStyle(
                                    color: Color(0xffa79986),
                                    fontWeight: FontWeight.bold),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: admins,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(
                                        color: Color(0xffa79986),
                                      ),
                                      onSubmitted: (value) {
                                        if (adminDevices.length < 3) {
                                          adminDevices.add(admins.text.trim());
                                          putSecondaryAdmins(
                                              service,
                                              command(deviceName),
                                              extractSerialNumber(deviceName),
                                              adminDevices);
                                          Navigator.of(dialogContext).pop();
                                        } else {
                                          printLog('Pago: $payAdmSec');
                                          if (payAdmSec) {
                                            if (adminDevices.length < 6) {
                                              adminDevices
                                                  .add(admins.text.trim());
                                              putSecondaryAdmins(
                                                  service,
                                                  command(deviceName),
                                                  extractSerialNumber(
                                                      deviceName),
                                                  adminDevices);
                                              Navigator.of(dialogContext).pop();
                                            } else {
                                              showToast(
                                                  'Alcanzaste el límite máximo');
                                            }
                                          } else {
                                            Navigator.of(dialogContext).pop();
                                            showAdminText();
                                          }
                                        }
                                      },
                                      decoration: InputDecoration(
                                          labelText:
                                              'Agrega el correo electronico',
                                          labelStyle: const TextStyle(
                                            color: Color(0xffa79986),
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
                                                if (adminDevices.length < 3) {
                                                  adminDevices
                                                      .add(admins.text.trim());
                                                  putSecondaryAdmins(
                                                      service,
                                                      command(deviceName),
                                                      extractSerialNumber(
                                                          deviceName),
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
                                                              deviceName),
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
                                              icon: const Icon(
                                                Icons.add,
                                                color: Color(0xffa79986),
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
                                            scrollDirection: Axis.horizontal,
                                            child: Text(
                                              adminDevices[i],
                                              style: const TextStyle(
                                                color: Color(0xffa79986),
                                              ),
                                            ),
                                          ),
                                          trailing: IconButton(
                                            onPressed: () {
                                              adminDevices
                                                  .remove(adminDevices[i]);
                                              putSecondaryAdmins(
                                                  service,
                                                  command(deviceName),
                                                  extractSerialNumber(
                                                      deviceName),
                                                  adminDevices);
                                              Navigator.of(dialogContext).pop();
                                            },
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Color(0xffa79986),
                                            ),
                                          ),
                                        )
                                      ]
                                    ] else ...[
                                      const Text(
                                        'Actualmente no hay ninguna cuenta agregada...',
                                        style: TextStyle(
                                            color: Color(0xffa79986),
                                            fontWeight: FontWeight.normal),
                                      )
                                    ]
                                  ],
                                ),
                              ),
                            );
                          })
                      : showCupertinoDialog<void>(
                          context: navigatorKey.currentContext!,
                          barrierDismissible: true,
                          builder: (BuildContext dialogContext) {
                            TextEditingController admins =
                                TextEditingController();
                            return CupertinoAlertDialog(
                              title: const Text(
                                'Administradores secundarios:',
                                style: TextStyle(
                                    color: CupertinoColors.label,
                                    fontWeight: FontWeight.bold),
                              ),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CupertinoTextField(
                                      controller: admins,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(
                                        color: CupertinoColors.label,
                                      ),
                                      onSubmitted: (value) {
                                        if (adminDevices.length < 3) {
                                          adminDevices.add(admins.text.trim());
                                          putSecondaryAdmins(
                                            service,
                                            command(deviceName),
                                            extractSerialNumber(deviceName),
                                            adminDevices,
                                          );
                                          Navigator.of(dialogContext).pop();
                                        } else {
                                          printLog('Pago: $payAdmSec');
                                          if (payAdmSec) {
                                            if (adminDevices.length < 6) {
                                              adminDevices
                                                  .add(admins.text.trim());
                                              putSecondaryAdmins(
                                                service,
                                                command(deviceName),
                                                extractSerialNumber(deviceName),
                                                adminDevices,
                                              );
                                              Navigator.of(dialogContext).pop();
                                            } else {
                                              showToast(
                                                  'Alcanzaste el límite máximo');
                                            }
                                          } else {
                                            Navigator.of(dialogContext).pop();
                                            showCupertinoAdminText();
                                          }
                                        }
                                      },
                                      placeholder:
                                          'Agrega el correo electrónico',
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
                                      suffix: CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          if (adminDevices.length < 3) {
                                            adminDevices
                                                .add(admins.text.trim());
                                            putSecondaryAdmins(
                                              service,
                                              command(deviceName),
                                              extractSerialNumber(deviceName),
                                              adminDevices,
                                            );
                                            Navigator.of(dialogContext).pop();
                                          } else {
                                            printLog('Pago: $payAdmSec');
                                            if (payAdmSec) {
                                              if (adminDevices.length < 6) {
                                                adminDevices
                                                    .add(admins.text.trim());
                                                putSecondaryAdmins(
                                                  service,
                                                  command(deviceName),
                                                  extractSerialNumber(
                                                      deviceName),
                                                  adminDevices,
                                                );
                                                Navigator.of(dialogContext)
                                                    .pop();
                                              } else {
                                                showToast(
                                                    'Alcanzaste el límite máximo');
                                              }
                                            } else {
                                              Navigator.of(dialogContext).pop();
                                              showCupertinoAdminText();
                                            }
                                          }
                                        },
                                        child: const Icon(
                                          CupertinoIcons.add,
                                          color: CupertinoColors.label,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    if (adminDevices.isNotEmpty) ...[
                                      for (int i = 0;
                                          i < adminDevices.length;
                                          i++) ...[
                                        CupertinoListTile(
                                          title: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Text(
                                              adminDevices[i],
                                              style: const TextStyle(
                                                color: CupertinoColors.label,
                                              ),
                                            ),
                                          ),
                                          trailing: IconButton(
                                            onPressed: () {
                                              adminDevices
                                                  .remove(adminDevices[i]);
                                              putSecondaryAdmins(
                                                  service,
                                                  command(deviceName),
                                                  extractSerialNumber(
                                                      deviceName),
                                                  adminDevices);
                                              Navigator.of(dialogContext).pop();
                                            },
                                            icon: const Icon(
                                              CupertinoIcons.delete,
                                              color: CupertinoColors.label,
                                            ),
                                          ),
                                        )
                                      ]
                                    ] else ...[
                                      const Text(
                                        'Actualmente no hay ninguna cuenta agregada...',
                                        style: TextStyle(
                                            color: Color(0xffa79986),
                                            fontWeight: FontWeight.normal),
                                      )
                                    ]
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                },
                child: const Text(
                  'Añadir administradores\n secundarios',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
            ]
          ],
          const Spacer(),
          Text(
            'Versión de Hardware: $hardwareVersion',
            style: const TextStyle(fontSize: 10.0, color: Color(0xffa79986)),
          ),
          Text(
            'Versión de SoftWare: $softwareVersion',
            style: const TextStyle(fontSize: 10.0, color: Color(0xffa79986)),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Color(0xff4b2427),
                ),
                foregroundColor: WidgetStatePropertyAll(
                  Color(0xffa79986),
                ),
              ),
              onPressed: () {
                android
                    ? showContactInfo(context)
                    : showCupertinoContactInfo(context);
              },
              child: const Text('CONTACTANOS'),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
