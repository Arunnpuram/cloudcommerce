# 🚀 Getting Started with CloudCommerce

Welcome to CloudCommerce! This guide will help you get the platform running locally in just a few minutes.

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Docker Desktop** 4.0+ ([Download](https://www.docker.com/products/docker-desktop/))
- **Git** ([Download](https://git-scm.com/))
- **Node.js** 18+ (optional, for development)
- **Python** 3.11+ (optional, for development)
- **Go** 1.21+ (optional, for development)

## 🏃‍♂️ Quick Start (5 minutes)

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/cloudcommerce.git
cd cloudcommerce
```

### 2. Start the Platform
```bash
# Option A: Using Make (recommended)
make quick-start

# Option B: Using Docker Compose directly
docker-compose up -d
```

### 3. Verify Everything is Running
```bash
# Check service health
make health-check-local

# Or manually check each service
curl http://localhost:3001/health  # User Service
curl http://localhost:8000/health  # Product Service  
curl http://localhost:8080/health  # Order Service
```

### 4. Access the Platform

Once all services are running, you can access:

| Service | URL | Credentials |
|---------|-----|-------------|
| **User Service** | http://localhost:3001/health | - |
| **Product Service** | http://localhost:8000/docs | - |
| **Order Service** | http://localhost:8080/health | - |
| **Grafana** | http://localhost:3000 | admin / cloudcommerce2024 |
| **Prometheus** | http://localhost:9090 | - |
| **Kibana** | http://localhost:5601 | - |
| **RabbitMQ** | http://localhost:15672 | cloudcommerce / cloudcommerce2024 |

## 🧪 Test the APIs

### User Service
```bash
# Register a new user
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123"
  }'

# Login
curl -X POST http://localhost:3001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@cloudcommerce.com",
    "password": "admin123"
  }'

# Get all users
curl http://localhost:3001/api/users
```

### Product Service
```bash
# Get all products
curl http://localhost:8000/api/v1/products

# Get categories
curl http://localhost:8000/api/v1/categories

# Create a product
curl -X POST http://localhost:8000/api/v1/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Awesome Product",
    "description": "This is an awesome product",
    "price": 29.99,
    "category": "Electronics",
    "stock_quantity": 100
  }'
```

### Order Service
```bash
# Get all orders
curl http://localhost:8080/api/v1/orders

# Create an order
curl -X POST http://localhost:8080/api/v1/orders \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "items": [
      {
        "product_id": 1,
        "quantity": 2,
        "price": 29.99
      }
    ]
  }'
```

## 📊 Monitoring & Observability

### Grafana Dashboards
1. Open http://localhost:3000
2. Login with `admin` / `cloudcommerce2024`
3. Explore pre-configured dashboards for:
   - Application performance metrics
   - Infrastructure monitoring
   - Business KPIs

### Prometheus Metrics
1. Open http://localhost:9090
2. Query metrics like:
   - `cloudcommerce_http_requests_total`
   - `cloudcommerce_http_request_duration_seconds`
   - `up` (service availability)

### Logs with Kibana
1. Open http://localhost:5601
2. Create index patterns for application logs
3. Explore structured logs from all services

## 🛠️ Development Workflow

### Making Changes to Services

1. **Edit code** in `services/[service-name]/`
2. **Rebuild the service**:
   ```bash
   make build-user    # For user service
   make build-product # For product service
   make build-order   # For order service
   ```
3. **Restart the service**:
   ```bash
   docker-compose restart user-service
   ```

### Running Tests
```bash
# Run all tests
make test

# Run tests for specific service
make test-user
make test-product
make test-order
```

### Code Quality
```bash
# Lint all code
make lint

# Format code
make format

# Security scan
make security-scan
```

## 🐳 Docker Commands

### Useful Docker Commands
```bash
# View running containers
docker ps

# View logs for a specific service
docker-compose logs -f user-service

# Execute commands in a container
docker-compose exec user-service /bin/sh

# Restart a specific service
docker-compose restart user-service

# Rebuild a service
docker-compose up -d --build user-service
```

### Cleanup
```bash
# Stop all services
make dev-down

# Clean everything (removes data)
make dev-clean

# Reset development environment
make dev-reset
```

## 🔧 Troubleshooting

### Common Issues

#### 1. Port Already in Use
```bash
# Find what's using the port
netstat -tulpn | grep :3000

# Kill the process
sudo kill -9 <PID>
```

#### 2. Docker Out of Space
```bash
# Clean up Docker
docker system prune -a
docker volume prune
```

#### 3. Services Not Starting
```bash
# Check logs
docker-compose logs [service-name]

# Check service health
docker-compose ps
```

#### 4. Database Connection Issues
```bash
# Restart databases
docker-compose restart mongodb postgresql redis

# Check database logs
docker-compose logs mongodb
docker-compose logs postgresql
```

### Getting Help

1. **Check the logs**: `docker-compose logs -f`
2. **Verify health**: `make health-check-local`
3. **Reset environment**: `make dev-reset`
4. **Check documentation**: Browse the `docs/` folder
5. **Open an issue**: [GitHub Issues](https://github.com/your-username/cloudcommerce/issues)

## 🎯 Next Steps

Now that you have CloudCommerce running locally, you can:

1. **Explore the APIs** using the Swagger UI at http://localhost:8000/docs
2. **Monitor performance** with Grafana dashboards
3. **View logs** in Kibana
4. **Modify services** and see changes in real-time
5. **Deploy to Kubernetes** using the provided manifests
6. **Set up CI/CD** with the GitHub Actions workflows

## 📚 Additional Resources

- [Architecture Documentation](docs/ARCHITECTURE.md)
- [API Reference](docs/API.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Contributing Guide](docs/CONTRIBUTING.md)

---

**Welcome to CloudCommerce!** 🎉 You're now ready to explore and develop with a production-ready, cloud-native e-commerce platform.