import 'package:flutter/material.dart';
import '/master.dart';
// VARIABLES //

List<int> workValues = [];
int lastCO = 0;
int lastCH4 = 0;
int ppmCO = 0;
int ppmCH4 = 0;
int picoMaxppmCO = 0;
int picoMaxppmCH4 = 0;
int promedioppmCO = 0;
int promedioppmCH4 = 0;
int daysToExpire = 0;
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF01121C),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            SizedBox(
              height: 50,
              // width: double.infinity,
              child: Image.asset(
                  'assets/IntelligentGas/IntelligentGasFlyerCL.png'),
            ),
            Icon(
              Icons.lightbulb,
              size: 200,
              color: Colors.yellow.withOpacity(_sliderValue / 100),
            ),
            const SizedBox(
              height: 30,
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                  valueIndicatorColor: const Color(0xFFFFFFFF),
                  activeTrackColor: const Color(0xFF1DA3A9),
                  inactiveTrackColor: const Color(0xFFFFFFFF),
                  trackHeight: 48.0,
                  thumbColor: const Color(0xFF1DA3A9),
                  thumbShape: IconThumbSlider(
                      iconData: _sliderValue > 50
                          ? Icons.light_mode
                          : Icons.nightlight,
                      thumbRadius: 25)),
              child: Slider(
                value: _sliderValue,
                min: 0.0,
                max: 100.0,
                onChanged: (double value) {
                  setState(() {
                    _sliderValue = value;
                  });
                },
                onChangeEnd: (value) {
                  setState(() {
                    _sliderValue = value;
                  });
                  _sendValueToBle(_sliderValue.toInt());
                },
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Text(
              'Valor del brillo: ${_sliderValue.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 20.0, color: Colors.white),
            ),
            const SizedBox(
              height: 80,
            ),
            Text(
              'Versión de Hardware: $hardwareVersion',
              style: const TextStyle(fontSize: 10.0, color: Colors.white),
            ),
            Text(
              'Versión de SoftWare: $softwareVersion',
              style: const TextStyle(fontSize: 10.0, color: Colors.white),
            ),
            const SizedBox(
              height: 10,
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    WidgetStateProperty.all<Color>(const Color(0xFF1DA3A9)),
                foregroundColor:
                    WidgetStateProperty.all<Color>(const Color(0xFFFFFFFF)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
              ),
              onPressed: () {
                android
                    ? showContactInfo(context)
                    : showCupertinoContactInfo(context);
              },
              child: const Text('CONTACTANOS'),
            ),
          ],
        ),
      ),
    );
  }
}
