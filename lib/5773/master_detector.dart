import 'package:flutter/material.dart';
import 'package:project_022000iot_user/master.dart';
import 'package:url_launcher/url_launcher.dart';

// VARIABLES //

List<int> workValues = [];
int lastCO = 0;
int lastCH4 = 0;
int ppmCO = 0;
int ppmCH4 = 0;
bool alert = false;

// FUNCIONES //

// CLASES //

class DrawerDetector extends StatefulWidget {
  const DrawerDetector({super.key});
  @override
  DrawerDetectorState createState() => DrawerDetectorState();
}

class DrawerDetectorState extends State<DrawerDetector> {
  static double _sliderValue = 100.0;

  void _sendValueToBle(int value) async {
    try {
      final data = [value];
      myDevice.lightUuid.write(data, withoutResponse: true);
    } catch (e, stackTrace) {
      printLog('Error al mandar el valor del brillo $e $stackTrace');
      // handleManualError(e, stackTrace);
    }
  }

  Future<void> _sendWhatsAppMessage(String phoneNumber, String message) async {
    var whatsappUrl =
        "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeFull(message)}";
    Uri uri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      showToast('No se pudo abrir WhatsApp');
    }
  }

  void _launchEmail(String mail, String asunto, String cuerpo) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: mail,
      query: encodeQueryParameters(
          <String, String>{'subject': asunto, 'body': cuerpo}),
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      showToast('No se pudo abrir el correo electrónico');
    }
  }

  String encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 1, 18, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 50,
            // width: double.infinity,
            child: Image.asset('assets/IntelligentGasFlyerCL.png'),
          ),
          Icon(
            Icons.lightbulb,
            size: 200,
            color: Colors.yellow.withOpacity(_sliderValue / 100),
          ),
          const SizedBox(
            height: 30,
          ),
          RotatedBox(
            quarterTurns: 3,
            child: _buildCustomSlider(),
          ),
          const SizedBox(
            height: 30,
          ),
          Text(
            'Valor del brillo: ${_sliderValue.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 20.0, color: Colors.white),
          ),
          const SizedBox(
            height: 30,
          ),
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    const Color.fromARGB(255, 29, 163, 169)),
                foregroundColor: MaterialStateProperty.all<Color>(
                    const Color.fromARGB(255, 255, 255, 255)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
              ),
              onPressed: () {
                showDialog(
                    barrierDismissible: true,
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                          backgroundColor:
                              const Color.fromARGB(255, 230, 254, 255),
                          content: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Contacto comercial:',
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                        onPressed: () => _sendWhatsAppMessage(
                                            '5491162234181',
                                            '¡Hola! Tengo una duda comercial sobre los productos Biocalden smart: \n'),
                                        icon: const Icon(
                                          Icons.phone,
                                          color:
                                              Color.fromARGB(255, 29, 163, 169),
                                          size: 20,
                                        )),
                                    // const SizedBox(width: 5),
                                    const Text('+54 9 11 6223-4181',
                                        style: TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0),
                                            fontSize: 20))
                                  ],
                                ),
                                SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: () => _launchEmail(
                                              'ceat@ibsanitarios.com.ar',
                                              'Consulta comercial acerca de la linea Biocalden smart',
                                              '¡Hola! mi equipo es el $deviceName y tengo la siguiente duda:\n'),
                                          icon: const Icon(
                                            Icons.mail,
                                            color: Color.fromARGB(
                                                255, 29, 163, 169),
                                            size: 20,
                                          ),
                                        ),
                                        // const SizedBox(width: 5),
                                        const Text('ceat@ibsanitarios.com.ar',
                                            style: TextStyle(
                                                color: Color.fromARGB(255, 0, 0, 0),
                                                fontSize: 20))
                                      ],
                                    )),
                                const SizedBox(height: 20),
                                const Text('Consulta técnica:',
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        onPressed: () => _launchEmail(
                                            'pablo@intelligentgas.com.ar',
                                            'Consulta ref. $deviceName',
                                            '¡Hola! Tengo una consulta referida al área de ingenieria sobre mi equipo.\n Información del mismo:\nModelo: $deviceType\nVersión de software: $softwareVersion \nVersión de hardware: $hardwareVersion \nMi duda es la siguiente:\n'),
                                        icon: const Icon(
                                          Icons.mail,
                                          color:
                                              Color.fromARGB(255, 29, 163, 169),
                                          size: 20,
                                        ),
                                      ),
                                      // const SizedBox(width: 5),
                                      const Text(
                                        'pablo@intelligentgas.com.ar',
                                        style: TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0), fontSize: 20),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text('Customer service:',
                                    style: TextStyle(
                                        color: Color.fromARGB(255, 0, 0, 0),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                        onPressed: () => _sendWhatsAppMessage(
                                            '5491162232619',
                                            '¡Hola! Te hablo por una duda sobre mi equipo $deviceName: \n'),
                                        icon: const Icon(
                                          Icons.phone,
                                          color:
                                              Color.fromARGB(255, 29, 163, 169),
                                          size: 20,
                                        )),
                                    // const SizedBox(width: 5),
                                    const Text('+54 9 11 6223-2619',
                                        style: TextStyle(
                                            color: Color.fromARGB(255, 0, 0, 0), fontSize: 20))
                                  ],
                                ),
                                SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          onPressed: () => _launchEmail(
                                              'service@calefactorescalden.com.ar',
                                              'Consulta 022000eIOT',
                                              'Tengo una consulta referida a mi equipo $deviceName: \n'),
                                          icon: const Icon(
                                            Icons.mail,
                                            color: Color.fromARGB(
                                                255, 29, 163, 169),
                                            size: 20,
                                          ),
                                        ),
                                        // const SizedBox(width: 5),
                                        const Text(
                                          'service@calefactorescalden.com.ar',
                                          style: TextStyle(
                                              color: Color.fromARGB(255, 0, 0, 0),
                                              fontSize: 20),
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      ],
                                    )),
                              ]));
                    });
              },
              child: const Text('CONTACTANOS'))
        ],
      ),
    );
  }

  Widget _buildCustomSlider() {
    return SizedBox(
      width: 300,
      height: 30,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          activeTrackColor: const Color.fromARGB(255, 29, 163, 169),
          inactiveTrackColor: const Color.fromARGB(255, 255, 255, 255),
          trackHeight: 30.0,
          thumbColor: const Color.fromARGB(255, 29, 163, 169),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0.0),
          overlayColor: const Color.fromARGB(255, 29, 163, 169).withAlpha(32),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 0.0),
        ),
        child: Slider(
          value: _sliderValue,
          min: 0.0,
          max: 100.0,
          onChanged: (double value) {
            setState(() {
              _sliderValue = value;
            });
          },
          onChangeEnd: (double value) {
            setState(() {
              _sliderValue = value;
            });
            _sendValueToBle(_sliderValue.toInt());
          },
        ),
      ),
    );
  }
}
