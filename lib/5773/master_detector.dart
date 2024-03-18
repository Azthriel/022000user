import 'package:flutter/material.dart';
import 'package:biocalden_smart_life/master.dart';

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
      backgroundColor: const Color.fromARGB(255, 1, 18, 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          SizedBox(
            height: 50,
            // width: double.infinity,
            child:
                Image.asset('assets/IntelligentGas/IntelligentGasFlyerCL.png'),
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
                showContactInfo(context);
                },
              child: const Text('CONTACTANOS')),
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
