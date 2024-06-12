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

    if (response.items != null) {
      printLog('Items encontrados');
      printLog(response.items);
      for (var item in response.items!) {
        printLog("-----------Inicio de un item-----------");
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
        printLog("-----------Fin de un item-----------");
      }
    } else {
      printLog('Dispositivo no encontrado');
    }
  } catch (e) {
    printLog('Error durante la consulta: $e');
  }
}

Future<void> putTokens(
    DynamoDB service, String pc, String sn, List<String> data) async {
  try {
    final response = await service.updateItem(tableName: 'tokens', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'tokens': AttributeValueUpdate(value: AttributeValue(ss: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<List<String>> getTokens(DynamoDB service, String pc, String sn) async {
  try {
    final response = await service.getItem(
      tableName: 'tokens',
      key: {
        'product_code': AttributeValue(s: pc),
        'device_id': AttributeValue(s: sn),
      },
    );
    if (response.item != null) {
      // Convertir AttributeValue a String
      var item = response.item!;
      List<String> tokens = item['tokens']?.ss ?? [];

      for (var token in tokens) {
        printLog(token);
      }

      printLog('Se encontro el siguiente item: $tokens');

      return tokens;
    } else {
      printLog('Item no encontrado.');
      return [];
    }
  } catch (e) {
    printLog('Error al obtener el item: $e');
    return [];
  }
}

Future<void> putIOTokens(DynamoDB service, String pc, String sn,
    List<String> data, int index) async {
  if (data.isEmpty) {
    data.add('');
  }
  try {
    final response = await service.updateItem(tableName: 'tokens', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'tokens$index': AttributeValueUpdate(value: AttributeValue(ss: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<List<String>> getIOTokens(
    DynamoDB service, String pc, String sn, int index) async {
  try {
    final response = await service.getItem(
      tableName: 'tokens',
      key: {
        'product_code': AttributeValue(s: pc),
        'device_id': AttributeValue(s: sn),
      },
    );
    if (response.item != null) {
      // Convertir AttributeValue a String
      var item = response.item!;
      List<String> tokens = item['tokens$index']?.ss ?? [];

      for (var token in tokens) {
        printLog(token);
      }

      printLog('Se encontro el siguiente item: $tokens');

      return tokens;
    } else {
      printLog('Item no encontrado.');
      return [];
    }
  } catch (e) {
    printLog('Error al obtener el item: $e');
    return [];
  }
}

Future<void> putOwner(
    DynamoDB service, String pc, String sn, String data) async {
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'owner': AttributeValueUpdate(value: AttributeValue(s: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<String> getOwner(DynamoDB service, String pc, String sn) async {
  try {
    final response = await service.getItem(
      tableName: 'sime-domotica',
      key: {
        'product_code': AttributeValue(s: pc),
        'device_id': AttributeValue(s: sn),
      },
    );
    if (response.item != null) {
      var item = response.item!;
      String owner = item['owner']?.s ?? '';
      printLog('Owner encontrado');
      return owner;
    } else {
      printLog('Item no encontrado.');
      return '';
    }
  } catch (e) {
    printLog('Error al obtener el item: $e');
    return '';
  }
}

Future<void> putSecondaryAdmins(
    DynamoDB service, String pc, String sn, List<String> data) async {
  if (data.isEmpty) {
    data.add('');
  }
  try {
    final response = await service.updateItem(tableName: 'sime-domotica', key: {
      'product_code': AttributeValue(s: pc),
      'device_id': AttributeValue(s: sn),
    }, attributeUpdates: {
      'secondary_admin': AttributeValueUpdate(value: AttributeValue(ss: data)),
    });

    printLog('Item escrito perfectamente $response');
  } catch (e) {
    printLog('Error inserting item: $e');
  }
}

Future<List<String>> getSecondaryAdmins(
    DynamoDB service, String pc, String sn) async {
  try {
    final response = await service.getItem(
      tableName: 'sime-domotica',
      key: {
        'product_code': AttributeValue(s: pc),
        'device_id': AttributeValue(s: sn),
      },
    );
    if (response.item != null) {
      // Convertir AttributeValue a String
      var item = response.item!;
      List<String> secAdm = item['secondary_admin']?.ss ?? [];

      printLog('Se encontro el siguiente item: $secAdm');

      return secAdm;
    } else {
      printLog('Item no encontrado.');
      return [];
    }
  } catch (e) {
    printLog('Error al obtener el item: $e');
    return [];
  }
}
