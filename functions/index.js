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


exports.multitaskFunction = functions.https.onRequest(
    async (req, res) => {
      if (req.method !== "POST") {
        res.status(405).send("Método no permitido");
        return;
      }
      const type = req.body.type;
      if (type === "Calefactor") {
        const collectionName = req.body.deviceName;
        if (!collectionName) {
          res.status(400).send("El nombre de la colección es requerido");
          return;
        }
        try {
          const docRef = admin.firestore()
              .collection(collectionName).doc("info");
          const doc = await docRef.get();
          if (!doc.exists) {
            res.status(404).send("Documento"+ collectionName + "no encontrado");
            return;
          }
          const data = doc.data();

          const verhard = req.body.hv;
          const productType = req.body.product_code;
          const otaRef = admin.firestore()
              .collection("OtaData").doc(productType);
          const otadoc = await otaRef.get();
          if (!otadoc.exists) {
            res.status(404).send("El producto"+ productType + "no existe");
            return;
          }
          const versions = otadoc.data();
          if (!(verhard in versions)) {
            res.status(404).send("No existe versión de hardware: " + verhard);
            return;
          }
          const sv = versions[verhard];
          const estado = data["estado"];
          res.status(200).send({status: estado, sv: sv});
        } catch (error) {
          console.error("Error al obtener el documento:", error);
          res.status(500).send("Error interno del servidor", error);
        }
      } else if (type === "Detector") {
        const collectionName = req.body.deviceName;
        const fun = parseInt(req.body.alert, 10);
        const alertValue = fun === 1;
        const ppmco = parseInt(req.body.ppmCO, 10);
        const ppmch4 = parseInt(req.body.ppmCH4, 10);

        const verhard = req.body.hv;
        const productType = req.body.product_code;
        const otaRef = admin.firestore()
            .collection("OtaData").doc(productType);
        const otadoc = await otaRef.get();
        if (!otadoc.exists) {
          res.status(404).send("El producto"+ productType + "no existe");
          return;
        }
        const versions = otadoc.data();
        if (!(verhard in versions)) {
          res.status(404).send("No existe versión de hardware: " + verhard);
          return;
        }
        const sv = versions[verhard];
        try {
          const docRef = admin.firestore()
              .collection(collectionName).doc("info");
          await docRef.update({
            "alert": alertValue,
            "ppmCO": ppmco,
            "ppmCH4": ppmch4,
          });
          res.status(200).send({sv: sv});
        } catch (error) {
          console.error("Error al actualizar el documento:", error);
          res.status(500).send("Error al actualizar el documento");
        }
      }
      res.status(666).send("Mandaste cualquier cosa");
    });
