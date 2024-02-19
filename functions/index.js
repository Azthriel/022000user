const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendDetectorAlert = functions.firestore
    .document("/{collectionId}/info")
    .onUpdate((change, context) => {
      const newValue = change.after.data();
      const oldValue = change.before.data();

      if (context.params.collectionId.startsWith("Detector")) {
        if (newValue.alert === true && oldValue.alert === false) {
          const alertMessage = `Alerta en ${context.params.collectionId}`;

          // Recuperamos los tokens del documento
          const tokens = newValue.Tokens || [];

          // Verificamos si hay tokens para enviar la notificación
          if (tokens.length > 0) {
            // Preparamos la carga útil de la notificación para cada token
            const mes = tokens.map((token) => ({
              token: token,
              notification: {
                title: "¡ALERTA DETECTADA!",
                body: alertMessage,
              },
              android: {
                notification: {
                  sound: "default",
                },
              },
              apns: {
                payload: {
                  aps: {
                    sound: "default",
                  },
                },
              },
              data: {
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                status: "done",
              },
            }));
            return Promise.all(mes.map((message) => admin.messaging()
                .send(message)))
                .then((responses) => {
                  console.log("Successfully sent all messages:", responses);
                  return responses;
                })
                .catch((error) => {
                  console.log("Error sending messages:", error);
                  throw new functions.https.HttpsError("unknown", error, error);
                });
          } else {
            console.log("No tokens available for notification.");
            return null;
          }
        }
      } else {
        console.log("Not a detector");
        return null;
      }
    });
