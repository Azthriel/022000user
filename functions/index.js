const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendNotification = functions.https.onCall((data, context) => {
  // Asegúrate de que la petición contenga product_code y serialNumber
  const productCode = data.product_code;
  const serialNumber = data.serialNumber;

  if (!productCode || !serialNumber) {
    throw new functions.https.HttpsError("invalid-argument");
  }

  const documentPath = `${productCode}/${serialNumber}`;

  // Referencia al documento de Firestore
  const docRef = admin.firestore().doc(documentPath);

  return docRef.get().then((doc) => {
    if (!doc.exists) {
      throw new functions.https.HttpsError("not-found");
    }

    // Recuperamos los tokens del documento
    let tokens = doc.data().Tokens || [];

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
  });
});

exports.saveToken = functions.https.onCall((data, context) => {
  const productCode = data.product_code;
  const serialNumber = data.serialNumber;
  const token = data.token;

  if (!productCode || !serialNumber || !token) {
    throw new functions.https.HttpsError("invalid-argument");
  }

  const documentPath = `${productCode}/${serialNumber}`;

  return admin.firestore().doc(documentPath).set({
    Tokens: admin.firestore.FieldValue.arrayUnion(token),
  }, {merge: true})
      .then(() => {
        console.log("Token added successfully");
        return {success: true};
      })
      .catch((error) => {
        console.log("Error adding token:", error);
        throw new functions.https.HttpsError("unknown", "Failed to add token.");
      });
});

exports.removeToken = functions.https.onCall((data, context) => {
  const productCode = data.product_code;
  const serialNumber = data.serialNumber;
  const token = data.token;

  if (!productCode || !serialNumber || !token) {
    throw new functions.https.HttpsError("invalid-argument");
  }

  const documentPath = `${productCode}/${serialNumber}`;

  return admin.firestore().doc(documentPath).update({
    notificationTokens: admin.firestore.FieldValue.arrayRemove(token),
  })
      .then(() => {
        console.log("Token removed successfully");
        return {success: true};
      })
      .catch((error) => {
        console.log("Error removing token:", error);
        throw new functions.https.HttpsError("unknown");
      });
});
