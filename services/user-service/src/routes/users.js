const express = require('express');
const router = express.Router();

// Sample user data for demonstration
const sampleUsers = [
  { 
    id: 1, 
    name: 'John Doe', 
    email: 'john.doe@cloudcommerce.com',
    role: 'customer',
    createdAt: '2024-01-15T10:30:00Z',
    lastLogin: '2024-01-20T14:22:00Z'
  },
  { 
    id: 2, 
    name: 'Jane Smith', 
    email: 'jane.smith@cloudcommerce.com',
    role: 'admin',
    createdAt: '2024-01-10T09:15:00Z',
    lastLogin: '2024-01-21T11:45:00Z'
  },
  { 
    id: 3, 
    name: 'Mike Johnson', 
    email: 'mike.johnson@cloudcommerce.com',
    role: 'customer',
    createdAt: '2024-01-18T16:20:00Z',
    lastLogin: '2024-01-21T08:30:00Z'
  }
];

// Get all users with pagination
router.get('/', (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const search = req.query.search || '';
    
    let filteredUsers = sampleUsers;
    
    // Simple search functionality
    if (search) {
      filteredUsers = sampleUsers.filter(user => 
        user.name.toLowerCase().includes(search.toLowerCase()) ||
        user.email.toLowerCase().includes(search.toLowerCase())
      );
    }
    
    const startIndex = (page - 1) * limit;
    const endIndex = startIndex + limit;
    const paginatedUsers = filteredUsers.slice(startIndex, endIndex);
    
    res.json({
      success: true,
      data: {
        users: paginatedUsers,
        pagination: {
          currentPage: page,
          totalPages: Math.ceil(filteredUsers.length / limit),
          totalUsers: filteredUsers.length,
          hasNext: endIndex < filteredUsers.length,
          hasPrev: startIndex > 0
        }
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch users',
      message: error.message
    });
  }
});

// Get user by ID
router.get('/:id', (req, res) => {
  try {
    const { id } = req.params;
    const userId = parseInt(id);
    
    if (isNaN(userId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid user ID format'
      });
    }
    
    const user = sampleUsers.find(u => u.id === userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }
    
    res.json({
      success: true,
      data: { user },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user',
      message: error.message
    });
  }
});

// Create new user
router.post('/', (req, res) => {
  try {
    const { name, email, role = 'customer' } = req.body;
    
    // Basic validation
    if (!name || !email) {
      return res.status(400).json({
        success: false,
        error: 'Name and email are required'
      });
    }
    
    // Check if email already exists
    const existingUser = sampleUsers.find(u => u.email === email);
    if (existingUser) {
      return res.status(409).json({
        success: false,
        error: 'User with this email already exists'
      });
    }
    
    const newUser = {
      id: Math.max(...sampleUsers.map(u => u.id)) + 1,
      name,
      email,
      role,
      createdAt: new Date().toISOString(),
      lastLogin: null
    };
    
    // In a real application, this would be saved to database
    sampleUsers.push(newUser);
    
    res.status(201).json({
      success: true,
      data: { user: newUser },
      message: 'User created successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to create user',
      message: error.message
    });
  }
});

// Update user
router.put('/:id', (req, res) => {
  try {
    const { id } = req.params;
    const userId = parseInt(id);
    const { name, email, role } = req.body;
    
    if (isNaN(userId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid user ID format'
      });
    }
    
    const userIndex = sampleUsers.findIndex(u => u.id === userId);
    
    if (userIndex === -1) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }
    
    // Update user data
    if (name) sampleUsers[userIndex].name = name;
    if (email) sampleUsers[userIndex].email = email;
    if (role) sampleUsers[userIndex].role = role;
    sampleUsers[userIndex].updatedAt = new Date().toISOString();
    
    res.json({
      success: true,
      data: { user: sampleUsers[userIndex] },
      message: 'User updated successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to update user',
      message: error.message
    });
  }
});

// Delete user
router.delete('/:id', (req, res) => {
  try {
    const { id } = req.params;
    const userId = parseInt(id);
    
    if (isNaN(userId)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid user ID format'
      });
    }
    
    const userIndex = sampleUsers.findIndex(u => u.id === userId);
    
    if (userIndex === -1) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }
    
    const deletedUser = sampleUsers.splice(userIndex, 1)[0];
    
    res.json({
      success: true,
      data: { user: deletedUser },
      message: 'User deleted successfully',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to delete user',
      message: error.message
    });
  }
});

// Get user profile (requires authentication in real app)
router.get('/:id/profile', (req, res) => {
  try {
    const { id } = req.params;
    const userId = parseInt(id);
    
    const user = sampleUsers.find(u => u.id === userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }
    
    // Return profile with additional details
    const profile = {
      ...user,
      preferences: {
        theme: 'light',
        notifications: true,
        language: 'en'
      },
      stats: {
        totalOrders: Math.floor(Math.random() * 50),
        totalSpent: Math.floor(Math.random() * 5000),
        memberSince: user.createdAt
      }
    };
    
    res.json({
      success: true,
      data: { profile },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Failed to fetch user profile',
      message: error.message
    });
  }
});

module.exports = router;