const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.saveToken = functions.https.onRequest(
    async (req, res) => {
      const productCode = req.body.product_code;
      const serialNumber = req.body.serialNumber;
      const token = req.body.token;

      if (!productCode || !serialNumber || !token) {
        throw new functions.https.HttpsError("invalid-argument");
      }

      const documentPath = `${productCode}/${serialNumber}`;

      return admin.firestore().doc(documentPath).set({
        Tokens: admin.firestore.FieldValue.arrayUnion(token),
      }, {merge: true})
          .then(() => {
            res.status(200).send("Token added successfully");
            console.log("Token added successfully");
            return {success: true};
          })
          .catch((error) => {
            res.status(600).send("something went wrong");
            console.log("Error adding token:", error);
            throw new functions.https.HttpsError("Failed to add token.");
          });
    });

exports.removeToken = functions.https.onRequest(
    (req, res) => {
      const productCode = req.body.product_code;
      const serialNumber = req.body.serialNumber;
      const token = req.body.token;

      if (!productCode || !serialNumber || !token) {
        throw new functions.https.HttpsError("invalid-argument");
      }

      const documentPath = `${productCode}/${serialNumber}`;

      return admin.firestore().doc(documentPath).update({
        Tokens: admin.firestore.FieldValue.arrayRemove(token),
      })
          .then(() => {
            res.status(200).send("Token removed successfully");
            console.log("Token removed successfully");
            return {success: true};
          })
          .catch((error) => {
            res.status(300).send("Error removing token");
            console.log("Error removing token:", error);
            throw new functions.https.HttpsError("unknown");
          });
    });

exports.receiveAlert = functions.https.onRequest(async (req, res) => {
  const {productCode, serialNumber} = req.body;

  // Construye la ruta al documento en Firestore
  const docPath = `${productCode}/${serialNumber}`;
  try {
    const doc = await admin.firestore().doc(docPath).get();
    if (!doc.exists) {
      console.log("No se encuentra el documento");
      return res.status(404).send("Documento no encontrado");
    }

    const data = doc.data();
    let tokens = data.Tokens;
    console.log("Tokens:", tokens);

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
            res.status(200).send("Todo piola");
            console.log("Successfully sent all messages:", responses);
            return responses;
          })
          .catch((error) => {
            res.status(300).send("Error");
            console.log("Error sending messages:", error);
          });
    } else {
      res.status(404).send("Sin tokens");
      console.log("No tokens available for notification.");
      return null;
    }
  } catch (error) {
    console.error("Error al acceder a Firestore:", error);
    res.status(500).send("Error interno");
  }
});
