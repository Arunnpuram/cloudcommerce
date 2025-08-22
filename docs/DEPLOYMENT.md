# CloudCommerce Deployment Guide

## Prerequisites

### Required Tools
- **AWS CLI** (v2.x): `aws --version`
- **kubectl** (v1.27+): `kubectl version --client`
- **Terraform** (v1.5+): `terraform version`
- **Helm** (v3.12+): `helm version`
- **Docker** (v20.x+): `docker version`

### AWS Setup
```bash
# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

### Kubernetes Access
```bash
# Update kubeconfig for EKS cluster
aws eks update-kubeconfig --region us-west-2 --name cloudcommerce-eks
```

## Infrastructure Deployment

### 1. Terraform Infrastructure

```bash
# Navigate to infrastructure directory
cd infrastructure

# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="environment=production"

# Apply infrastructure
terraform apply -var="environment=production"
```

**Expected Resources Created:**
- VPC with public/private subnets
- EKS cluster with managed node groups
- RDS PostgreSQL instance
- ElastiCache Redis cluster
- Application Load Balancer
- Security groups and IAM roles

### 2. Verify Infrastructure

```bash
# Check EKS cluster status
aws eks describe-cluster --name cloudcommerce-eks --region us-west-2

# Verify node groups
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system
```

## Application Deployment

### 1. Automated Deployment

```bash
# Make deployment script executable
chmod +x scripts/deploy.sh

# Run full deployment
./scripts/deploy.sh production
```

### 2. Manual Deployment Steps

If you prefer manual deployment:

#### Step 1: Create Namespaces
```bash
kubectl apply -f k8s/namespaces.yaml
```

#### Step 2: Deploy Infrastructure Components
```bash
# Add Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy MongoDB
helm install mongodb bitnami/mongodb \
  --namespace cloudcommerce \
  --set auth.rootPassword=cloudcommerce2024 \
  --set auth.username=cloudcommerce \
  --set auth.password=cloudcommerce2024 \
  --set auth.database=cloudcommerce_users

# Deploy PostgreSQL
helm install postgresql bitnami/postgresql \
  --namespace cloudcommerce \
  --set auth.postgresPassword=cloudcommerce2024 \
  --set auth.username=cloudcommerce \
  --set auth.password=cloudcommerce2024 \
  --set auth.database=cloudcommerce_products

# Deploy Redis
helm install redis bitnami/redis \
  --namespace cloudcommerce \
  --set auth.password=cloudcommerce2024
```

#### Step 3: Deploy Monitoring Stack
```bash
kubectl apply -f monitoring/prometheus.yaml
kubectl apply -f monitoring/grafana.yaml
```

#### Step 4: Deploy Application Services
```bash
kubectl apply -f k8s/user-service.yaml
kubectl apply -f k8s/product-service.yaml
kubectl apply -f k8s/order-service.yaml
```

### 3. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n cloudcommerce

# Check services
kubectl get svc -n cloudcommerce

# Check ingress (if configured)
kubectl get ingress -n cloudcommerce

# Verify monitoring
kubectl get pods -n monitoring
```

## Configuration

### 1. Environment Variables

Update the following secrets with your actual values:

```bash
# User Service
kubectl create secret generic user-service-secrets \
  --from-literal=mongodb-uri="mongodb://cloudcommerce:cloudcommerce2024@mongodb:27017/cloudcommerce_users" \
  --from-literal=jwt-secret="cloudcommerce-super-secret-jwt-key-2024" \
  --namespace=cloudcommerce

# Product Service
kubectl create secret generic product-service-secrets \
  --from-literal=database-url="postgresql://cloudcommerce:cloudcommerce2024@postgresql:5432/cloudcommerce_products" \
  --from-literal=redis-url="redis://:cloudcommerce2024@redis-master:6379/0" \
  --namespace=cloudcommerce

# Order Service
kubectl create secret generic order-service-secrets \
  --from-literal=database-url="postgresql://cloudcommerce:cloudcommerce2024@postgresql:5432/cloudcommerce_products" \
  --from-literal=redis-url="redis://:cloudcommerce2024@redis-master:6379/0" \
  --namespace=cloudcommerce
```

### 2. SSL/TLS Configuration

```bash
# Install cert-manager for automatic SSL certificates
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer for Let's Encrypt
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@cloudcommerce.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## Access and Testing

### 1. Port Forwarding for Local Access

```bash
# Grafana Dashboard
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# Access: http://localhost:3000 (admin/cloudcommerce2024)

# Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Access: http://localhost:9090

# User Service
kubectl port-forward svc/user-service 3001:80 -n cloudcommerce
# Access: http://localhost:3001/health

# Product Service
kubectl port-forward svc/product-service 8000:80 -n cloudcommerce
# Access: http://localhost:8000/docs

