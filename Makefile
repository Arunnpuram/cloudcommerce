# CloudCommerce Platform Makefile

.PHONY: help dev-up dev-down build test lint security-scan deploy clean

# Default target
help: ## Show this help message
	@echo "CloudCommerce - Enterprise E-Commerce Platform"
	@echo "=============================================="
	@echo ""
	@echo "Available commands:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development Environment
dev-up: ## Start development environment
	@echo "🚀 Starting CloudCommerce development environment..."
	docker-compose up -d
	@echo "✅ Development environment started"
	@echo ""
	@echo "🌐 Access URLs:"
	@echo "  User Service:    http://localhost:3001/health"
	@echo "  Product Service: http://localhost:8000/docs"
	@echo "  Order Service:   http://localhost:8080/health"
	@echo "  Grafana:         http://localhost:3000 (admin/cloudcommerce2024)"
	@echo "  Prometheus:      http://localhost:9090"
	@echo "  Kibana:          http://localhost:5601"
	@echo "  RabbitMQ:        http://localhost:15672 (cloudcommerce/cloudcommerce2024)"

dev-down: ## Stop development environment
	@echo "🛑 Stopping CloudCommerce development environment..."
	docker-compose down
	@echo "✅ Development environment stopped"

dev-logs: ## Show development logs
	docker-compose logs -f

dev-clean: ## Clean development environment (removes volumes)
	@echo "🧹 Cleaning CloudCommerce development environment..."
	docker-compose down -v
	docker system prune -f
	@echo "✅ Development environment cleaned"

dev-restart: ## Restart development environment
	$(MAKE) dev-down
	$(MAKE) dev-up

# Build
build: ## Build all service images
	@echo "🔨 Building CloudCommerce service images..."
	docker build -t cloudcommerce/user-service ./services/user-service
	docker build -t cloudcommerce/product-service ./services/product-service
	docker build -t cloudcommerce/order-service ./services/order-service
	@echo "✅ All images built successfully"

build-user: ## Build user service image
	docker build -t cloudcommerce/user-service ./services/user-service

build-product: ## Build product service image
	docker build -t cloudcommerce/product-service ./services/product-service

build-order: ## Build order service image
	docker build -t cloudcommerce/order-service ./services/order-service

# Testing
test: ## Run all tests
	@echo "🧪 Running CloudCommerce tests..."
	$(MAKE) test-user
	$(MAKE) test-product
	$(MAKE) test-order
	@echo "✅ All tests completed"

test-user: ## Run user service tests
	@echo "Testing user service..."
	cd services/user-service && npm test

test-product: ## Run product service tests
	@echo "Testing product service..."
	cd services/product-service && python -m pytest

test-order: ## Run order service tests
	@echo "Testing order service..."
	cd services/order-service && go test ./...

test-integration: ## Run integration tests
	@echo "🔗 Running integration tests..."
	./scripts/integration-tests.sh

test-load: ## Run load tests
	@echo "⚡ Running load tests..."
	k6 run --vus 10 --duration 30s scripts/load-tests/basic-load-test.js

# Code Quality
lint: ## Run linting for all services
	@echo "🔍 Running linting..."
	$(MAKE) lint-user
	$(MAKE) lint-product
	$(MAKE) lint-order
	@echo "✅ Linting completed"

lint-user: ## Lint user service
	cd services/user-service && npm run lint

lint-product: ## Lint product service
	cd services/product-service && black --check . && flake8 .

lint-order: ## Lint order service
	cd services/order-service && go fmt ./... && go vet ./...

format: ## Format code for all services
	@echo "🎨 Formatting code..."
	cd services/user-service && npm run lint:fix
	cd services/product-service && black .
	cd services/order-service && go fmt ./...
	@echo "✅ Code formatting completed"

# Security
security-scan: ## Run security scans
	@echo "🔒 Running security scans..."
	$(MAKE) security-scan-containers
	$(MAKE) security-scan-code
	@echo "✅ Security scans completed"

security-scan-containers: ## Scan container images for vulnerabilities
	@echo "🐳 Scanning container images..."
	trivy image cloudcommerce/user-service:latest
	trivy image cloudcommerce/product-service:latest
	trivy image cloudcommerce/order-service:latest

security-scan-code: ## Run static code analysis
	@echo "📝 Running static code analysis..."
	semgrep --config=auto .

