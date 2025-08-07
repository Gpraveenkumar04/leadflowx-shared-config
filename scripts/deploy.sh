#!/bin/bash

# LeadFlowX - Complete Service Deployment Script
# This script manages all 15 microservices in the LeadFlowX architecture

set -e

echo "🚀 Starting LeadFlowX Complete Deployment..."

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "❌ Docker is not running. Please start Docker and try again."
        exit 1
    fi
    echo "✅ Docker is running"
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose >/dev/null 2>&1; then
        echo "❌ Docker Compose is not installed"
        exit 1
    fi
    echo "✅ Docker Compose is available"
}

# Function to create monitoring directories
create_monitoring_dirs() {
    echo "📁 Creating monitoring directories..."
    mkdir -p monitoring/{prometheus,grafana/{dashboards,datasources}}
    
    # Create basic Prometheus config if it doesn't exist
    if [ ! -f monitoring/prometheus/prometheus.yml ]; then
        cat > monitoring/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'ingestion-api'
    static_configs:
      - targets: ['ingestion-api:8080']

  - job_name: 'auditor'
    static_configs:
      - targets: ['auditor:8081']

  - job_name: 'config-service'
    static_configs:
      - targets: ['config-service:8082']

  - job_name: 'kafka-exporter'
    static_configs:
      - targets: ['kafka:9092']
EOF
    fi
    
    # Create basic alert rules
    if [ ! -f monitoring/prometheus/alert_rules.yml ]; then
        cat > monitoring/prometheus/alert_rules.yml << 'EOF'
groups:
  - name: leadflowx_alerts
    rules:
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.instance }} is down"

      - alert: HighKafkaLag
        expr: kafka_consumer_lag_sum > 1000
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "High Kafka consumer lag detected"
EOF
    fi
    
    echo "✅ Monitoring directories created"
}

# Function to deploy infrastructure services
deploy_infrastructure() {
    echo "🏗️  Deploying infrastructure services..."
    docker-compose up -d postgres redis zookeeper kafka
    
    echo "⏳ Waiting for infrastructure services to be healthy..."
    # Wait for postgres
    until docker-compose exec postgres pg_isready -U postgres; do
        echo "Waiting for PostgreSQL..."
        sleep 2
    done
    
    # Wait for Kafka
    echo "Waiting for Kafka to be ready..."
    sleep 30
    
    echo "✅ Infrastructure services deployed"
}

# Function to deploy core application services
deploy_core_services() {
    echo "🔧 Deploying core application services..."
    docker-compose up -d \
        ingestion-api \
        verifier \
        auditor \
        scorer \
        admin-ui \
        config-service \
        dead-letter-handler
    
    echo "✅ Core services deployed"
}

# Function to deploy scraper workers
deploy_scrapers() {
    echo "🕷️  Deploying scraper workers..."
    docker-compose up -d \
        scraper-yelp \
        scraper-etsy \
        scraper-craigslist \
        scraper-google-maps \
        scraper-yellowpages \
        scraper-linkedin \
        scraper-chamber \
        scraper-facebook \
        scraper-opendata \
        scraper-trade \
        scraper-reviews \
        scraper-whois \
        scraper-noweblist \
        scraper-classifieds
    
    echo "✅ Scraper workers deployed"
}

# Function to deploy monitoring services
deploy_monitoring() {
    echo "📊 Deploying monitoring services..."
    docker-compose up -d prometheus grafana jaeger
    echo "✅ Monitoring services deployed"
}

# Function to deploy workflow services
deploy_workflows() {
    echo "🔄 Deploying workflow services..."
    docker-compose up -d activepieces n8n qa-ui
    echo "✅ Workflow services deployed"
}

