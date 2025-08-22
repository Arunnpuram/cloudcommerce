#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE=${1:-"cloudcommerce"}
TIMEOUT=30

echo -e "${BLUE}🏥 CloudCommerce Health Check Report${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# Function to check service health
check_service_health() {
    local service_name=$1
    local port=$2
    local health_endpoint=${3:-"/health"}
    
    echo -e "${YELLOW}Checking ${service_name}...${NC}"
    
    # Port forward to service
    kubectl port-forward svc/${service_name} ${port}:80 -n ${NAMESPACE} >/dev/null 2>&1 &
    PF_PID=$!
    
    # Wait for port forward to establish
    sleep 3
    
    # Check health endpoint
    local status_code
    local response
    
    if command -v curl >/dev/null 2>&1; then
        status_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:${port}${health_endpoint} 2>/dev/null || echo "000")
        response=$(curl -s http://localhost:${port}${health_endpoint} 2>/dev/null || echo "Connection failed")
    else
        echo -e "${RED}❌ curl not found, skipping HTTP check${NC}"
        kill $PF_PID 2>/dev/null || true
        return 1
    fi
    
    # Kill port forward
    kill $PF_PID 2>/dev/null || true
    sleep 1
    
    # Evaluate health
    if [[ "$status_code" == "200" ]]; then
        echo -e "${GREEN}✅ ${service_name} is healthy (HTTP $status_code)${NC}"
        echo -e "   Response: $(echo $response | jq -r '.status // .message // .' 2>/dev/null || echo $response | head -c 100)"
        return 0
    else
        echo -e "${RED}❌ ${service_name} is unhealthy (HTTP $status_code)${NC}"
        echo -e "   Response: $(echo $response | head -c 100)"
        return 1
    fi
}

