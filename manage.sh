#!/bin/bash

# Frappe Builder Docker Management Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    color=$1
    message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_color $RED "❌ Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Frappe Builder Docker Management Script"
    echo
    echo "Usage: ./manage.sh [COMMAND]"
    echo
    echo "Commands:"
    echo "  start, up       Start all services"
    echo "  stop, down      Stop all services"
    echo "  restart         Restart all services"
    echo "  logs           Show logs from all services"
    echo "  logs-f         Follow logs from all services"
    echo "  status, ps     Show status of all services"
    echo "  clean          Stop and remove all containers and volumes (WARNING: deletes data)"
    echo "  reset          Clean and start fresh"
    echo "  bench          Access bench CLI in frappe container"
    echo "  shell          Access shell in frappe container"
    echo "  help           Show this help message"
    echo
}

# Main script logic
case "${1:-help}" in
    "start"|"up")
        check_docker
        print_color $BLUE "🚀 Starting Frappe Builder..."
        print_color $YELLOW "⚠️  First run may take 10-15 minutes to complete setup"
        docker compose up -d
        print_color $GREEN "✅ Services started! Check status with: ./manage.sh status"
        print_color $BLUE "🌐 Access your site at: http://builder.localhost:8000"
        print_color $BLUE "🔧 Builder interface: http://builder.localhost:8000/builder"
        print_color $BLUE "👨‍💻 Dev server: http://builder.localhost:8080"
        print_color $BLUE "👤 Login: Administrator / admin"
        ;;
    
    "stop"|"down")
        check_docker
        print_color $YELLOW "🛑 Stopping all services..."
        docker compose down
        print_color $GREEN "✅ All services stopped"
        ;;
    
    "restart")
        check_docker
        print_color $YELLOW "🔄 Restarting all services..."
        docker compose restart
        print_color $GREEN "✅ All services restarted"
        ;;
    
    "logs")
        check_docker
        docker compose logs
        ;;
    
    "logs-f")
        check_docker
        print_color $BLUE "📋 Following logs (Press Ctrl+C to exit)..."
        docker compose logs -f
        ;;
    
    "status"|"ps")
        check_docker
        print_color $BLUE "📊 Service Status:"
        docker compose ps
        ;;
    
    "clean")
        check_docker
        print_color $RED "⚠️  WARNING: This will delete all data!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_color $YELLOW "🧹 Cleaning up..."
            docker compose down -v
            docker system prune -a -f
            print_color $GREEN "✅ Cleanup complete"
        else
            print_color $BLUE "ℹ️  Cleanup cancelled"
        fi
        ;;
    
    "reset")
        check_docker
        print_color $RED "⚠️  WARNING: This will delete all data and start fresh!"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_color $YELLOW "🧹 Cleaning up..."
            docker compose down -v
            print_color $BLUE "🚀 Starting fresh..."
            docker compose up -d
            print_color $GREEN "✅ Reset complete"
        else
            print_color $BLUE "ℹ️  Reset cancelled"
        fi
        ;;
    
    "bench")
        check_docker
        print_color $BLUE "🔧 Accessing bench CLI..."
        docker compose exec frappe bash -c "cd frappe-bench && bash"
        ;;
    
    "shell")
        check_docker
        print_color $BLUE "🐚 Accessing container shell..."
        docker compose exec frappe bash
        ;;
    
    "help"|*)
        show_usage
        ;;
esac