#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="cloudcommerce"
SERVICE_NAME=${1:-"user-service"}
NEW_IMAGE=${2:-"user-service:latest"}
TIMEOUT=300

echo -e "${BLUE}🔄 Starting Blue-Green deployment for ${SERVICE_NAME}...${NC}"

# Get current deployment
get_current_deployment() {
    kubectl get deployment ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.metadata.name}' 2>/dev/null || echo ""
}

# Create green deployment
create_green_deployment() {
    local current_deployment=$1
    local green_deployment="${SERVICE_NAME}-green"
    
    echo -e "${YELLOW}🟢 Creating green deployment...${NC}"
    
    # Copy current deployment to green
    kubectl get deployment ${current_deployment} -n ${NAMESPACE} -o yaml | \
    sed "s/${current_deployment}/${green_deployment}/g" | \
    sed "s/image: .*/image: ${NEW_IMAGE//\//\\/}/" | \
    kubectl apply -f -
    
    # Wait for green deployment to be ready
    echo -e "${YELLOW}⏳ Waiting for green deployment to be ready...${NC}"
    kubectl wait --for=condition=available --timeout=${TIMEOUT}s deployment/${green_deployment} -n ${NAMESPACE}
    
    echo -e "${GREEN}✅ Green deployment is ready${NC}"
    echo ${green_deployment}
}

# Run health checks on green deployment
health_check_green() {
    local green_deployment=$1
    local green_pod=$(kubectl get pods -n ${NAMESPACE} -l app=${SERVICE_NAME} -l version=green -o jsonpath='{.items[0].metadata.name}')
    
    echo -e "${YELLOW}🏥 Running health checks on green deployment...${NC}"
    
    # Port forward to green pod
    kubectl port-forward ${green_pod} 8080:3001 -n ${NAMESPACE} &
    PF_PID=$!
    sleep 10
    
    # Run health check
    local health_status=0
    for i in {1..5}; do
        if curl -f http://localhost:8080/health > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Health check ${i}/5 passed${NC}"
        else
            echo -e "${RED}❌ Health check ${i}/5 failed${NC}"
            health_status=1
        fi
        sleep 2
    done
    
    # Kill port forward
    kill $PF_PID 2>/dev/null || true
    
    if [ $health_status -eq 0 ]; then
        echo -e "${GREEN}✅ All health checks passed${NC}"
        return 0
    else
        echo -e "${RED}❌ Health checks failed${NC}"
        return 1
    fi
}

# Switch traffic to green
switch_to_green() {
    local current_deployment=$1
    local green_deployment=$2
    
    echo -e "${YELLOW}🔄 Switching traffic to green deployment...${NC}"
    
    # Update service selector to point to green deployment
    kubectl patch service ${SERVICE_NAME} -n ${NAMESPACE} -p '{"spec":{"selector":{"version":"green"}}}'
    
    # Label green pods
    kubectl patch deployment ${green_deployment} -n ${NAMESPACE} -p '{"spec":{"template":{"metadata":{"labels":{"version":"green"}}}}}'
    
    # Wait a bit for traffic to switch
    sleep 10
    
    echo -e "${GREEN}✅ Traffic switched to green deployment${NC}"
}

# Run smoke tests
run_smoke_tests() {
    echo -e "${YELLOW}🧪 Running smoke tests...${NC}"
    
    # Port forward to service
    kubectl port-forward svc/${SERVICE_NAME} 8080:80 -n ${NAMESPACE} &
    PF_PID=$!
    sleep 5
    
    # Run basic smoke tests
    local test_status=0
    
    # Test health endpoint
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Health endpoint test passed${NC}"
    else
        echo -e "${RED}❌ Health endpoint test failed${NC}"
        test_status=1
    fi
    
    # Test API endpoints (if applicable)
    if [[ ${SERVICE_NAME} == "user-service" ]]; then
        if curl -f http://localhost:8080/api/users > /dev/null 2>&1; then
            echo -e "${GREEN}✅ API endpoint test passed${NC}"
        else
            echo -e "${RED}❌ API endpoint test failed${NC}"
            test_status=1
        fi
    fi
    
    # Kill port forward
    kill $PF_PID 2>/dev/null || true
    
    return $test_status
}

# Cleanup old deployment
cleanup_blue() {
    local blue_deployment=$1
    
    echo -e "${YELLOW}🧹 Cleaning up blue deployment...${NC}"
    
    # Scale down blue deployment
    kubectl scale deployment ${blue_deployment} --replicas=0 -n ${NAMESPACE}
    
    # Wait a bit
    sleep 30
    
    # Delete blue deployment
    kubectl delete deployment ${blue_deployment} -n ${NAMESPACE}
    
    echo -e "${GREEN}✅ Blue deployment cleaned up${NC}"
}

# Rollback to blue
rollback_to_blue() {
    local blue_deployment=$1
    local green_deployment=$2
    
    echo -e "${RED}🔙 Rolling back to blue deployment...${NC}"
    
    # Switch service back to blue
    kubectl patch service ${SERVICE_NAME} -n ${NAMESPACE} -p '{"spec":{"selector":{"version":"blue"}}}'
    
    # Scale down green deployment
    kubectl scale deployment ${green_deployment} --replicas=0 -n ${NAMESPACE}
    
    # Delete green deployment
    kubectl delete deployment ${green_deployment} -n ${NAMESPACE}
    
    echo -e "${RED}❌ Rollback completed${NC}"
    exit 1
}

# Main execution
main() {
    local current_deployment=$(get_current_deployment)
    
    if [ -z "$current_deployment" ]; then
        echo -e "${RED}❌ No current deployment found for ${SERVICE_NAME}${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}📋 Current deployment: ${current_deployment}${NC}"
    
    # Label current deployment as blue
    kubectl patch deployment ${current_deployment} -n ${NAMESPACE} -p '{"spec":{"template":{"metadata":{"labels":{"version":"blue"}}}}}'
    kubectl patch service ${SERVICE_NAME} -n ${NAMESPACE} -p '{"spec":{"selector":{"version":"blue"}}}'
    
    # Create green deployment
    local green_deployment=$(create_green_deployment ${current_deployment})
    
    # Health check green deployment
    if ! health_check_green ${green_deployment}; then
        echo -e "${RED}❌ Green deployment health checks failed, cleaning up...${NC}"
        kubectl delete deployment ${green_deployment} -n ${NAMESPACE}
        exit 1
    fi
    
    # Switch traffic to green
    switch_to_green ${current_deployment} ${green_deployment}
    
    # Run smoke tests
    if ! run_smoke_tests; then
        echo -e "${RED}❌ Smoke tests failed, rolling back...${NC}"
        rollback_to_blue ${current_deployment} ${green_deployment}
    fi
    
    # Cleanup blue deployment
    cleanup_blue ${current_deployment}
    
    # Rename green deployment to original name
    kubectl patch deployment ${green_deployment} -n ${NAMESPACE} -p "{\"metadata\":{\"name\":\"${SERVICE_NAME}\"}}"
    
    echo -e "${GREEN}🎉 Blue-Green deployment completed successfully!${NC}"
}

# Check if running directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi