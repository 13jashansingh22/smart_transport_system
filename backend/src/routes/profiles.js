const { Router } = require('express');

const { requireAuth } = require('../middleware/requireAuth');
const { getUserProfile, upsertUserProfile } = require('../services/firestore');

const router = Router();

router.get('/me', requireAuth, async (req, res, next) => {
  try {
    const profile = await getUserProfile(req.firebaseUser.uid);

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: 'Profile not found.',
      });
    }

    return res.json({
      success: true,
      data: profile,
    });
  } catch (error) {
    return next(error);
  }
});

router.put('/me', requireAuth, async (req, res, next) => {
  try {
    const profile = await upsertUserProfile(req.firebaseUser.uid, {
      uid: req.firebaseUser.uid,
      email: req.body.email || req.firebaseUser.email || '',
      role: req.body.role || 'passenger',
      state: req.body.state || '',
      city: req.body.city || '',
      town: req.body.town || '',
    });

    return res.json({
      success: true,
      data: profile,
    });
  } catch (error) {
    return next(error);
  }
});

module.exports = router;

