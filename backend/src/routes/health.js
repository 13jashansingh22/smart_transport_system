const { Router } = require('express');

const router = Router();

router.get('/', (req, res) => {
  res.json({
    status: 'ok',
    service: 'smart-transport-backend',
    timestamp: new Date().toISOString(),
  });
});

module.exports = router;

