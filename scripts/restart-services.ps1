#!/usr/bin/env powershell

# LeadFlowX Service Restart Script
# This script stops all services, cleans up, and restarts them

Write-Host "=== LeadFlowX Service Restart ===" -ForegroundColor Cyan

# Stop all running services
Write-Host "Stopping all services..." -ForegroundColor Yellow
docker-compose -f docker-compose.dev.yml down --remove-orphans

# Clean up orphaned containers and networks
Write-Host "Cleaning up Docker resources..." -ForegroundColor Yellow
docker container prune -f
docker network prune -f
docker volume prune -f

# Verify environment file exists
if (!(Test-Path ".env")) {
    Write-Host "Warning: .env file not found. Using .env.example as template..." -ForegroundColor Red
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" ".env"
        Write-Host "Please edit .env file with your actual API keys and configuration" -ForegroundColor Yellow
    } else {
        Write-Host "Error: No .env.example found. Please create .env manually." -ForegroundColor Red
        exit 1
    }
}

# Check for required environment variables
$env_content = Get-Content .env -ErrorAction SilentlyContinue
$required_vars = @("CAPSOLVER_KEY", "GOOGLE_API_KEY", "PAGESPEED_API_KEY")

foreach ($var in $required_vars) {
    if (-not ($env_content | Select-String -Pattern "^$var=")) {
        Write-Host "Warning: $var not set in .env file" -ForegroundColor Yellow
    }
}

# Build and start services
Write-Host "Building and starting services..." -ForegroundColor Green
docker-compose -f docker-compose.dev.yml up -d --build

Write-Host "`nServices starting up..." -ForegroundColor Green
Write-Host "This may take a few minutes for all services to be ready." -ForegroundColor Yellow

Write-Host "`n=== Service Status Check ===" -ForegroundColor Cyan
Start-Sleep -Seconds 10

# Check service health
$services = @(
    @{Name="PostgreSQL"; Port=5432; Host="localhost"}
    @{Name="Kafka"; Port=9092; Host="localhost"}
    @{Name="Ingestion API"; Port=8080; Host="localhost"}
    @{Name="Scraper API"; Port=8000; Host="localhost"}
    @{Name="Auditor"; Port=8081; Host="localhost"}
    @{Name="QA UI"; Port=3002; Host="localhost"}
    @{Name="Admin UI"; Port=3000; Host="localhost"}
)

Write-Host "`nChecking service availability:" -ForegroundColor Green
foreach ($service in $services) {
    try {
        $connection = Test-NetConnection -ComputerName $service.Host -Port $service.Port -WarningAction SilentlyContinue -InformationLevel Quiet
        if ($connection.TcpTestSucceeded) {
            Write-Host "  ✓ $($service.Name) - Port $($service.Port)" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $($service.Name) - Port $($service.Port) (Starting...)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ✗ $($service.Name) - Port $($service.Port) (Error)" -ForegroundColor Red
    }
}

Write-Host "`n=== Access URLs ===" -ForegroundColor Cyan
Write-Host "  • Ingestion API:     http://localhost:8080" -ForegroundColor White
Write-Host "  • Scraper API:       http://localhost:8000" -ForegroundColor White
Write-Host "  • QA UI:             http://localhost:3002" -ForegroundColor White
Write-Host "  • Admin UI:          http://localhost:3000" -ForegroundColor White
Write-Host "  • N8N Automation:    http://localhost:5678 (admin/admin123)" -ForegroundColor White
Write-Host "  • ActivePieces:      http://localhost:3001" -ForegroundColor White
Write-Host "  • LeadFlowX UI:      http://localhost:3003 (when started)" -ForegroundColor White

Write-Host "`n=== Logs ===" -ForegroundColor Cyan
Write-Host "To view logs: docker-compose -f docker-compose.dev.yml logs -f [service-name]" -ForegroundColor White
Write-Host "To view all logs: docker-compose -f docker-compose.dev.yml logs -f" -ForegroundColor White

Write-Host "`nServices are starting up. Please wait a few minutes for all health checks to pass." -ForegroundColor Green
