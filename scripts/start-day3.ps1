#!/usr/bin/env pwsh

# LeadFlowX Day 3 - Start All Services
# Optimized startup sequence for Day 3 architecture

Write-Host "🚀 Starting LeadFlowX Day 3 Services..." -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan

# Function to wait for service health
function Wait-ForService {
    param(
        [string]$ServiceName,
        [string]$HealthUrl,
        [int]$MaxAttempts = 30,
        [int]$DelaySeconds = 5
    )
    
    Write-Host "⏳ Waiting for $ServiceName to be healthy..." -ForegroundColor Yellow
    
    for ($i = 1; $i -le $MaxAttempts; $i++) {
        try {
            $response = Invoke-RestMethod -Uri $HealthUrl -TimeoutSec 3 -ErrorAction Stop
            Write-Host "✅ $ServiceName is healthy!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Attempt $i/$MaxAttempts - $ServiceName not ready yet..." -ForegroundColor Gray
            Start-Sleep $DelaySeconds
        }
    }
    
    Write-Host "❌ $ServiceName failed to become healthy" -ForegroundColor Red
    return $false
}

# Step 1: Start core infrastructure
Write-Host "`n📦 Starting Core Infrastructure..." -ForegroundColor Magenta
docker compose -f docker-compose.dev.yml up -d postgres redis zookeeper

# Step 2: Start Kafka
Write-Host "`n📡 Starting Kafka..." -ForegroundColor Magenta
docker compose -f docker-compose.dev.yml up -d kafka

# Wait for Kafka to be healthy
Write-Host "⏳ Waiting for Kafka to be ready (this may take 2-3 minutes)..."
Start-Sleep 30
$kafkaAttempts = 0
do {
    $kafkaAttempts++
    $kafkaStatus = docker compose -f docker-compose.dev.yml ps kafka --format json | ConvertFrom-Json
    if ($kafkaStatus.Health -eq "healthy") {
        Write-Host "✅ Kafka is healthy!" -ForegroundColor Green
        break
    }
    Write-Host "⏳ Kafka health check attempt $kafkaAttempts/20..." -ForegroundColor Gray
    Start-Sleep 10
} while ($kafkaAttempts -lt 20)

# Step 3: Initialize Kafka topics
Write-Host "`n🔧 Initializing Kafka Topics..." -ForegroundColor Magenta
docker compose -f docker-compose.dev.yml up kafka-init

# Step 4: Start application services
Write-Host "`n🏗️ Starting Application Services..." -ForegroundColor Magenta
docker compose -f docker-compose.dev.yml up -d ingestion-api verifier

# Wait for ingestion API
Wait-ForService "Ingestion API" "http://localhost:8080/health"

# Step 5: Start Day 3 services
Write-Host "`n🎯 Starting Day 3 Services..." -ForegroundColor Magenta
docker compose -f docker-compose.dev.yml up -d auditor scorer qa-ui

# Wait for auditor service
Wait-ForService "Auditor Service" "http://localhost:8081/health"

# Step 6: Start UI services
Write-Host "`n🖥️ Starting UI Services..." -ForegroundColor Magenta
docker compose -f docker-compose.dev.yml up -d admin-ui activepieces n8n

# Final status check
Write-Host "`n📊 Final Service Status:" -ForegroundColor Magenta
docker compose -f docker-compose.dev.yml ps

Write-Host "`n🎉 Day 3 Services Started Successfully!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host "`n🌐 Available Services:" -ForegroundColor White
Write-Host "  Admin UI:        http://localhost:3000" -ForegroundColor Cyan
Write-Host "  QA Dashboard:    http://localhost:3002/qa" -ForegroundColor Cyan
Write-Host "  Ingestion API:   http://localhost:8080/health" -ForegroundColor Cyan
Write-Host "  Auditor Health:  http://localhost:8081/health" -ForegroundColor Cyan
Write-Host "  Auditor Metrics: http://localhost:8081/metrics" -ForegroundColor Cyan
Write-Host "  n8n:             http://localhost:5678 (admin/admin123)" -ForegroundColor Cyan

Write-Host "`n⚠️  Optional Services (may require configuration):" -ForegroundColor Yellow
Write-Host "  Verifier Metrics:http://localhost:9090/metrics" -ForegroundColor Gray
Write-Host "  Activepieces:    http://localhost:3001" -ForegroundColor Gray

Write-Host "`n📝 API Usage Notes:" -ForegroundColor Yellow
Write-Host "  • Ingestion API requires: Authorization: Bearer leadflowx-api-key-2025" -ForegroundColor Gray
Write-Host "  • QA Dashboard main page: /qa route" -ForegroundColor Gray
Write-Host "  • For API testing use: curl with proper auth header" -ForegroundColor Gray

Write-Host "`n🧪 Run validation:" -ForegroundColor White
Write-Host "  .\validation\validate-leadflowx.ps1" -ForegroundColor Gray

Write-Host "`n🔧 Quick Tests:" -ForegroundColor White
Write-Host "  .\test-ingestion-api.ps1" -ForegroundColor Gray
Write-Host "  curl http://localhost:8080/health" -ForegroundColor Gray
Write-Host "  curl http://localhost:8081/health" -ForegroundColor Gray
