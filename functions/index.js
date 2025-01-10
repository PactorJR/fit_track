const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.resetUserAlertsIfElapsed = functions.pubsub.schedule('every 1 hours').onRun(async (context) => {
  console.log('Checking for alerts to reset...');

  const alertsCollection = admin.firestore().collection('alerts');
  const alertsSnapshot = await alertsCollection.get();

  const currentTime = new Date();

  alertsSnapshot.forEach(doc => {
    const alertData = doc.data();
    const lastUpdated = alertData['lastUpdated'] ? alertData['lastUpdated'].toDate() : null;

    if (!lastUpdated || currentTime - lastUpdated > 2 * 60 * 60 * 1000) {
      let updatedUserFields = {};

      // Loop through all keys to reset user IDs
      Object.keys(alertData).forEach(key => {
        if (key !== 'lastUpdated' && key !== 'title' && key !== 'duration' && key !== 'desc') {
          updatedUserFields[key] = false;
        }
      });

      // Update the document with all user IDs set to false and update lastUpdated
      alertsCollection.doc(doc.id).update({
        ...updatedUserFields,
        'lastUpdated': currentTime
      }).then(() => {
        console.log(`Successfully reset alerts for document: ${doc.id}`);
      }).catch(error => {
        console.error(`Error resetting alerts for document ${doc.id}:`, error);
      });
    } else {
      console.log(`No reset needed for document: ${doc.id}`);
    }
  });
});
