import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_022000iot_user/master.dart';
// VARIABLES //

List<int> workValues = [];
int lastCO = 0;
int lastCH4 = 0;
int ppmCO = 0;
int ppmCH4 = 0;
bool alert = false;

// FUNCIONES //

void compareValues(int ppmCO, int ppmCH4) {
  if (ppmCO != lastCO) {
    lastCO = ppmCO;
    sendValuePPMCO(ppmCO);
  }
  if (ppmCH4 != lastCH4) {
    lastCH4 = ppmCH4;
    sendValuePPMCH4(ppmCH4);
  }
}

void sendValuePPMCO(int ppmCO) async {
  DocumentReference documentRef =
      FirebaseFirestore.instance.collection(deviceName).doc('info');
  await documentRef.set({'ppmCO': ppmCO}, SetOptions(merge: true));
}

void sendValuePPMCH4(int ppmCH4) async {
  DocumentReference documentRef =
      FirebaseFirestore.instance.collection(deviceName).doc('info');
  await documentRef.set({'ppmCH4': ppmCH4}, SetOptions(merge: true));
}

// CLASES //