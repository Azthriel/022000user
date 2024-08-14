import 'package:flutter/material.dart';
import '/master.dart';
import 'package:flutter/cupertino.dart';
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
              height: 120,
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
                showContactInfo(context);
              },
              child: const Text('CONTACTANOS'),
            ),
          ],
        ),
      ),
    );
  }
}

//!-------------------------------------IOS Widget-------------------------------------!\\
class IOSDrawerDetector extends StatefulWidget {
  const IOSDrawerDetector({super.key});
  @override
  IOSDrawerDetectorState createState() => IOSDrawerDetectorState();
}

class IOSDrawerDetectorState extends State<IOSDrawerDetector> {
  static double _sliderValue = 100.0;
  void _updateSliderValue(double localPosition) {
    setState(() {
      _sliderValue = (300 - localPosition) / 3;
      if (_sliderValue < 0) {
        _sliderValue = 0;
      } else if (_sliderValue > 100) {
        _sliderValue = 100;
      }
    });
  }

  void _sendValueToBle(int value) async {
    try {
      final data = [value];
      myDevice.lightUuid.write(data, withoutResponse: true);
    } catch (e, stackTrace) {
      printLog('Error al mandar el valor del brillo $e $stackTrace');
      // handleManualError(e, stackTrace);
    }
  }

  Widget _buildCustomSlider() {
    return Container(
      width: 60,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: CupertinoColors.systemFill,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (TapDownDetails details) {
          _updateSliderValue(details.localPosition.dy);
          _sendValueToBle(_sliderValue.round());
        },
        onVerticalDragUpdate: (DragUpdateDetails details) {
          _updateSliderValue(details.localPosition.dy);
        },
        onVerticalDragEnd: (DragEndDetails details) {
          _updateSliderValue(details.localPosition.dy);
          _sendValueToBle(_sliderValue.round());
        },
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Column(
              children: [
                Expanded(
                  flex: 100 - _sliderValue.toInt(),
                  child: Container(),
                ),
                Expanded(
                  flex: _sliderValue.toInt(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DA3A9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Icon(
                _sliderValue > 50
                    ? CupertinoIcons.sun_max_fill
                    : CupertinoIcons.moon_fill,
                color: CupertinoColors.white,
                size: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFF01121C),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              SizedBox(
                height: 50,
                child: Image.asset(
                    'assets/IntelligentGas/IntelligentGasFlyerCL.png'),
              ),
              Icon(
                CupertinoIcons.lightbulb_fill,
                size: 150,
                color: CupertinoColors.systemYellow
                    .withOpacity(_sliderValue / 100),
              ),
              const SizedBox(
                height: 30,
              ),
              _buildCustomSlider(),
              const SizedBox(
                height: 30,
              ),
              DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 20.0,
                  color: CupertinoColors.white,
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  'Nivel del brillo: ${_sliderValue.toStringAsFixed(0)}',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 15.0,
                  color: CupertinoColors.white,
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  'Versión de Hardware: $hardwareVersion',
                  textAlign: TextAlign.center,
                ),
              ),
              DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 15.0,
                  color: CupertinoColors.white,
                  backgroundColor: Colors.transparent,
                ),
                child: Text(
                  'Versión de SoftWare: $softwareVersion',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              CupertinoButton(
                color: const Color(0xFF1DA3A9),
                borderRadius: BorderRadius.circular(18.0),
                onPressed: () {
                  showCupertinoContactInfo(context);
                },
                child: const Text('CONTACTANOS',
                    style: TextStyle(
                        fontSize: 15.0, color: CupertinoColors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