# Order Service
kubectl port-forward svc/order-service 8080:80 -n cloudcommerce
# Access: http://localhost:8080/health
```

### 2. Health Checks

```bash
# Check all service health endpoints
services=("user-service" "product-service" "order-service")

for service in "${services[@]}"; do
  echo "Checking $service..."
  kubectl port-forward svc/$service 8080:80 -n cloudcommerce &
  PF_PID=$!
  sleep 5
  curl -f http://localhost:8080/health && echo " ✅" || echo " ❌"
  kill $PF_PID
  sleep 2
done
```

### 3. Load Testing

```bash
# Install k6 for load testing
brew install k6  # macOS
# or
sudo apt-get install k6  # Ubuntu

# Run basic load test
k6 run --vus 10 --duration 30s scripts/load-test.js
```

## Monitoring and Observability

### 1. Grafana Dashboards

Access Grafana at `http://localhost:3000` after port-forwarding:

**Pre-configured Dashboards:**
- Kubernetes Cluster Overview
- Application Performance Monitoring
- Business Metrics Dashboard
- Infrastructure Monitoring

### 2. Prometheus Metrics

Key metrics to monitor:
- `http_requests_total`: Total HTTP requests
- `http_request_duration_seconds`: Request latency
- `container_cpu_usage_seconds_total`: CPU usage
- `container_memory_usage_bytes`: Memory usage

### 3. Log Aggregation

```bash
# View application logs
kubectl logs -f deployment/user-service -n cloudcommerce
kubectl logs -f deployment/product-service -n cloudcommerce
kubectl logs -f deployment/order-service -n cloudcommerce

# View logs from all pods
kubectl logs -f -l app=user-service -n cloudcommerce
```

## Scaling

### 1. Manual Scaling

```bash
# Scale specific service
kubectl scale deployment user-service --replicas=5 -n cloudcommerce

# Scale all services
kubectl scale deployment --all --replicas=3 -n cloudcommerce
```

### 2. Auto-scaling Configuration

HPA is already configured in the YAML files. Monitor scaling:

```bash
# Check HPA status
kubectl get hpa -n cloudcommerce

# Describe HPA for details
kubectl describe hpa user-service-hpa -n cloudcommerce
```

## Troubleshooting

### 1. Common Issues

**Pods not starting:**
```bash
# Check pod status
kubectl get pods -n cloudcommerce

# Describe problematic pod
kubectl describe pod <pod-name> -n cloudcommerce

# Check logs
kubectl logs <pod-name> -n cloudcommerce
```

**Service connectivity issues:**
```bash
# Test service connectivity
kubectl run test-pod --image=busybox -it --rm -- /bin/sh
# Inside pod: wget -qO- http://user-service.cloudcommerce.svc.cluster.local/health
```

**Database connection issues:**
```bash
# Check database pods
kubectl get pods -l app.kubernetes.io/name=mongodb -n cloudcommerce
kubectl get pods -l app.kubernetes.io/name=postgresql -n cloudcommerce

# Test database connectivity
kubectl exec -it <db-pod> -n cloudcommerce -- /bin/bash
```

### 2. Performance Issues

```bash
# Check resource usage
kubectl top pods -n cloudcommerce
kubectl top nodes

# Check HPA metrics
kubectl get hpa -n cloudcommerce -w

# View detailed metrics
kubectl describe hpa <hpa-name> -n cloudcommerce
```

### 3. Debugging Commands

```bash
# Get all resources in namespace
kubectl get all -n cloudcommerce

# Check events
kubectl get events -n cloudcommerce --sort-by='.lastTimestamp'

# Check resource quotas
kubectl describe quota -n cloudcommerce

# Check network policies
kubectl get networkpolicies -n cloudcommerce
```

## Backup and Recovery

### 1. Database Backups

```bash
# MongoDB backup
kubectl exec -it <mongodb-pod> -n cloudcommerce -- mongodump --out /tmp/backup

# PostgreSQL backup
kubectl exec -it <postgresql-pod> -n cloudcommerce -- pg_dump -U cloudcommerce cloudcommerce_products > backup.sql
```

### 2. Configuration Backup

```bash
# Backup all Kubernetes resources
kubectl get all -n cloudcommerce -o yaml > cloudcommerce-backup.yaml

# Backup secrets
kubectl get secrets -n cloudcommerce -o yaml > secrets-backup.yaml
```

## Security Considerations

### 1. Update Default Passwords

```bash
# Generate secure passwords
openssl rand -base64 32

# Update secrets with new passwords
kubectl create secret generic <secret-name> \
  --from-literal=password="<new-password>" \
  --namespace=cloudcommerce \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 2. Enable Network Policies

```bash
# Apply network policies for micro-segmentation
kubectl apply -f k8s/network-policies.yaml
```

### 3. Regular Security Updates

```bash
# Update container images regularly
kubectl set image deployment/user-service user-service=user-service:v1.1.0 -n cloudcommerce

# Check for vulnerabilities
trivy image user-service:latest
```
