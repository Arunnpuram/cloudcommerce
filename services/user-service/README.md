# CloudCommerce User Service

The User Service is responsible for user authentication, authorization, and profile management in the CloudCommerce platform.

## Features

- ✅ User registration and authentication
- ✅ JWT token generation and validation
- ✅ User profile management
- ✅ Role-based access control
- ✅ Password hashing with bcrypt
- ✅ Rate limiting and security middleware
- ✅ Prometheus metrics integration
- ✅ Health checks and monitoring

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/validate` - Token validation
- `POST /api/auth/refresh` - Token refresh
- `POST /api/auth/logout` - User logout

### User Management
- `GET /api/users` - Get all users (with pagination)
- `GET /api/users/:id` - Get user by ID
- `POST /api/users` - Create new user
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user
- `GET /api/users/:id/profile` - Get user profile

### System
- `GET /health` - Health check
- `GET /health/ready` - Readiness probe
- `GET /health/live` - Liveness probe
- `GET /metrics` - Prometheus metrics

## Environment Variables

```bash
NODE_ENV=production
PORT=3001
MONGODB_URI=mongodb://localhost:27017/cloudcommerce_users
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=24h
RATE_LIMIT=100
ALLOWED_ORIGINS=http://localhost:3000,https://cloudcommerce.com
```

## Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test

# Run linting
npm run lint

# Build Docker image
npm run docker:build
```

## Docker

```bash
# Build image
docker build -t cloudcommerce/user-service .

# Run container
docker run -p 3001:3001 \
  -e MONGODB_URI=mongodb://host.docker.internal:27017/cloudcommerce_users \
  cloudcommerce/user-service
```

## Testing

```bash
# Health check
curl http://localhost:3001/health

# Login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@cloudcommerce.com","password":"admin123"}'

# Get users
curl http://localhost:3001/api/users
```

## Monitoring

The service exposes Prometheus metrics at `/metrics` endpoint:

- `cloudcommerce_http_requests_total` - Total HTTP requests
- `cloudcommerce_http_request_duration_seconds` - Request duration
- Standard Node.js metrics (memory, CPU, etc.)

## Security

- Helmet.js for security headers
- CORS configuration
- Rate limiting
- JWT token authentication
- Password hashing with bcrypt
- Input validation
- Non-root Docker user