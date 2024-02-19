

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project_022000iot_user/master.dart';
import 'package:project_022000iot_user/login/master_login.dart';
import 'package:url_launcher/url_launcher.dart';

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
        printLog('Usuario no está logueado');
        navigatorKey.currentState?.pushReplacementNamed('/login');
      } else {
        printLog('Usuario logueado');
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
  final TextEditingController confirmpasswordController =
      TextEditingController();
  bool isLogin = false;

  @override
  void initState() {
    super.initState();
    showPrivacyDialogIfNeeded();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        printLog('Usuario no está logueado');
        if (alreadyLog) {
          navigatorKey.currentState?.pushReplacementNamed('/login');
          alreadyLog = false;
        }
      } else {
        printLog('Usuario logueado');
        if (!alreadyLog) {
          navigatorKey.currentState?.pushReplacementNamed('/scan');
          alreadyLog = true;
          wrongPass = 0;
        }
      }
    });
  }

  void registrarUsuario() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: newUserController.text,
        password: registerpasswordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        printLog('La contraseña es demasiado débil.');
        showToast('La contraseña es demasiado débil.');
      } else if (e.code == 'email-already-in-use') {
        printLog('Ya existe una cuenta con este correo electrónico.');
        showToast('Ya existe una cuenta con este correo electrónico.');
      }
    } catch (e) {
      showToast('Error al registrar usuario');
    }
  }

  void iniciarSesion() async {
    printLog('Intento iniciar');
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: mailController.text,
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        printLog('No se encontró ningún usuario con ese correo electrónico.');
        showToast('No se encontró ningún usuario con ese correo electrónico.');
      } else if (e.code == 'wrong-password') {
        printLog('Contraseña incorrecta para ese usuario.');
        showToast('Contraseña incorrecta para ese usuario.');
        setState(() {
          wrongPass += 1;
        });
      } else if (e.code == 'invalid-credential') {
        printLog('Credenciales incorrectas.');
        showToast('Credenciales incorrectas.');
        setState(() {
          wrongPass += 1;
        });
      }
      printLog('$e');
    }
  }

  void restablecerContrasena() async {
    FirebaseAuth auth = FirebaseAuth.instance;

    try {
      await auth.sendPasswordResetEmail(email: mailController.text);
      printLog('Correo de restablecimiento enviado.');
      showToast('Correo de restablecimiento enviado.');
    } on FirebaseAuthException catch (e) {
      showToast('Correo electronico no encontrado.');
      // Manejar los errores aquí (por ejemplo, correo electrónico no encontrado)
      printLog('Error: ${e.message}');
    }
  }

  void _launchURL() async {
    String url = 'https://biocalden.com.ar/';
    var uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        printLog('No se pudo abrir la URL: $url');
      }
    } catch (e, s) {
      printLog('Error url $e Stacktrace: $s');
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    return Scaffold(
        bottomSheet: ClipPath(
          clipper: CustomBottomClip(),
          child: GestureDetector(
            onTap: () {
              setState(() {
                isLogin = true;
              });
            },
            child: AnimatedContainer(
              /// Duration
              duration: const Duration(milliseconds: 400),

              /// Curve
              curve: Curves.decelerate,
              // color: Theme.of(context).primaryColor,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),

              /// changing the height of bottom sheet with animation using animatedContainer
              height: isLogin ? height * 0.8 : height * 0.1,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ///AnimatedContainer to handle animation of size of the container basically height only
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: isLogin ? 100 : 50,
                    alignment: Alignment.bottomCenter,
                    child: const TextUtil(
                      text: "Iniciar sesión",
                      size: 30,
                    ),
                  ),
                  Expanded(
                    /// Using Custom Animated ShowUpAnimated  to handle slide animation of textfield
                    child: isLogin
                        ? ShowUpAnimation(
                            delay: 200,
                            child: Padding(
                                padding: const EdgeInsets.only(top: 50),
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      /// Custom FieldWidget
                                      FieldWidget(
                                        title: "Email",
                                        icon: Icons.mail,
                                        pass: false,
                                        controlador: mailController,
                                      ),
                                      FieldWidget(
                                        title: "Contraseña",
                                        icon: Icons.key,
                                        pass: true,
                                        controlador: passwordController,
                                      ),
                                      SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: TextButton(
                                              onPressed: () =>
                                                  restablecerContrasena(),
                                              child: const TextUtil(
                                                text:
                                                    '¿Olvidaste tu contraseña?',
                                              ))),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Theme.of(context)
                                                  .primaryColorLight,
                                            ),
                                            onPressed: () {
                                              iniciarSesion();
                                            },
                                            child: const TextUtil(
                                              text: 'Ingresar',
                                            )),
                                      ),
                                      const SizedBox(
                                        height: 30,
                                      ),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 200,
                                        child: IconButton(
                                            onPressed: _launchURL,
                                            icon: Image.asset(
                                                'assets/Corte_laser_negro.png')),
                                      )
                                    ],
                                  ),
                                )),
                          )
                        : const SizedBox(),
                  )
                ],
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              ClipPath(
                ///Custom Clipper
                clipper: CustomUpClip(),

                child: Container(
                  padding: const EdgeInsets.all(20),
                  height: height * 0.3,
                  width: double.infinity,
                  decoration:
                      BoxDecoration(color: Theme.of(context).primaryColorLight),
                  alignment: Alignment.center,
                  child: InkWell(

                      /// Using Ink well to change the  isLogin value
                      onTap: () {
                        setState(() {
                          isLogin = false;
                        });
                      },
                      child: const TextUtil(
                        text: "Registrar",
                        size: 30,
                      )),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Custom FieldWidget
                    FieldWidget(
                      title: "Email",
                      icon: Icons.mail,
                      pass: false,
                      controlador: newUserController,
                    ),
                    FieldWidget(
                      title: "Contraseña",
                      icon: Icons.key,
                      pass: true,
                      controlador: registerpasswordController,
                    ),
                    FieldWidget(
                      title: "Confirmar Contraseña",
                      icon: Icons.key,
                      pass: true,
                      controlador: confirmpasswordController,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).primaryColorLight),
                          onPressed: () {
                            if (registerpasswordController.text ==
                                confirmpasswordController.text) {
                              registrarUsuario();
                            } else {
                              showToast(
                                  'Las contraseñas deben ser idénticas...');
                            }
                          },
                          child: const TextUtil(
                            text: 'Registrarse',
                          )),
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
