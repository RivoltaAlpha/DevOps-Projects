#!/bin/bash

# Multi-Service Docker Application Management Script
# This script provides easy commands to manage the application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to build images
build() {
    print_info "Building Docker images..."
    docker-compose build "$@"
    print_info "Build complete!"
}

# Function to start services
start() {
    print_info "Starting services..."
    docker-compose up -d
    print_info "Services started!"
    print_info "Application available at: http://localhost"
    print_info "API health check: http://localhost/health"
}

# Function to stop services
stop() {
    print_info "Stopping services..."
    docker-compose down
    print_info "Services stopped!"
}

# Function to restart services
restart() {
    print_info "Restarting services..."
    docker-compose restart
    print_info "Services restarted!"
}

# Function to view logs
logs() {
    if [ -z "$1" ]; then
        docker-compose logs -f
    else
        docker-compose logs -f "$1"
    fi
}

# Function to show status
status() {
    print_info "Service Status:"
    docker-compose ps
    echo ""
    print_info "Health Status:"
    for service in nginx frontend backend mongodb redis; do
        health=$(docker inspect --format='{{.State.Health.Status}}' "$service" 2>/dev/null || echo "unknown")
        if [ "$health" = "healthy" ]; then
            echo -e "  $service: ${GREEN}$health${NC}"
        elif [ "$health" = "unhealthy" ]; then
            echo -e "  $service: ${RED}$health${NC}"
        else
            echo -e "  $service: ${YELLOW}$health${NC}"
        fi
    done
}

# Function to clean up
clean() {
    print_warning "This will remove all containers, networks, and images."
    print_warning "Volumes (data) will be preserved."
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Cleaning up..."
        docker-compose down --rmi all
        print_info "Cleanup complete!"
    else
        print_info "Cleanup cancelled."
    fi
}

# Function to reset everything including data
reset() {
    print_error "WARNING: This will DELETE ALL DATA including database and cache!"
    read -p "Are you absolutely sure? Type 'yes' to confirm: " -r
    echo
    if [[ $REPLY = "yes" ]]; then
        print_info "Resetting everything..."
        docker-compose down -v --rmi all
        print_info "Reset complete!"
    else
        print_info "Reset cancelled."
    fi
}

# Function to backup data
backup() {
    print_info "Backing up MongoDB data..."
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_file="mongodb-backup-${timestamp}.tar.gz"
    
    docker run --rm \
        -v multi-service-app_mongodb-data:/data \
        -v "$(pwd)":/backup \
        alpine tar czf "/backup/${backup_file}" -C /data .
    
    print_info "Backup saved to: ${backup_file}"
}

# Function to run tests
test() {
    print_info "Running application tests..."
    
    # Wait for services to be healthy
    print_info "Waiting for services to be healthy..."
    sleep 10
    
    # Test API health
    print_info "Testing API health endpoint..."
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health)
    if [ "$response" = "200" ]; then
        print_info "✓ API health check passed"
    else
        print_error "✗ API health check failed (HTTP $response)"
    fi
    
    # Test frontend
    print_info "Testing frontend..."
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/)
    if [ "$response" = "200" ]; then
        print_info "✓ Frontend check passed"
    else
        print_error "✗ Frontend check failed (HTTP $response)"
    fi
    
    print_info "Basic tests complete!"
}

# Function to show help
help() {
    cat << EOF
Multi-Service Docker Application - Management Script

Usage: ./manage.sh [command]

Commands:
  build         Build all Docker images
  start         Start all services
  stop          Stop all services
  restart       Restart all services
  logs [svc]    View logs (optional: specify service name)
  status        Show status of all services
  clean         Remove containers, networks, and images (keeps data)
  reset         DANGER: Remove everything including data volumes
  backup        Backup MongoDB data
  test          Run basic health tests
  help          Show this help message

Examples:
  ./manage.sh build          # Build all images
  ./manage.sh start          # Start all services
  ./manage.sh logs backend   # View backend logs
  ./manage.sh status         # Check service status

EOF
}

# Main script logic
check_docker

case "$1" in
    build)
        build "${@:2}"
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    logs)
        logs "$2"
        ;;
    status)
        status
        ;;
    clean)
        clean
        ;;
    reset)
        reset
        ;;
    backup)
        backup
        ;;
    test)
        test
        ;;
    help|--help|-h|"")
        help
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Run './manage.sh help' for usage information."
        exit 1
        ;;
esac
