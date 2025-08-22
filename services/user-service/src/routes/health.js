const express = require('express');
const mongoose = require('mongoose');
const router = express.Router();

// Health check endpoint
router.get('/', async (req, res) => {
  try {
    // Check database connection
    const dbState = mongoose.connection.readyState;
    const dbStatus = {
      0: 'disconnected',
      1: 'connected',
      2: 'connecting',
      3: 'disconnecting'
    };

    // Perform a simple database operation
    if (dbState === 1) {
      await mongoose.connection.db.admin().ping();
    }

    const health = {
      status: 'healthy',
      service: 'CloudCommerce User Service',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      environment: process.env.NODE_ENV || 'development',
      database: {
        status: dbStatus[dbState],
        connected: dbState === 1
      },
      memory: {
        used: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
        total: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
        external: Math.round(process.memoryUsage().external / 1024 / 1024)
      },
      system: {
        platform: process.platform,
        nodeVersion: process.version,
        pid: process.pid
      }
    };

    // Return 503 if database is not connected
    if (dbState !== 1) {
      return res.status(503).json({
        ...health,
        status: 'unhealthy',
        error: 'Database not connected'
      });
    }

    res.status(200).json(health);
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(503).json({
      status: 'unhealthy',
      service: 'CloudCommerce User Service',
      version: '1.0.0',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// Readiness probe
router.get('/ready', async (req, res) => {
  try {
    // Check if service is ready to accept traffic
    const dbState = mongoose.connection.readyState;
    
    if (dbState === 1) {
      await mongoose.connection.db.admin().ping();
      res.status(200).json({ status: 'ready' });
    } else {
      res.status(503).json({ status: 'not ready', reason: 'database not connected' });
    }
  } catch (error) {
    res.status(503).json({ status: 'not ready', reason: error.message });
  }
});

// Liveness probe
router.get('/live', (req, res) => {
  // Simple liveness check - service is running
  res.status(200).json({ 
    status: 'alive',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

module.exports = router;