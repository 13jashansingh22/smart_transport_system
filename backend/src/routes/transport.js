const { Router } = require('express');
const { routes, vehicles } = require('../data/mockData');

const router = Router();

router.get('/routes', (req, res) => {
  res.json({
    success: true,
    count: routes.length,
    data: routes,
  });
});

router.get('/vehicles', (req, res) => {
  res.json({
    success: true,
    count: vehicles.length,
    data: vehicles,
  });
});

module.exports = router;

