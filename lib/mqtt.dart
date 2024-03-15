import 'dart:convert';
import 'dart:io';
import 'package:biocalden_smart_life/master.dart';
import 'package:biocalden_smart_life/mqttCerts.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

MqttServerClient? mqttAWSFlutterClient;

void setupMqtt() async {
  try {
    printLog('Haciendo setup');
    String deviceId = 'FlutterDevice/${generateRandomNumbers(32)}';
    String broker = 'a3fm8tbrbcxfbf-ats.iot.sa-east-1.amazonaws.com';

    mqttAWSFlutterClient = MqttServerClient(broker, deviceId);

    mqttAWSFlutterClient!.secure = true;
    mqttAWSFlutterClient!.port = 8883; // Puerto estándar para MQTT sobre TLS
    mqttAWSFlutterClient!.securityContext = SecurityContext.defaultContext;

    mqttAWSFlutterClient!.securityContext.setTrustedCertificatesBytes(utf8.encode(caCert));
    mqttAWSFlutterClient!.securityContext.useCertificateChainBytes(utf8.encode(certChain));
    mqttAWSFlutterClient!.securityContext.usePrivateKeyBytes(utf8.encode(privateKey));

    mqttAWSFlutterClient!.logging(on: true);
    mqttAWSFlutterClient!.onDisconnected = mqttonDisconnected;

    // Configuración de las credenciales
    mqttAWSFlutterClient!.setProtocolV311();
    mqttAWSFlutterClient!.keepAlivePeriod = 3;
    try{
      await mqttAWSFlutterClient!.connect();
    }catch (e){
      printLog('Error intentando conectar: $e');
    }
    printLog('Usuario conectado a mqtt');
  } catch (e, s) {
    printLog('Error setup mqtt $e $s');
  }
}

void mqttonDisconnected() {
  printLog('Desconectado de mqtt');
  setupMqtt();
}

void sendMessagemqtt(String topic, String message) {
  final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
  builder.addString(message);

  mqttAWSFlutterClient!
      .publishMessage(topic, MqttQos.exactlyOnce, builder.payload!);
}

void subToTopicMQTT(String topic) {
  mqttAWSFlutterClient!.subscribe(topic, MqttQos.atLeastOnce);
}

void unSubToTopicMQTT(String topic) {
  mqttAWSFlutterClient!.unsubscribe(topic);
}

void listenToTopics() {
  mqttAWSFlutterClient!.updates
      ?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
    final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
    final String topic = c[0].topic;
    var listNames = topic.split('/');
    final List<int> message = recMess.payload.message;
    String keyName = "${listNames[1]}/${listNames[2]}";

    final String messageString = utf8.decode(message);
    try {
      final Map<String, dynamic> messageMap = json.decode(messageString);

      globalDATA.putIfAbsent(keyName, () => {}).addAll(messageMap);

      printLog('Received message: $messageString from topic: $topic');
    } catch (e) {
      printLog('Error decoding message: $e');
    }

  });
}
