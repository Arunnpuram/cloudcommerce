const express = require('express');
const promClient = require('prom-client');
const router = express.Router();

// Metrics endpoint for Prometheus
router.get('/', (req, res) => {
  res.set('Content-Type', promClient.register.contentType);
  res.end(promClient.register.metrics());
});

module.exports = router;