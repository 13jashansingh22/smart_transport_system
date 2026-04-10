const { Router } = require('express');

const { getFirebaseStatus } = require('../config/firebaseAdmin');

const router = Router();

router.get('/status', (req, res) => {
  const status = getFirebaseStatus();
  const httpStatus = status.initialized ? 200 : 503;

  res.status(httpStatus).json({
    success: httpStatus === 200,
    firebase: status,
  });
});

module.exports = router;

