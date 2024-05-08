import 'package:aws_dynamodb_api/dynamodb-2012-08-10.dart';
import '/master.dart';
import '/stored_data.dart';

Future<void> queryItems(DynamoDB service, String pc, String sn) async {
  try {
    final response = await service.query(
      tableName: 'sime-domotica',
      keyConditionExpression: 'product_code = :pk AND device_id = :sk',
      expressionAttributeValues: {
        ':pk': AttributeValue(s: pc),
        ':sk': AttributeValue(s: sn),
      },
    );
    printLog('Items encontrados');
    if (response.items != null) {
      for (var item in response.items!) {
        for (var key in item.keys) {
          var value = item[key];
          String displayValue = value?.s ??
              value?.n ??
              value?.boolValue.toString() ??
              "Desconocido";
          if (value != null) {
            switch (key) {
              case 'alert':
                globalDATA
                    .putIfAbsent('$pc/$sn', () => {})
                    .addAll({key: value.boolValue ?? false});
                break;
              case 'cstate':
                globalDATA
                    .putIfAbsent('$pc/$sn', () => {})
                    .addAll({key: value.boolValue ?? false});
                break;
              case 'w_status':
                globalDATA
                    .putIfAbsent('$pc/$sn', () => {})
                    .addAll({key: value.boolValue ?? false});
                break;
              case 'f_status':
                globalDATA
                    .putIfAbsent('$pc/$sn', () => {})
                    .addAll({key: value.boolValue ?? false});
                break;
              case 'ppmco':
                globalDATA
                    .putIfAbsent('$pc/$sn', () => {})
                    .addAll({key: int.parse(value.n ?? '0')});
                break;
              case 'ppmch4':
                globalDATA
                    .putIfAbsent('$pc/$sn', () => {})
                    .addAll({key: int.parse(value.n ?? '0')});
                break;
            }
          }
          printLog("$key: $displayValue");
          saveGlobalData(globalDATA);
        }
        printLog("--- Fin de un item ---");
      }
    }
  } catch (e) {
    printLog('Error durante la consulta: $e');
  }
}

