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
          // Recuperamos los tokens del documento
          let tokens = newValue.Tokens || [];

          tokens = tokens.map((token) => {
            const parts = token.split("/-/");
            const alertMessage = `Alerta en ${parts[1]}`;
            return {
              token: parts[0],
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
            };
          });

          // Verificamos si hay tokens para enviar la notificación
          if (tokens.length > 0) {
            // Enviamos la notificación para cada token
            return Promise.all(tokens.map((message) => admin.messaging()
                .send(message)))
                .then((responses) => {
                  console.log("Successfully sent all messages:", responses);
                  return responses;
                })
                .catch((error) => {
                  console.log("Error sending messages:", error);
                  throw new functions.https.HttpsError("unkwn", error.message);
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
