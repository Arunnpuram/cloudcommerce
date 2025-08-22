# CloudCommerce - Enterprise E-Commerce Platform

[![Build Status](https://github.com/Arunnpuram/cloudcommerce/workflows/CloudCommerce%20CI%2FCD%20Pipeline/badge.svg)](https://github.com/Arunnpuram/cloudcommerce/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Native-326ce5.svg)](https://kubernetes.io/)

## 🚀 Overview

**CloudCommerce** is a complete, production-ready e-commerce platform that showcases modern cloud-native development. Think of it as your blueprint for building scalable online stores with enterprise-grade reliability.

### What Does CloudCommerce Do?

🛒 **Full E-commerce Experience**
- **User Management**: Secure registration, authentication, and profile management
- **Product Catalog**: Browse products, search, filter, and manage inventory
- **Order Processing**: Shopping cart, checkout, payment integration, and order tracking
- **Real-time Updates**: Live inventory, order status, and notifications

### Why CloudCommerce?

This isn't just another demo app - it's a **comprehensive learning platform** that demonstrates:

🏗️ **Modern Architecture Patterns**
- Microservices that actually communicate and work together
- Event-driven architecture with real business logic
- Proper separation of concerns and domain boundaries

☁️ **Cloud-Native Best Practices**
- Kubernetes-native deployment with auto-scaling
- Infrastructure as Code with Terraform
- Comprehensive monitoring and observability
- Zero-downtime deployments with blue-green strategies

🔧 **Enterprise DevOps**
- Complete CI/CD pipelines with automated testing
- Security scanning and vulnerability management
- Multi-environment deployment strategies
- Production-ready monitoring and alerting

### Perfect For:

- **Developers** learning microservices and cloud-native patterns
- **DevOps Engineers** implementing modern deployment strategies
- **Architects** designing scalable e-commerce solutions
- **Teams** needing a reference implementation for best practices
- **Students** studying real-world application architecture

CloudCommerce bridges the gap between simple tutorials and complex production systems, giving you a **realistic, working e-commerce platform** you can learn from, extend, and deploy.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     AWS Cloud Infrastructure                    │
├─────────────────────────────────────────────────────────────────┤
│  ALB → Kong Gateway → Istio Service Mesh → Microservices       │
│                                                                 │
│  Services:                    Databases:                       │
│  • User Service (Node.js)    • MongoDB (Users)                │
│  • Product Service (Python)  • PostgreSQL (Products)          │
│  • Order Service (Go)        • Redis (Cache/Sessions)          │
│                                                                 │
│  Observability:              Security:                         │
│  • Prometheus + Grafana      • Trivy + Falco                  │
│  • ELK Stack                 • OWASP ZAP                       │
│  • Jaeger Tracing           • Network Policies                 │
└─────────────────────────────────────────────────────────────────┘
```

## 🛠️ Technology Stack

### **Microservices**
- **User Service**: Node.js + Express + MongoDB + JWT Authentication
- **Product Service**: Python + FastAPI + PostgreSQL + Redis Caching
- **Order Service**: Go + Gin + Redis + Event Processing

### **Infrastructure**
- **Cloud**: AWS (EKS, RDS, ElastiCache, ALB)
- **Orchestration**: Kubernetes with Helm charts
- **IaC**: Terraform with remote state management
- **Service Mesh**: Istio for traffic management and security

### **DevOps & CI/CD**
- **CI/CD**: GitHub Actions with multi-stage pipelines
- **GitOps**: ArgoCD for continuous deployment
- **Security**: Trivy, OWASP ZAP, SonarQube integration
- **Deployment**: Blue-Green with automated rollback

### **Observability**
- **Monitoring**: Prometheus + Grafana with custom dashboards
- **Logging**: ELK Stack (Elasticsearch, Logstash, Kibana)
- **Tracing**: Jaeger distributed tracing
- **Alerting**: AlertManager with Slack integration

## 🚀 Quick Start

### Prerequisites
- Docker Desktop 4.0+
- kubectl 1.27+
- Terraform 1.5+
- AWS CLI 2.0+

### Local Development
```bash
# Clone the repository
git clone https://github.com/Arunnpuram/cloudcommerce.git
cd cloudcommerce

# Start development environment
make dev-up

# Access services
make health-check
```

### Production Deployment
```bash
# Deploy infrastructure
cd infrastructure
terraform init && terraform apply

# Deploy applications
./scripts/deploy.sh production
```

## 📊 Features

### **Business Features**
- ✅ User registration and authentication
- ✅ Product catalog with categories
- ✅ Shopping cart and order management
- ✅ Payment processing integration
- ✅ Real-time inventory tracking
- ✅ Order status notifications

### **Technical Features**
- ✅ Microservices architecture
- ✅ Auto-scaling (HPA/VPA)
- ✅ Circuit breakers and retry logic
- ✅ Distributed caching
- ✅ Event-driven communication
- ✅ API rate limiting

### **DevOps Features**
- ✅ Infrastructure as Code
- ✅ Automated CI/CD pipelines
- ✅ Security scanning (SAST/DAST)
- ✅ Blue-green deployments
- ✅ Comprehensive monitoring
- ✅ Disaster recovery

## 🌐 API Documentation

### User Service
- **Base URL**: `http://localhost:3001`
- **Health**: `GET /health`
- **Authentication**: `POST /api/auth/login`
- **Users**: `GET /api/users`

### Product Service
- **Base URL**: `http://localhost:8000`
- **Swagger UI**: `http://localhost:8000/docs`
- **Products**: `GET /api/v1/products`
- **Categories**: `GET /api/v1/categories`

### Order Service
- **Base URL**: `http://localhost:8080`
- **Health**: `GET /health`
- **Orders**: `GET /api/v1/orders`
- **Create Order**: `POST /api/v1/orders`

## 📊 Monitoring & Observability

### Dashboards
- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **Kibana**: http://localhost:5601

### Key Metrics
- **SLA**: 99.9% uptime target
- **Performance**: P95 latency < 200ms
- **Throughput**: 1000+ RPS per service
- **Error Rate**: < 0.1% target

## 🔒 Security

### Container Security
- Distroless base images
- Non-root user execution
- Vulnerability scanning with Trivy
- Image signing with Cosign

### Runtime Security
- Network policies for micro-segmentation
- RBAC with least privilege
- Secrets management with External Secrets Operator
- Runtime threat detection with Falco

### Application Security
- JWT-based authentication
- Input validation and sanitization
- Rate limiting and DDoS protection
- HTTPS/TLS everywhere

## 🏗️ Development

### Local Setup
```bash
# Install dependencies
make install

# Run tests
make test

# Lint code
make lint

# Build services
make build
```

### Adding New Services
1. Create service directory in `services/`
2. Add Dockerfile and health checks
3. Create Kubernetes manifests in `k8s/`
4. Update CI/CD pipeline
5. Add monitoring configuration

## 📈 Scaling

### Horizontal Scaling
- Kubernetes HPA based on CPU/memory
- Custom metrics scaling (queue depth, response time)
- Cluster autoscaling for node management

### Performance Optimization
- Redis caching at multiple levels
- Database connection pooling
- CDN for static assets
- Async processing for heavy operations

## 🔄 CI/CD Pipeline

### Stages
1. **Code Quality**: Linting, formatting, security scanning
2. **Testing**: Unit, integration, and load testing
3. **Build**: Multi-arch Docker images with optimization
4. **Security**: Container and dependency scanning
5. **Deploy**: Blue-green deployment with health checks
6. **Monitor**: Automated rollback on failure

### Environments
- **Development**: Local Docker Compose
- **Staging**: Minikube/Kind cluster
- **Production**: AWS EKS with multi-AZ setup

## 📚 Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
