import 'dart:convert';

import 'package:biocalden_smart_life/master.dart';
import 'package:flutter/material.dart';

// VARIABLES //
bool configPass = false;
List<String> tipo = [];
List<bool> estado = [];
List<String> valores = [];
// FUNCIONES //

Future<void> passText(BuildContext context) {
  TextEditingController passController = TextEditingController();

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xff1f1d20),
        title: const Text(
          'Ingresar contraseña del módulo ubicada en el manual',
          style: TextStyle(
            color: Color(0xffa79986),
          ),
        ),
        content: TextField(
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
            child: const Text('Probar'),
            onPressed: () {
              if (passController.text == '53494d45') {
                configPass = true;
                Navigator.of(dialogContext).pop();
              } else {
                showToast('Contraseña incorrecta');
              }
            },
          ),
        ],
      );
    },
  );
}

void controlOut(bool value, int index) async {
  String fun = '$index#${value ? '1' : '0'}';
  await myDevice.ioUuid.write(fun.codeUnits);
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
          'Ingresar contraseña del módulo ubicada en el manual',
          style: TextStyle(
            color: Color(0xffa79986),
          ),
        ),
        content: ListView.builder(
            itemCount: parts.length,
            itemBuilder: (context, int index) {
              bool entrada = tipo[index] == 'Entrada';
              return ListTile(
                title: Text(
                  subNicknamesMap['$deviceName/-/${parts[index]}'] ??
                      '${tipo[index]} ${index + 1}',
                ),
                subtitle: entrada
                    ? const Text('¿Cambiar de entrada a salida?')
                    : const Text('¿Cambiar de salida a entrada?'),
                leading: TextButton(
                    onPressed: () {
                      String fun =
                          '${command(deviceType)}[13]($index#${entrada ? '0' : '1'})';
                      printLog(fun);
                      myDevice.toolsUuid.write(fun.codeUnits);
                    },
                    child: const Text('CAMBIAR')),
              );
            }),
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
            child: const Text('Probar'),
            onPressed: () {},
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
          ElevatedButton(
              onPressed: () {
                passText(context).then((value) {
                  printLog(configPass);
                });
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
