import 'dart:convert';
import 'package:biocalden_smart_life/master.dart';
import 'package:biocalden_smart_life/mqtt/mqtt.dart';
import 'package:biocalden_smart_life/stored_data.dart';
import 'package:flutter/material.dart';

// VARIABLES //
List<String> tipo = [];
List<bool> estado = [];
List<String> valores = [];

// FUNCIONES //

void controlOut(bool value, int index)  {
  String fun = '$index#${value ? '1' : '0'}';
  myDevice.ioUuid.write(fun.codeUnits);

  String fun2 = '$index:${value ? '1' : '0'}';
  deviceSerialNumber = extractSerialNumber(deviceName);
  String topic = 'devices_rx/${productCode[deviceName]}/$deviceSerialNumber';
  String topic2 = 'devices_tx/${productCode[deviceName]}/$deviceSerialNumber';
  String message = jsonEncode({'io': fun2});
  sendMessagemqtt(topic, message);
  estado[index] = value;
  for (int i = 0; i < estado.length; i++) {
    String device =
        '${tipo[i] == 'Salida' ? '0' : '1'}:${estado[i] == true ? '1' : '0'}';
    globalDATA['${productCode[deviceName]}/$deviceSerialNumber']!['io$i'] =
        device;
  }

  saveGlobalData(globalDATA);
  String message2 =
      jsonEncode(globalDATA['${productCode[deviceName]}/$deviceSerialNumber']);
  sendMessagemqtt(topic2, message2);
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
        content: Column(
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
                                '${command(deviceType)}[13]($i#${tipo[i] == 'Entrada' ? '0' : '1'})';
                            printLog(fun);
                            myDevice.toolsUuid.write(fun.codeUnits);
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text(
                            'CAMBIAR',
                            style: TextStyle(
                              color: Color(0xffa79986),
                            ),
                          )),
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
          const Spacer(),
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
