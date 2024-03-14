import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:biocalden_smart_life/master.dart';
import 'package:biocalden_smart_life/login/master_login.dart';
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
    asking();
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
  }

  Future<void> signUpUser(String email, String password) async {
    try {
      final userAttributes = {
        AuthUserAttributeKey.email: email,
        // additional attributes as needed
      };
      final result = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: userAttributes,
        ),
      );
      await _handleSignUpResult(result);
    } on AuthException catch (e) {
      printLog('Error signing up user: ${e.message}');
      if (e.message.contains('Password not long enough')) {
        showToast('La contraseña debe tener minimo 8 caracteres');
      } else if (e.message.contains('Password must have numeric characters')) {
        showToast('La contraseña debe contener al menos un número');
      } else {
        showToast('Contraseña invalida, intente otra');
      }
      printLog('You could: ${e.recoverySuggestion}');
    }
  }

  Future<void> _handleSignUpResult(SignUpResult result) async {
    switch (result.nextStep.signUpStep) {
      case AuthSignUpStep.confirmSignUp:
        final codeDeliveryDetails = result.nextStep.codeDeliveryDetails!;
        _handleCodeDelivery(codeDeliveryDetails);
        break;
      case AuthSignUpStep.done:
        printLog('Sign up is complete');
        navigatorKey.currentState!.pushReplacementNamed('/scan');
        break;
    }
  }

  void _handleCodeDelivery(AuthCodeDeliveryDetails codeDeliveryDetails) {
    TextEditingController codeController = TextEditingController();
    printLog(
      'A confirmation code has been sent to ${codeDeliveryDetails.destination}. '
      'Please check your ${codeDeliveryDetails.deliveryMedium.name} for the code.',
    );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 30, 36, 43),
          title: const Text(
            'Ingresa el código de verificación.',
            style: TextStyle(color: Color.fromARGB(255, 178, 181, 174)),
          ),
          content: TextField(
            controller: codeController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Color.fromARGB(255, 178, 181, 174)),
            decoration: const InputDecoration(
              icon: Icon(Icons.mail),
              iconColor: Color.fromARGB(255, 178, 181, 174),
              hintStyle: TextStyle(color: Color.fromARGB(255, 178, 181, 174)),
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: const ButtonStyle(
                  foregroundColor: MaterialStatePropertyAll(
                      Color.fromARGB(255, 178, 181, 174))),
              child: const Text('Verificar código'),
              onPressed: () async {
                try {
                  final result = await Amplify.Auth.confirmSignUp(
                    username: newUserController.text,
                    confirmationCode: codeController.text,
                  );
                  // Check if further confirmations are needed or if
                  // the sign up is complete.
                  await _handleSignUpResult(result);
                } on AuthException catch (e) {
                  safePrint('Error confirming user: ${e.message}');
                  printLog('You could: ${e.recoverySuggestion}');
                  if (e.message.contains('Password not long enough')) {
                    showToast('La contraseña debe tener minimo 8 caracteres');
                  } else if (e.message
                      .contains('Password must have numeric characters')) {
                    showToast('La contraseña debe contener al menos un número');
                  } else if (e.message
                      .contains('Invalid verification code provided')) {
                    showToast('Código de confirmación incorrecto');
                  } else {
                    showToast('Error al cambiar contraseña');
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> resetPassword(String email) async {
    try {
      final result = await Amplify.Auth.resetPassword(
        username: email,
      );
      return _handleResetPasswordResult(result);
    } on AuthException catch (e) {
      safePrint('Error resetting password: ${e.message}');
      showToast('Error intentando reestablecer contraseña');
    }
  }

  void _handleCodeDeliveryNewPass(AuthCodeDeliveryDetails codeDeliveryDetails) {
    TextEditingController npcodeController = TextEditingController();
    TextEditingController npController = TextEditingController();
    printLog(
      'A confirmation code has been sent to ${codeDeliveryDetails.destination}. '
      'Please check your ${codeDeliveryDetails.deliveryMedium.name} for the code.',
    );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 30, 36, 43),
          title: const Text(
            'Ingresa el código de verificación y la nueva contraseña.',
            style: TextStyle(color: Color.fromARGB(255, 178, 181, 174)),
          ),
          content: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: npcodeController,
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(color: Color.fromARGB(255, 178, 181, 174)),
                decoration: const InputDecoration(
                  icon: Icon(Icons.mail),
                  iconColor: Color.fromARGB(255, 178, 181, 174),
                  hintStyle:
                      TextStyle(color: Color.fromARGB(255, 178, 181, 174)),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: npController,
                keyboardType: TextInputType.text,
                style:
                    const TextStyle(color: Color.fromARGB(255, 178, 181, 174)),
                decoration: const InputDecoration(
                  icon: Icon(Icons.key),
                  iconColor: Color.fromARGB(255, 178, 181, 174),
                  hintStyle:
                      TextStyle(color: Color.fromARGB(255, 178, 181, 174)),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: const ButtonStyle(
                  foregroundColor: MaterialStatePropertyAll(
                      Color.fromARGB(255, 178, 181, 174))),
              child: const Text('Cambiar contraseña'),
              onPressed: () async {
                try {
                  final result = await Amplify.Auth.confirmResetPassword(
                      username: mailController.text,
                      confirmationCode: npcodeController.text,
                      newPassword: npController.text);
                  await _handleResetPasswordResult(result);
                } on AuthException catch (e) {
                  safePrint('Error confirming user: ${e.message}');
                  printLog('You could: ${e.recoverySuggestion}');
                  showToast('Código de confirmación incorrecto');
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleResetPasswordResult(ResetPasswordResult result) async {
    switch (result.nextStep.updateStep) {
      case AuthResetPasswordStep.confirmResetPasswordWithCode:
        final codeDeliveryDetails = result.nextStep.codeDeliveryDetails!;
        _handleCodeDeliveryNewPass(codeDeliveryDetails);
      case AuthResetPasswordStep.done:
        safePrint('Successfully reset password');
        navigatorKey.currentState!.pushReplacementNamed('/scan');
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      SignInResult result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      if (result.isSignedIn) {
        printLog('Ingreso exitoso');
        navigatorKey.currentState!.pushReplacementNamed('/scan');
        // Navegar a la página principal de la aplicación
      }
    } on AuthException catch (e) {
      safePrint('Error singin user: ${e.message}');
      printLog('You could: ${e.recoverySuggestion}');
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
      resizeToAvoidBottomInset: false,
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
                                            onPressed: () => resetPassword(
                                                mailController.text),
                                            child: const TextUtil(
                                              text: '¿Olvidaste tu contraseña?',
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
                                            // iniciarSesion();
                                            signIn(mailController.text,
                                                passwordController.text);
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
                                              'assets/Biocalden/Corte_laser_negro.png')),
                                    ),
                                    Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Text(
                                          'Versión $appVersionNumber',
                                          style: const TextStyle(
                                              color: Color.fromARGB(
                                                  255, 156, 157, 152),
                                              fontSize: 12),
                                        )),
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
      body: Column(
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
                          backgroundColor: Theme.of(context).primaryColorLight),
                      onPressed: () {
                        if (registerpasswordController.text ==
                            confirmpasswordController.text) {
                          // registrarUsuario();
                          signUpUser(newUserController.text,
                              registerpasswordController.text);
                        } else {
                          showToast('Las contraseñas deben ser idénticas...');
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
    );
  }
}
