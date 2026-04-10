const admin = require('firebase-admin');

let initError = null;

function parseServiceAccount() {
  const rawJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (rawJson && rawJson.trim()) {
    return JSON.parse(rawJson);
  }

  const base64Json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON_BASE64;
  if (base64Json && base64Json.trim()) {
    return JSON.parse(Buffer.from(base64Json, 'base64').toString('utf8'));
  }

  return null;
}

function buildCredential() {
  const serviceAccount = parseServiceAccount();
  if (serviceAccount) {
    const normalizedAccount = { ...serviceAccount };

    if (typeof normalizedAccount.private_key === 'string') {
      normalizedAccount.private_key = normalizedAccount.private_key.replace(/\\n/g, '\n');
    }

    return admin.credential.cert(normalizedAccount);
  }

  return admin.credential.applicationDefault();
}

function initializeFirebaseAdmin() {
  if (admin.apps.length > 0) {
    return admin.app();
  }

  if (initError) {
    throw initError;
  }

  try {
    const projectId = process.env.FIREBASE_PROJECT_ID || process.env.GCLOUD_PROJECT;
    const credential = buildCredential();
    const options = { credential };

    if (projectId) {
      options.projectId = projectId;
    }

    return admin.initializeApp(options);
  } catch (error) {
    initError = new Error(
      'Firebase Admin could not be initialized. Set FIREBASE_SERVICE_ACCOUNT_JSON, FIREBASE_SERVICE_ACCOUNT_JSON_BASE64, or GOOGLE_APPLICATION_CREDENTIALS.',
    );
    initError.code = 'firebase-admin-init-failed';
    initError.cause = error;
    throw initError;
  }
}

function getAuth() {
  initializeFirebaseAdmin();
  return admin.auth();
}

function getFirestore() {
  initializeFirebaseAdmin();
  return admin.firestore();
}

function getFirebaseStatus() {
  return {
    configured: Boolean(
      process.env.FIREBASE_SERVICE_ACCOUNT_JSON ||
        process.env.FIREBASE_SERVICE_ACCOUNT_JSON_BASE64 ||
        process.env.GOOGLE_APPLICATION_CREDENTIALS ||
        process.env.FIREBASE_PROJECT_ID ||
        process.env.GCLOUD_PROJECT,
    ),
    initialized: admin.apps.length > 0,
    projectId:
      (admin.apps[0] && admin.apps[0].options && admin.apps[0].options.projectId) ||
      process.env.FIREBASE_PROJECT_ID ||
      process.env.GCLOUD_PROJECT ||
      null,
    initError: initError ? initError.message : null,
  };
}

module.exports = {
  admin,
  getAuth,
  getFirebaseStatus,
  getFirestore,
  initializeFirebaseAdmin,
};

