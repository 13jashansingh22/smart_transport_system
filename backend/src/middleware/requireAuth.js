const { getAuth } = require('../config/firebaseAdmin');

async function requireAuth(req, res, next) {
  const authorization = req.headers.authorization || '';
  const [scheme, token] = authorization.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({
      success: false,
      message: 'Missing Firebase bearer token.',
    });
  }

  try {
    const decodedToken = await getAuth().verifyIdToken(token, true);
    req.firebaseUser = decodedToken;
    return next();
  } catch (error) {
    const statusCode = error.code === 'firebase-admin-init-failed' ? 503 : 401;
    return res.status(statusCode).json({
      success: false,
      message:
        statusCode === 503
          ? 'Firebase Admin is not configured on the backend.'
          : 'Invalid or expired Firebase token.',
    });
  }
}

module.exports = {
  requireAuth,
};