# Function to show service status
show_status() {
    echo ""
    echo "📋 Service Status:"
    echo "===================="
    docker-compose ps
    echo ""
    echo "🌐 Service URLs:"
    echo "===================="
    echo "📊 Admin UI:        http://localhost:3000"
    echo "🔄 Activepieces:    http://localhost:3001"  
    echo "👥 QA UI:           http://localhost:3002"
    echo "📈 Grafana:         http://localhost:3003 (admin/admin123)"
    echo "🔍 Jaeger:          http://localhost:16686"
    echo "🎯 Prometheus:      http://localhost:9090"
    echo "🔧 N8N:             http://localhost:5678 (admin/admin123)"
    echo "📡 Ingestion API:   http://localhost:8080"
    echo ""
    echo "🎯 Quick Health Check:"
    echo "======================"
    
    # Check key services
    services=("ingestion-api:8080/health" "auditor:8081/health")
    for service in "${services[@]}"; do
        if curl -s -f "http://localhost:${service#*:}" >/dev/null 2>&1; then
            echo "✅ ${service%:*} is healthy"
        else
            echo "❌ ${service%:*} is not responding"
        fi
    done
}

# Function to show logs for specific service
show_logs() {
    if [ -z "$1" ]; then
        echo "Usage: $0 logs <service-name>"
        echo "Available services:"
        docker-compose ps --services | sort
        return 1
    fi
    
    docker-compose logs -f --tail=100 "$1"
}

# Function to restart specific service
restart_service() {
    if [ -z "$1" ]; then
        echo "Usage: $0 restart <service-name>"
        return 1
    fi
    
    echo "🔄 Restarting $1..."
    docker-compose restart "$1"
    echo "✅ $1 restarted"
}

# Function to stop all services
stop_services() {
    echo "🛑 Stopping all LeadFlowX services..."
    docker-compose down
    echo "✅ All services stopped"
}

# Function to clean up everything
cleanup() {
    echo "🧹 Cleaning up LeadFlowX deployment..."
    docker-compose down -v --remove-orphans
    docker system prune -f
    echo "✅ Cleanup completed"
}

# Main execution logic
case "${1:-deploy}" in
    "deploy"|"start"|"up")
        check_docker
        check_docker_compose
        create_monitoring_dirs
        
        # Deploy in stages
        deploy_infrastructure
        deploy_core_services
        deploy_scrapers
        deploy_monitoring
        deploy_workflows
        
        echo ""
        echo "🎉 LeadFlowX deployment completed successfully!"
        show_status
        ;;
        
    "core")
        check_docker
        check_docker_compose
        create_monitoring_dirs
        deploy_infrastructure
        deploy_core_services
        show_status
        ;;
        
    "scrapers")
        check_docker
        check_docker_compose
        deploy_scrapers
        show_status
        ;;
        
    "monitoring")
        check_docker
        check_docker_compose
        create_monitoring_dirs
        deploy_monitoring
        show_status
        ;;
        
    "workflows")
        check_docker
        check_docker_compose
        deploy_workflows
        show_status
        ;;
        
    "status")
        show_status
        ;;
        
    "logs")
        show_logs "$2"
        ;;
        
    "restart")
        restart_service "$2"
        ;;
        
    "stop"|"down")
        stop_services
        ;;
        
    "clean"|"cleanup")
        cleanup
        ;;
        
    "help"|"--help"|"-h")
        echo "LeadFlowX Deployment Script"
        echo "Usage: $0 [command] [service-name]"
        echo ""
        echo "Commands:"
        echo "  deploy/start/up    - Deploy all services (default)"
        echo "  core              - Deploy only core services"
        echo "  scrapers          - Deploy only scraper workers" 
        echo "  monitoring        - Deploy only monitoring services"
        echo "  workflows         - Deploy only workflow services"
        echo "  status            - Show service status and URLs"
        echo "  logs <service>    - Show logs for specific service"
        echo "  restart <service> - Restart specific service"
        echo "  stop/down         - Stop all services"
        echo "  clean/cleanup     - Remove all containers, volumes, and cleanup"
        echo "  help              - Show this help"
        echo ""
        echo "Examples:"
        echo "  $0 deploy         - Deploy all services"
        echo "  $0 core           - Deploy only infrastructure + core"
        echo "  $0 logs kafka     - Show Kafka logs"
        echo "  $0 restart auditor - Restart auditor service"
        ;;
        
    *)
        echo "❌ Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
