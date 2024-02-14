import 'package:flutter/material.dart';
import 'package:project_022000iot_user/5773/master_detector.dart';
import 'package:project_022000iot_user/master.dart';

class DetectorPage extends StatefulWidget {
  const DetectorPage({super.key});
  @override
  DetectorPageState createState() => DetectorPageState();
}

class DetectorPageState extends State<DetectorPage> {
  @override
  void initState() {
    super.initState();
    _subscribeToWorkCharacteristic();
  }

  void _subscribeToWorkCharacteristic() async {
    await myDevice.workUuid.setNotifyValue(true);

    final workSub =
        myDevice.workUuid.onValueReceived.listen((List<int> status) {
      setState(() {
        ppmCO = status[5] + status[6] << 8;
        ppmCH4 = status[7] + status[8] << 8;
      });
      compareValues(ppmCO, ppmCH4);
    });

    myDevice.device.cancelWhenDisconnected(workSub);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
