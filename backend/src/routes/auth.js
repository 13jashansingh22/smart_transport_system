const { Router } = require('express');

const { requireAuth } = require('../middleware/requireAuth');

const router = Router();

router.get('/me', requireAuth, (req, res) => {
  res.json({
    success: true,
    user: req.firebaseUser,
  });
});

module.exports = router;

