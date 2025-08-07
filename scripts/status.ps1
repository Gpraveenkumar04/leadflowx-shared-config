#!/usr/bin/env powershell

# LeadFlowX Service Status Checker

Write-Host "=== LeadFlowX Service Status ===" -ForegroundColor Cyan

# Check Docker status
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "Error: Docker is not running" -ForegroundColor Red
    exit 1
}

# Get container status
Write-Host "`nContainer Status:" -ForegroundColor Green
docker-compose -f docker-compose.dev.yml ps

Write-Host "`n=== Health Status ===" -ForegroundColor Cyan
$containers = docker-compose -f docker-compose.dev.yml ps --format json | ConvertFrom-Json

foreach ($container in $containers) {
    if ($container.Health) {
        $health_color = switch ($container.Health) {
            "healthy" { "Green" }
            "unhealthy" { "Red" }
            "starting" { "Yellow" }
            default { "Gray" }
        }
        Write-Host "  $($container.Service): $($container.Health)" -ForegroundColor $health_color
    } else {
        Write-Host "  $($container.Service): $($container.State)" -ForegroundColor Gray
    }
}

Write-Host "`n=== Resource Usage ===" -ForegroundColor Cyan
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" | Where-Object { $_ -match "leadflowx" -or $_ -match "CONTAINER" }
