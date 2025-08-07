#!/usr/bin/env pwsh

# Test script for LeadFlowX Ingestion API

Write-Host "🧪 Testing LeadFlowX Ingestion API..." -ForegroundColor Cyan

# Test 1: Health Check
Write-Host "`n1️⃣ Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -TimeoutSec 5
    Write-Host "✅ Health Check: $($healthResponse.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: API Authentication Test
Write-Host "`n2️⃣ Testing API Endpoint with Authentication..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer leadflowx-api-key-2025"
        "Content-Type" = "application/json"
    }
    
    $testLead = @{
        name = "Test User"
        company = "Test Corp"
        email = "test@example.com" 
        website = "https://example.com"
        phone = "+1234567890"
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri "http://localhost:8080/v1/lead" -Method POST -Headers $headers -Body $testLead -TimeoutSec 10
    Write-Host "✅ Lead Created Successfully" -ForegroundColor Green
    Write-Host "   Lead ID: $($response.id)" -ForegroundColor Cyan
    Write-Host "   Status: $($response.status)" -ForegroundColor Cyan
} catch {
    if ($_.Exception.Message -like "*409*" -or $_.Exception.Message -like "*Duplicate*") {
        Write-Host "✅ API Working (Lead already exists)" -ForegroundColor Green
    } else {
        Write-Host "❌ Lead Creation Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 3: Without Authentication (should fail)
Write-Host "`n3️⃣ Testing API without Authentication (should fail)..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/v1/lead" -Method GET -TimeoutSec 5
    Write-Host "❌ Unexpected Success - API should require authentication" -ForegroundColor Red
} catch {
    if ($_.Exception.Message -like "*Missing or invalid authorization header*" -or $_.Exception.Message -like "*401*" -or $_.Exception.Message -like "*403*") {
        Write-Host "✅ Authentication Required (as expected)" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Unexpected Error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "`n🎯 API Testing Complete!" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