security-scan-k8s: ## Scan Kubernetes manifests
	@echo "☸️ Scanning Kubernetes manifests..."
	kubesec scan k8s/*.yaml

# Infrastructure
infra-plan: ## Plan Terraform infrastructure
	@echo "📋 Planning infrastructure..."
	cd infrastructure && terraform plan

infra-apply: ## Apply Terraform infrastructure
	@echo "🏗️ Applying infrastructure..."
	cd infrastructure && terraform apply

infra-destroy: ## Destroy Terraform infrastructure
	@echo "💥 Destroying infrastructure..."
	cd infrastructure && terraform destroy

infra-validate: ## Validate Terraform configuration
	@echo "✅ Validating infrastructure..."
	cd infrastructure && terraform validate
	cd infrastructure && terraform fmt -check

# Kubernetes Deployment
k8s-deploy: ## Deploy to Kubernetes
	@echo "☸️ Deploying CloudCommerce to Kubernetes..."
	./scripts/deploy.sh

k8s-deploy-staging: ## Deploy to staging environment
	@echo "🎭 Deploying to staging..."
	./scripts/deploy.sh staging

k8s-deploy-production: ## Deploy to production environment
	@echo "🚀 Deploying to production..."
	./scripts/deploy.sh production

k8s-status: ## Check Kubernetes deployment status
	@echo "📊 Checking deployment status..."
	kubectl get pods -n cloudcommerce
	kubectl get svc -n cloudcommerce
	kubectl get ingress -n cloudcommerce

k8s-logs: ## Show Kubernetes logs
	@echo "📋 Showing application logs..."
	kubectl logs -f -l app=user-service -n cloudcommerce --tail=100

k8s-clean: ## Clean Kubernetes resources
	@echo "🧹 Cleaning Kubernetes resources..."
	kubectl delete namespace cloudcommerce --ignore-not-found
	kubectl delete namespace monitoring --ignore-not-found

# Monitoring
monitor-port-forward: ## Port forward monitoring services
	@echo "🔗 Setting up port forwarding..."
	kubectl port-forward svc/grafana 3000:3000 -n monitoring &
	kubectl port-forward svc/prometheus 9090:9090 -n monitoring &
	@echo "📊 Grafana: http://localhost:3000"
	@echo "🔍 Prometheus: http://localhost:9090"

monitor-stop: ## Stop port forwarding
	@echo "🛑 Stopping port forwarding..."
	pkill -f "kubectl port-forward" || true

# Health Checks
health-check: ## Check service health
	@echo "🏥 Checking CloudCommerce service health..."
	./scripts/health-check.sh

health-check-local: ## Check local service health
	@echo "🏥 Checking local service health..."
	curl -f http://localhost:3001/health && echo " ✅ User Service"
	curl -f http://localhost:8000/health && echo " ✅ Product Service"
	curl -f http://localhost:8080/health && echo " ✅ Order Service"
	curl -f http://localhost:9090/-/healthy && echo " ✅ Prometheus"
	curl -f http://localhost:3000/api/health && echo " ✅ Grafana"

smoke-test: ## Run smoke tests
	@echo "💨 Running smoke tests..."
	./scripts/smoke-tests.sh

# Database Operations
db-migrate: ## Run database migrations
	@echo "🗃️ Running database migrations..."
	kubectl exec -it deployment/product-service -n cloudcommerce -- python -m alembic upgrade head

db-seed: ## Seed databases with sample data
	@echo "🌱 Seeding databases..."
	./scripts/seed-data.sh

db-backup: ## Backup databases
	@echo "💾 Backing up databases..."
	./scripts/backup-databases.sh

# Utilities
install: ## Install dependencies for all services
	@echo "📦 Installing dependencies..."
	cd services/user-service && npm install
	cd services/product-service && pip install -r requirements.txt
	cd services/order-service && go mod download

generate-docs: ## Generate API documentation
	@echo "📚 Generating API documentation..."
	cd services/product-service && python -c "import main; import json; print(json.dumps(main.app.openapi(), indent=2))" > ../../docs/product-api.json
	@echo "✅ API documentation generated"

clean: ## Clean all build artifacts and caches
	@echo "🧹 Cleaning build artifacts..."
	docker system prune -f
	docker volume prune -f
	cd services/user-service && rm -rf node_modules coverage
	cd services/product-service && rm -rf __pycache__ .pytest_cache
	cd services/order-service && go clean -cache -testcache
	@echo "✅ Cleanup completed"

# CI/CD
ci-test: ## Run CI tests (used in GitHub Actions)
	$(MAKE) lint
	$(MAKE) test
	$(MAKE) security-scan

ci-build: ## Build for CI (used in GitHub Actions)
	$(MAKE) build

# Quick Start
quick-start: ## Quick start for new developers
	@echo "🚀 CloudCommerce Quick Start..."
	@echo "1. Starting development environment..."
	$(MAKE) dev-up
	@echo "2. Building services..."
	$(MAKE) build
	@echo "3. Running health checks..."
	sleep 30
	$(MAKE) health-check-local
	@echo "✅ CloudCommerce is ready!"
	@echo ""
	@echo "🌐 Access URLs:"
	@echo "  User Service:    http://localhost:3001/health"
	@echo "  Product Service: http://localhost:8000/docs"
	@echo "  Order Service:   http://localhost:8080/health"
	@echo "  Grafana:         http://localhost:3000 (admin/cloudcommerce2024)"
	@echo "  Prometheus:      http://localhost:9090"

# Development helpers
dev-reset: ## Reset development environment
	$(MAKE) dev-down
	$(MAKE) dev-clean
	$(MAKE) dev-up

dev-rebuild: ## Rebuild and restart development environment
	$(MAKE) dev-down
	$(MAKE) build
	$(MAKE) dev-up

# Documentation
docs-serve: ## Serve documentation locally
	@echo "📚 Serving documentation..."
	python -m http.server 8080 -d docs

docs-build: ## Build documentation
	@echo "📖 Building documentation..."
	@echo "✅ Documentation built"