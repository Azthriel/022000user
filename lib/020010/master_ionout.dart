import 'dart:convert';
import '../aws/dynamo/dynamo.dart';
import '../aws/dynamo/dynamo_certificates.dart';
import '/master.dart';
import '/aws/mqtt/mqtt.dart';
import '/stored_data.dart';
import 'package:flutter/material.dart';

// VARIABLES //
List<String> tipo = [];
List<String> estado = [];
List<bool> alertIO = [];
List<String> common = [];
List<String> valores = [];

// FUNCIONES //

void controlOut(bool value, int index) {
  String fun = '$index#${value ? '1' : '0'}';
  myDevice.ioUuid.write(fun.codeUnits);

  String fun2 = '${tipo[index] == 'Entrada' ? '1' : '0'}:${value ? '1' : '0'}:${common[index]}';
  deviceSerialNumber = extractSerialNumber(deviceName);
  String topic = 'devices_rx/${command(deviceName)}/$deviceSerialNumber';
  String topic2 = 'devices_tx/${command(deviceName)}/$deviceSerialNumber';
  String message = jsonEncode({'io$index': fun2});
  sendMessagemqtt(topic, message);
  sendMessagemqtt(topic2, message);
  estado[index] = value ? '1' : '0';
  for (int i = 0; i < estado.length; i++) {
    String device =
        '${tipo[i] == 'Salida' ? '0' : '1'}:${estado[i]}:${common[i]}';
    globalDATA['${command(deviceName)}/$deviceSerialNumber']!['io$i'] = device;
  }

  saveGlobalData(globalDATA);
}

Future<void> changeModes(BuildContext context) {
  var parts = utf8.decode(ioValues).split('/');
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xff1f1d20),
        title: const Text(
          'Cambiar modo:',
          style:
              TextStyle(color: Color(0xffa79986), fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < parts.length; i++) ...[
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xff4b2427),
                    borderRadius: BorderRadius.circular(20),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xffa79986), width: 1),
                      right: BorderSide(color: Color(0xffa79986), width: 1),
                      left: BorderSide(color: Color(0xffa79986), width: 1),
                      top: BorderSide(color: Color(0xffa79986), width: 1),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          subNicknamesMap['$deviceName/-/${parts[i]}'] ??
                              '${tipo[i]} ${i + 1}',
                          style: const TextStyle(
                              color: Color(0xffa79986),
                              fontSize: 25,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        tipo[i] == 'Entrada'
                            ? const Text(
                                '    ¿Cambiar de entrada a salida?    ',
                                style: TextStyle(
                                  color: Color(0xffa79986),
                                ),
                              )
                            : const Text(
                                '    ¿Cambiar de salida a entrada?    ',
                                style: TextStyle(
                                  color: Color(0xffa79986),
                                ),
                              ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextButton(
                          onPressed: () {
                            String fun =
                                '${command(deviceName)}[13]($i#${tipo[i] == 'Entrada' ? '0' : '1'})';
                            printLog(fun);
                            myDevice.toolsUuid.write(fun.codeUnits);
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text(
                            'CAMBIAR',
                            style: TextStyle(
                              color: Color(0xffa79986),
                            ),
                          ),
                        ),
                        tipo[i] == 'Entrada'
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    width: 30,
                                  ),
                                  const Text(
                                    'Estado común: ',
                                    style: TextStyle(
                                      color: Color(0xffa79986),
                                    ),
                                  ),
                                  Text(
                                    common[i],
                                    style: const TextStyle(
                                        color: Color(0xffa79986),
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      String data =
                                          '${command(deviceName)}[14]($i#${common[i] == '1' ? '0' : '1'})';
                                      printLog(data);
                                      myDevice.toolsUuid.write(data.codeUnits);
                                      Navigator.of(dialogContext).pop();
                                    },
                                    icon: const Icon(
                                      Icons.change_circle_outlined,
                                      color: Color(0xffa79986),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 5,
                                  ),
                                ],
                              )
                            : const SizedBox(
                                height: 0,
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            style: const ButtonStyle(
              foregroundColor: MaterialStatePropertyAll(
                Color(0xffa79986),
              ),
            ),
            child: const Text('Cerrar'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      );
    },
  );
}

// CLASES //

class DrawerIO extends StatefulWidget {
  const DrawerIO({super.key});
  @override
  DrawerIOState createState() => DrawerIOState();
}

class DrawerIOState extends State<DrawerIO> {
  TextEditingController passController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xff1f1d20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          SizedBox(
            height: 50,
            // width: double.infinity,
            child: Image.asset('assets/Biocalden/BiocaldenBanner.png'),
          ),
          const Spacer(),
          const Text(
            'Ingresar la contraseña del módulo ubicada en el manual',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xffa79986), fontSize: 20),
          ),
          const SizedBox(
            height: 10,
          ),
          SizedBox(
            width: 200,
            child: TextField(
              style: const TextStyle(
                color: Color(0xffa79986),
              ),
              cursorColor: const Color(0xffa79986),
              controller: passController,
              decoration: const InputDecoration(
                hintText: "********",
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
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
              onPressed: () {
                if (passController.text == '53494d45') {
                  changeModes(context);
                } else {
                  showToast('Clave incorrecta');
                }
              },
              style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(
                  Color(0xff4b2427),
                ),
                foregroundColor: MaterialStatePropertyAll(
                  Color(0xffa79986),
                ),
              ),
              child: const Text('Cambiar modo de pines')),
          const SizedBox(
            height: 20,
          ),
          if (deviceOwner) ...[
            ElevatedButton(
              style: const ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(
                  Color(0xff4b2427),
                ),
                foregroundColor: MaterialStatePropertyAll(
                  Color(0xffa79986),
                ),
              ),
              onPressed: () {
                if (owner != '') {
                  showDialog<void>(
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
                              foregroundColor: MaterialStatePropertyAll(
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
                              foregroundColor: MaterialStatePropertyAll(
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
                                printLog('Error al borrar owner $e Trace: $s');
                                showToast('Error al borrar el administrador.');
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
                  backgroundColor: MaterialStatePropertyAll(
                    Color(0xff4b2427),
                  ),
                  foregroundColor: MaterialStatePropertyAll(
                    Color(0xffa79986),
                  ),
                ),
                onPressed: () async {
                  adminDevices = await getSecondaryAdmins(service,
                      command(deviceName), extractSerialNumber(deviceName));
                  showDialog<void>(
                      context: navigatorKey.currentContext!,
                      barrierDismissible: true,
                      builder: (BuildContext dialogContext) {
                        TextEditingController admins = TextEditingController();
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
                                          adminDevices.add(admins.text.trim());
                                          putSecondaryAdmins(
                                              service,
                                              command(deviceName),
                                              extractSerialNumber(deviceName),
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
                                      labelText: 'Agrega el correo electronico',
                                      labelStyle: const TextStyle(
                                        color: Color(0xffa79986),
                                      ),
                                      enabledBorder: const UnderlineInputBorder(
                                        borderSide: BorderSide(),
                                      ),
                                      focusedBorder: const UnderlineInputBorder(
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
                                          adminDevices.remove(adminDevices[i]);
                                          putSecondaryAdmins(
                                              service,
                                              command(deviceName),
                                              extractSerialNumber(deviceName),
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
                backgroundColor: MaterialStatePropertyAll(
                  Color(0xff4b2427),
                ),
                foregroundColor: MaterialStatePropertyAll(
                  Color(0xffa79986),
                ),
              ),
              onPressed: () {
                showContactInfo(context);
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
