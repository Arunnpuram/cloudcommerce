const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const router = express.Router();

// Sample user credentials for demonstration
const users = [
  {
    id: 1,
    email: 'admin@cloudcommerce.com',
    password: '$2a$10$8K1p/a0dRTlNqNhI1RVHBOaHQ4WMn.V8W5VkSMxFx5rQ9qNhI1RVH', // password: admin123
    name: 'Admin User',
    role: 'admin'
  },
  {
    id: 2,
    email: 'user@cloudcommerce.com',
    password: '$2a$10$8K1p/a0dRTlNqNhI1RVHBOaHQ4WMn.V8W5VkSMxFx5rQ9qNhI1RVH', // password: user123
    name: 'Regular User',
    role: 'customer'
  }
];

// Login endpoint
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Validation
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Email and password are required'
      });
    }
    
    // Find user
    const user = users.find(u => u.email === email);
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }
    
    // For demo purposes, accept any password
    // In production, use: const isValidPassword = await bcrypt.compare(password, user.password);
    const isValidPassword = true;
    
    if (!isValidPassword) {
      return res.status(401).json({
        success: false,
        error: 'Invalid credentials'
      });
    }
    
    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: user.id,
        email: user.email,
        role: user.role
      },
      process.env.JWT_SECRET || 'cloudcommerce-dev-secret',
      { 
        expiresIn: process.env.JWT_EXPIRES_IN || '24h',
        issuer: 'cloudcommerce-user-service'
      }
    );
    
    // Update last login (in real app, save to database)
    user.lastLogin = new Date().toISOString();
    
    res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          lastLogin: user.lastLogin
        }
      },
      message: 'Login successful',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Login failed',
      message: error.message
    });
  }
});

// Register endpoint
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, role = 'customer' } = req.body;
    
    // Validation
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Name, email, and password are required'
      });
    }
    
    // Check if user already exists
    const existingUser = users.find(u => u.email === email);
    if (existingUser) {
      return res.status(409).json({
        success: false,
        error: 'User with this email already exists'
      });
    }
    
    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // Create new user
    const newUser = {
      id: Math.max(...users.map(u => u.id)) + 1,
      email,
      password: hashedPassword,
      name,
      role,
      createdAt: new Date().toISOString(),
      lastLogin: null
    };
    
    // Save user (in real app, save to database)
    users.push(newUser);
    
    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: newUser.id,
        email: newUser.email,
        role: newUser.role
      },
      process.env.JWT_SECRET || 'cloudcommerce-dev-secret',
      { 
        expiresIn: process.env.JWT_EXPIRES_IN || '24h',
        issuer: 'cloudcommerce-user-service'
      }
    );
    
    res.status(201).json({
      success: true,
      data: {
        token,
        user: {
          id: newUser.id,
          email: newUser.email,
          name: newUser.name,
          role: newUser.role,
          createdAt: newUser.createdAt
        }
      },
      message: 'User registered successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: 'Registration failed',
      message: error.message
    });
  }
});

// Token validation endpoint
router.post('/validate', (req, res) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'Token is required'
      });
    }
    
    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'cloudcommerce-dev-secret');
    
    // Find user
    const user = users.find(u => u.id === decoded.userId);
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Invalid token - user not found'
      });
    }
    
    res.json({
      success: true,
      data: {
        valid: true,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role
        },
        tokenInfo: {
          issuedAt: new Date(decoded.iat * 1000).toISOString(),
          expiresAt: new Date(decoded.exp * 1000).toISOString()
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        error: 'Invalid token'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: 'Token expired'
      });
    }
    
    res.status(500).json({
      success: false,
      error: 'Token validation failed',
      message: error.message
    });
  }
});

// Refresh token endpoint
router.post('/refresh', (req, res) => {
  try {
    const { token } = req.body;
    
    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'Token is required'
      });
    }
    
    // Verify token (even if expired, we can still decode it)
    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET || 'cloudcommerce-dev-secret');
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        decoded = jwt.decode(token);
      } else {
        throw error;
      }
    }
    
    // Find user
    const user = users.find(u => u.id === decoded.userId);
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'Invalid token - user not found'
      });
    }
    
    // Generate new token
    const newToken = jwt.sign(
      { 
        userId: user.id,
        email: user.email,
        role: user.role
      },
      process.env.JWT_SECRET || 'cloudcommerce-dev-secret',
      { 
        expiresIn: process.env.JWT_EXPIRES_IN || '24h',
        issuer: 'cloudcommerce-user-service'
      }
    );
    
    res.json({
      success: true,
      data: {
        token: newToken,
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role
        }
      },
      message: 'Token refreshed successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(401).json({
      success: false,
      error: 'Token refresh failed',
      message: error.message
    });
  }
});

// Logout endpoint (for completeness, though JWT is stateless)
router.post('/logout', (req, res) => {
  // In a real application, you might want to blacklist the token
  // or store logout events for audit purposes
  
  res.json({
    success: true,
    message: 'Logged out successfully',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;