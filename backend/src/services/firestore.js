const { admin, getFirestore } = require('../config/firebaseAdmin');

function profilesCollection() {
  return getFirestore().collection('user_profiles');
}

async function getUserProfile(uid) {
  const snapshot = await profilesCollection().doc(uid).get();

  if (!snapshot.exists) {
    return null;
  }

  return {
    id: snapshot.id,
    ...snapshot.data(),
  };
}

async function upsertUserProfile(uid, profile) {
  const payload = {
    ...profile,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await profilesCollection().doc(uid).set(payload, { merge: true });
  return getUserProfile(uid);
}

module.exports = {
  getUserProfile,
  upsertUserProfile,
};