# Function to check pod status
check_pod_status() {
    local service_name=$1
    
    echo -e "${YELLOW}Checking ${service_name} pods...${NC}"
    
    local pods=$(kubectl get pods -n ${NAMESPACE} -l app=${service_name} -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    
    if [[ -z "$pods" ]]; then
        echo -e "${RED}❌ No pods found for ${service_name}${NC}"
        return 1
    fi
    
    local healthy_pods=0
    local total_pods=0
    
    for pod in $pods; do
        total_pods=$((total_pods + 1))
        local status=$(kubectl get pod $pod -n ${NAMESPACE} -o jsonpath='{.status.phase}' 2>/dev/null)
        local ready=$(kubectl get pod $pod -n ${NAMESPACE} -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
        
        if [[ "$status" == "Running" && "$ready" == "True" ]]; then
            healthy_pods=$((healthy_pods + 1))
            echo -e "   ✅ $pod: Running and Ready"
        else
            echo -e "   ❌ $pod: $status (Ready: $ready)"
        fi
    done
    
    echo -e "   📊 Healthy pods: $healthy_pods/$total_pods"
    
    if [[ $healthy_pods -eq $total_pods && $total_pods -gt 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Function to check service endpoints
check_service_endpoints() {
    local service_name=$1
    
    echo -e "${YELLOW}Checking ${service_name} endpoints...${NC}"
    
    local endpoints=$(kubectl get endpoints ${service_name} -n ${NAMESPACE} -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null)
    
    if [[ -z "$endpoints" ]]; then
        echo -e "${RED}❌ No endpoints found for ${service_name}${NC}"
        return 1
    else
        local endpoint_count=$(echo $endpoints | wc -w)
        echo -e "${GREEN}✅ ${service_name} has $endpoint_count endpoint(s)${NC}"
        echo -e "   Endpoints: $endpoints"
        return 0
    fi
}

# Function to check database connectivity
check_database_connectivity() {
    echo -e "${YELLOW}Checking database connectivity...${NC}"
    
    # Check MongoDB
    local mongodb_pod=$(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=mongodb -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [[ -n "$mongodb_pod" ]]; then
        if kubectl exec $mongodb_pod -n ${NAMESPACE} -- mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ MongoDB is accessible${NC}"
        else
            echo -e "${RED}❌ MongoDB connection failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ MongoDB pod not found${NC}"
    fi
    
    # Check PostgreSQL
    local postgres_pod=$(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=postgresql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [[ -n "$postgres_pod" ]]; then
        if kubectl exec $postgres_pod -n ${NAMESPACE} -- pg_isready >/dev/null 2>&1; then
            echo -e "${GREEN}✅ PostgreSQL is accessible${NC}"
        else
            echo -e "${RED}❌ PostgreSQL connection failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ PostgreSQL pod not found${NC}"
    fi
    
    # Check Redis
    local redis_pod=$(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=redis -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [[ -n "$redis_pod" ]]; then
        if kubectl exec $redis_pod -n ${NAMESPACE} -- redis-cli ping >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Redis is accessible${NC}"
        else
            echo -e "${RED}❌ Redis connection failed${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ Redis pod not found${NC}"
    fi
}

# Function to check resource usage
check_resource_usage() {
    echo -e "${YELLOW}Checking resource usage...${NC}"
    
    # Check if metrics-server is available
    if kubectl top nodes >/dev/null 2>&1; then
        echo -e "${GREEN}📊 Node Resource Usage:${NC}"
        kubectl top nodes
        echo ""
        
        echo -e "${GREEN}📊 Pod Resource Usage (${NAMESPACE}):${NC}"
        kubectl top pods -n ${NAMESPACE} 2>/dev/null || echo -e "${YELLOW}⚠️ Pod metrics not available${NC}"
    else
        echo -e "${YELLOW}⚠️ Metrics server not available, skipping resource usage check${NC}"
    fi
}

# Function to check HPA status
check_hpa_status() {
    echo -e "${YELLOW}Checking HPA status...${NC}"
    
    local hpas=$(kubectl get hpa -n ${NAMESPACE} -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)
    
    if [[ -n "$hpas" ]]; then
        for hpa in $hpas; do
            local current_replicas=$(kubectl get hpa $hpa -n ${NAMESPACE} -o jsonpath='{.status.currentReplicas}' 2>/dev/null)
            local desired_replicas=$(kubectl get hpa $hpa -n ${NAMESPACE} -o jsonpath='{.status.desiredReplicas}' 2>/dev/null)
            local target_cpu=$(kubectl get hpa $hpa -n ${NAMESPACE} -o jsonpath='{.spec.targetCPUUtilizationPercentage}' 2>/dev/null)
            
            echo -e "   📈 $hpa: $current_replicas/$desired_replicas replicas (Target CPU: ${target_cpu}%)"
        done
    else
        echo -e "${YELLOW}⚠️ No HPA found${NC}"
    fi
}

# Main health check execution
main() {
    local overall_status=0
    
    echo -e "${BLUE}🔍 Checking Kubernetes cluster connectivity...${NC}"
    if kubectl cluster-info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Kubernetes cluster is accessible${NC}"
    else
        echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
    echo ""
    
    # Check namespace
    echo -e "${BLUE}📦 Checking namespace: ${NAMESPACE}${NC}"
    if kubectl get namespace ${NAMESPACE} >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Namespace ${NAMESPACE} exists${NC}"
    else
        echo -e "${RED}❌ Namespace ${NAMESPACE} not found${NC}"
        exit 1
    fi
    echo ""
    
    # Define services to check
    services=("user-service:3001" "product-service:8000" "order-service:8080")
    
    # Check each service
    for service_info in "${services[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        
        echo -e "${BLUE}🔍 Checking ${service_name}${NC}"
        echo "----------------------------------------"
        
        # Check pod status
        if ! check_pod_status "$service_name"; then
            overall_status=1
        fi
        
        # Check service endpoints
        if ! check_service_endpoints "$service_name"; then
            overall_status=1
        fi
        
        # Check service health endpoint
        if ! check_service_health "$service_name" "$port"; then
            overall_status=1
        fi
        
        echo ""
    done
    
    # Check database connectivity
    echo -e "${BLUE}🗄️ Database Connectivity${NC}"
    echo "----------------------------------------"
    check_database_connectivity
    echo ""
    
    # Check resource usage
    echo -e "${BLUE}📊 Resource Usage${NC}"
    echo "----------------------------------------"
    check_resource_usage
    echo ""
    
    # Check HPA status
    echo -e "${BLUE}📈 Auto-scaling Status${NC}"
    echo "----------------------------------------"
    check_hpa_status
    echo ""
    
    # Final report
    echo -e "${BLUE}📋 CloudCommerce Health Check Summary${NC}"
    echo "========================================"
    
    if [[ $overall_status -eq 0 ]]; then
        echo -e "${GREEN}🎉 All services are healthy!${NC}"
        echo -e "${GREEN}✅ CloudCommerce is ready for traffic${NC}"
    else
        echo -e "${RED}⚠️ Some services have issues${NC}"
        echo -e "${RED}❌ Please check the details above${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}🔗 Quick Access Commands:${NC}"
    echo "  Grafana:    kubectl port-forward svc/grafana 3000:3000 -n monitoring"
    echo "  Prometheus: kubectl port-forward svc/prometheus 9090:9090 -n monitoring"
    echo "  Logs:       kubectl logs -f -l app=user-service -n ${NAMESPACE}"
    
    exit $overall_status
}

# Run main function
main "$@"