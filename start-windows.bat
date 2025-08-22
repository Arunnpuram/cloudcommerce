@echo off
echo ========================================
echo  CloudCommerce - Enterprise Platform
echo  Windows Quick Start
echo ========================================
echo.

REM Check if Docker is running
docker version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not running or not installed
    echo Please install Docker Desktop and make sure it's running
    pause
    exit /b 1
)

echo ✅ Docker is running
echo.

echo 🚀 Starting CloudCommerce platform...
echo This will start all services:
echo   - User Service (Node.js)
echo   - Product Service (Python)  
echo   - Order Service (Go)
echo   - MongoDB, PostgreSQL, Redis
echo   - Prometheus, Grafana
echo   - RabbitMQ, Elasticsearch, Kibana
echo.

REM Start the platform
docker-compose up -d

if %errorlevel% neq 0 (
    echo ERROR: Failed to start services
    pause
    exit /b 1
)

echo.
echo ✅ CloudCommerce started successfully!
echo.
echo 🌐 Access URLs:
echo   User Service:    http://localhost:3001/health
echo   Product Service: http://localhost:8000/docs
echo   Order Service:   http://localhost:8080/health
echo   Grafana:         http://localhost:3000 (admin/cloudcommerce2024)
echo   Prometheus:      http://localhost:9090
echo   Kibana:          http://localhost:5601
echo   RabbitMQ:        http://localhost:15672 (cloudcommerce/cloudcommerce2024)
echo.
echo 📋 Useful Commands:
echo   View logs:       docker-compose logs -f
echo   Stop services:   docker-compose down
echo   Health check:    curl http://localhost:3001/health
echo.
pause