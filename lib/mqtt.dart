import 'dart:convert';
import 'dart:io';
import 'package:biocalden_smart_life/master.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

String privateKey = '''-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAr1bcb797zj09EQ8k5g1P1Piu7h5CCqqddjvgaVTa4eXZrRyA
BFAfsun1KkJKpOZLXVT+khKs1UbzJNtgDJnPMgOT8ENWvLSAyXwoa596GvV19G2+
5QCrsAN0VF9qPeMQJLzUVCO9Wa4lOtF6bD8dATDTSqhzzAm/Y/W4ZELrnEqslkRj
LLmxiamSmL1YD4AT5QMsrheCmH+ZBLePEn83F6uhhucxw0BFIYmRBVmFIz65/D5Q
LTB/SCKJi5YiagFXHm5yOD/xHTGBRd7xshCvSt3x12IhW7NEeBfXgTX0h8NfzAgi
rQSFfeBPR6yZvf/XTs6bqEvJXrYvlO4eEoruCQIDAQABAoIBAGspVTRe/VXBC69/
Z/fKLv5kttUFXSuTtwTp92+o0tW5Wt54Sq1YIueAIbygI2rA7VKvfZ7dFxCKelQO
V5eb8YwJr8LqBPrz/rolzbZpE4Gif2LSKBdh34yFr/VZE1+bhORPHB4IcdN7oXlf
SckakamGo7w/U/ZiBr0bEoUEeWddITxzloGyK5mQCuL1B/ohHEFC7gir/K6P+WCk
W5Ml4zDayR44goA+PHnpWomkwel4nn2fWOOM+ovT+QSO64QPNf8qxWaIyyMZw0gK
vtQT4a+g35ihkjSs/eU7XDkb09jvLjAnp0oG53Ma1CW9Ctbkzsstw7cSVSGVrcCQ
oYzstwECgYEA1kmuH91WOWi+MxBGin3IWAYaSAO7UuEKNly0XSompFVkYNN00b0S
/Dgvs9TqCCOXG3y46KjfSoZ2oxKyTYp/rqjKvHuCS/lC71FBnEh6kzTsmjJ2ysjZ
2PUkCW3uiihi4ErT56EdohVR3snSYlV+M2EUZP8u38GE+W6rvWp7IHECgYEA0XhP
vAJkzZvG0w6elvd5Y9VnkyB8PKLwI3ES7dr90EpP+8hjJW+d9cjOqDYNN6abVc0W
fDgbesZ2Mc9xO9g3NgNh5pWmYfExAyxsgsKm6GH1SM5+fN6AsPi2NVtcS+F/qwI1
XzK4zA3mP7WDfp8NeQeia0tqRb1jBG+Q3OUScxkCgYAwhc6f+IalyUoIVg8jHQhY
pkkdNXsdcUfWt3dAAWNuosdwBXHWbHH4GuDyX6v+29BDsSJNzK+DOJ90na8yT8JJ
0n7V30HJ4k990XCB6weWfc11vSeZE5IAxsG6QOJa9notP8RsFteW9CztvdWd3q4N
BFaR6Ba9JBzwPlc1NP9cgQKBgFGbCZU5aYQguCjpfSdbalNWhG9xLHWDFQL5vmIj
+tX23Yo920JuZZ+nh7tIs4WGxuV6bNQgF7SRNOLa6kZiScAlOTLYAmYNzQZrfCrF
IrlN0H141RZYqNJJUtMesKpvQ4mf5qMb45q7n4QadwwRcvI/4yrhypk42yaTQGCO
bc2hAoGAZbDfyJw3YJ4aajfiCpHk5UdasbWijv1+9FX9mKq6HLT6FvkbTi4miu/A
EY+l/61/WohxSqBUUaUG5Aw13Y753g2BAXH+4MxrJ3Oo3xJj7eoBJVTekn9l2Aa9
RhW/c+ATbiUJUIbOUlaCj2hkU+rswi5yiovSG+bXyJqUEZEluiQ=
-----END RSA PRIVATE KEY-----''';

String certChain = '''-----BEGIN CERTIFICATE-----
MIIDWTCCAkGgAwIBAgIUeYSLiqPFlhhgx6Lv0hcSt0DXQDMwDQYJKoZIhvcNAQEL
BQAwTTFLMEkGA1UECwxCQW1hem9uIFdlYiBTZXJ2aWNlcyBPPUFtYXpvbi5jb20g
SW5jLiBMPVNlYXR0bGUgU1Q9V2FzaGluZ3RvbiBDPVVTMB4XDTI0MDMxNDIwNDAy
MVoXDTQ5MTIzMTIzNTk1OVowHjEcMBoGA1UEAwwTQVdTIElvVCBDZXJ0aWZpY2F0
ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAK9W3G+/e849PREPJOYN
T9T4ru4eQgqqnXY74GlU2uHl2a0cgARQH7Lp9SpCSqTmS11U/pISrNVG8yTbYAyZ
zzIDk/BDVry0gMl8KGufehr1dfRtvuUAq7ADdFRfaj3jECS81FQjvVmuJTrRemw/
HQEw00qoc8wJv2P1uGRC65xKrJZEYyy5sYmpkpi9WA+AE+UDLK4Xgph/mQS3jxJ/
NxeroYbnMcNARSGJkQVZhSM+ufw+UC0wf0giiYuWImoBVx5ucjg/8R0xgUXe8bIQ
r0rd8ddiIVuzRHgX14E19IfDX8wIIq0EhX3gT0esmb3/107Om6hLyV62L5TuHhKK
7gkCAwEAAaNgMF4wHwYDVR0jBBgwFoAUYb9wKOIq3wWDweUPfAwZF5rOcTUwHQYD
VR0OBBYEFBxYi+KMQ6gdgWAly5A7VY0xf0xdMAwGA1UdEwEB/wQCMAAwDgYDVR0P
AQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4IBAQAW5XAGIRC9EJElrV6d9fquspvx
U6Ux8572C+oVyGfytNa4Alv/TRGclWcmIu3V9mIY5RE/xMd28GixzsH4GfnzioMZ
0GFICi5DddG9eh6HbZA7Y0LFqe3dSzbvEs5vuiRLDT/iKjDrcrZnw8DCV+EkiQ7N
IrL/c/obCc5t7ifVYk3LlWvVNWeXyWwVrxXULBDKRmZG3rmjcjW51pJr+kCQGLRx
TOFEeEoLuByjlycjWv8dRLBh8cUI0lYJwj7lQeku0VKBjnGG5wvGUGrUW8rkqVZg
hX4Q3x4t64p3gJlZF7gv1OvtpeSAHNWnKS/HHaqABoeTRYESdbLQkTOp9qcZ
-----END CERTIFICATE-----''';

String caCert = '''-----BEGIN CERTIFICATE-----
MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF
ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6
b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL
MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv
b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj
ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM
9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw
IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6
VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L
93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm
jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC
AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA
A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI
U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs
N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv
o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU
5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy
rqXRfboQnoZsG4q5WTP468SQvvG5
-----END CERTIFICATE-----''';

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

    printLog('Received message: ${message.toString()} from topic: $topic');
  });
}
