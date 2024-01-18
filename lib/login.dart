// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'master.dart';

class AskLoginPage extends StatefulWidget {
  const AskLoginPage({super.key});

  @override
  AskLoginPageState createState() => AskLoginPageState();
}

class AskLoginPageState extends State<AskLoginPage> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('Usuario no está logueado');
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        print('Usuario logueado');
        navigatorKey.currentState?.pushReplacementNamed('/scan');
      }
    });
  }

  //!Visual
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color.fromARGB(255, 37, 34, 35),
      body: Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController mailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController newUserController = TextEditingController();
  final TextEditingController registerpasswordController =
      TextEditingController();
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        print('Usuario no está logueado');
        if (alreadyLog) {
          navigatorKey.currentState?.pushReplacementNamed('/login');
          alreadyLog = false;
        }
      } else {
        print('Usuario logueado');
        if (!alreadyLog) {
          navigatorKey.currentState?.pushReplacementNamed('/scan');
          alreadyLog = true;
          wrongPass = 0;
        }
      }
    });
  }

  void registrarUsuario() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 37, 34, 35),
          title: const Text(
            'Registrar nuevo usuario',
            style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
          ),
          content: SingleChildScrollView(
            child: Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  cursorColor: const Color.fromARGB(255, 189, 189, 189),
                  style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255)),
                  controller: newUserController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'Ingrese correo electronico',
                    hintStyle:
                        TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 189, 189, 189)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 189, 189, 189)),
                    ),
                  ),
                  onChanged: (value) {
                    print('New user: $value');
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  cursorColor: const Color.fromARGB(255, 189, 189, 189),
                  style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255)),
                  controller: registerpasswordController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: 'Ingresa contraseña',
                    hintStyle:
                        TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 189, 189, 189)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 189, 189, 189)),
                    ),
                  ),
                  onChanged: (value) {
                    print('New pass: $value');
                  },
                ),
              ],
            )),
          ),
          actions: [
            TextButton(
                style: const ButtonStyle(
                    foregroundColor: MaterialStatePropertyAll(
                        Color.fromARGB(255, 255, 255, 255))),
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.createUserWithEmailAndPassword(
                      email: newUserController.text,
                      password: registerpasswordController.text,
                    );
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'weak-password') {
                      print('La contraseña es demasiado débil.');
                      showToast('La contraseña es demasiado débil.');
                    } else if (e.code == 'email-already-in-use') {
                      print(
                          'Ya existe una cuenta con este correo electrónico.');
                      showToast(
                          'Ya existe una cuenta con este correo electrónico.');
                    }
                  } catch (e) {
                    print(e);
                  }
                },
                child: const Text('Registrar')),
          ],
        );
      },
    );
  }

  void iniciarSesion() async {
    print('Intento iniciar');
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: mailController.text,
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        print('No se encontró ningún usuario con ese correo electrónico.');
        showToast('No se encontró ningún usuario con ese correo electrónico.');
      } else if (e.code == 'wrong-password') {
        print('Contraseña incorrecta para ese usuario.');
        showToast('Contraseña incorrecta para ese usuario.');
        setState(() {
          wrongPass += 1;
        });
      } else if (e.code == 'invalid-credential') {
        print('Credenciales incorrectas.');
        showToast('Credenciales incorrectas.');
        setState(() {
          wrongPass += 1;
        });
      }
      print(e);
    }
  }

  void restablecerContrasena() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    try {
      await auth.sendPasswordResetEmail(email: mailController.text);
      print('Correo de restablecimiento enviado.');
      showToast('Correo de restablecimiento enviado.');
    } on FirebaseAuthException catch (e) {
      showToast('Correo electronico no encontrado.');
      // Manejar los errores aquí (por ejemplo, correo electrónico no encontrado)
      print('Error: ${e.message}');
    }
  }

  void _launchURL() async {
    String url = 'https://biocalden.com.ar/';
    var uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        print('No se pudo abrir la URL: $url');
      }
    } catch (e, s) {
      print('Error url $e Stacktrace: $s');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 37, 34, 35),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
              child: SingleChildScrollView(
                  child: Center(
                      child: Column(
            children: [
              const SizedBox(height: 50),
              IconButton(
                  onPressed: _launchURL,
                  icon: Image.asset('assets/Corte_laser_negro.png')),
              const SizedBox(height: 50),
              SizedBox(
                  width: 300,
                  child: TextField(
                    cursorColor: const Color.fromARGB(255, 189, 189, 189),
                    style: const TextStyle(
                        color: Color.fromARGB(255, 255, 255, 255)),
                    controller: mailController,
                    keyboardType: TextInputType.text,
                    decoration: const InputDecoration(
                      focusColor: Color.fromARGB(255, 189, 189, 189),
                      fillColor: Color.fromARGB(255, 189, 189, 189),
                      hoverColor: Color.fromARGB(255, 189, 189, 189),
                      labelText: 'Correo electronico',
                      labelStyle: TextStyle(color: Colors.white),
                      hintStyle: TextStyle(color: Colors.white),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 189, 189, 189)),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 189, 189, 189)),
                      ),
                    ),
                  )),
              const SizedBox(height: 20),
              SizedBox(
                width: 300,
                child: TextField(
                  cursorColor: const Color.fromARGB(255, 189, 189, 189),
                  obscureText: _obscureText,
                  style: const TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255)),
                  controller: passwordController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: const TextStyle(color: Colors.white),
                    hintStyle: const TextStyle(color: Colors.white),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 189, 189, 189)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide:
                          BorderSide(color: Color.fromARGB(255, 189, 189, 189)),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white, size: 25,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                    style: const ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(
                            Color.fromARGB(255, 189, 189, 189)),
                        foregroundColor: MaterialStatePropertyAll(
                            Color.fromARGB(255, 255, 255, 255))),
                    onPressed: () => iniciarSesion(),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [Icon(Icons.login), Text('Ingresar')],
                      ),
                    )),
              ),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                    style: const ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(
                            Color.fromARGB(255, 189, 189, 189)),
                        foregroundColor: MaterialStatePropertyAll(
                            Color.fromARGB(255, 255, 255, 255))),
                    onPressed: () => registrarUsuario(),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person),
                          Text('Registrar usuario')
                        ],
                      ),
                    )),
              ),
              if (wrongPass >= 3) ...{
                TextButton(
                    style: const ButtonStyle(
                        foregroundColor: MaterialStatePropertyAll(
                            Color.fromARGB(255, 255, 255, 255))),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor:
                                  const Color.fromARGB(255, 37, 34, 35),
                              title: const Text(
                                  'Parece que se te olvido la contraseña...',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  )),
                              content: const Text(
                                  'Se enviara un correo de recuperación \nAl correo que anotaste',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                  )),
                              actions: [
                                TextButton(
                                    style: const ButtonStyle(
                                        foregroundColor:
                                            MaterialStatePropertyAll(
                                                Color.fromARGB(
                                                    255, 255, 255, 255))),
                                    onPressed: () => restablecerContrasena(),
                                    child: const Text('Enviar'))
                              ],
                            );
                          });
                    },
                    child: const Text('Reestablecer contraseña'))
              },
            ],
          )))),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              'Versión 24011702',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
