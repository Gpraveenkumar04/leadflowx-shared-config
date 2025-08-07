#!/usr/bin/env pwsh

# LeadFlowX Quick Shutdown Script
# Gracefully stop all services

Write-Host "🛑 LeadFlowX Quick Shutdown" -ForegroundColor Yellow
Write-Host "===========================" -ForegroundColor Yellow
Write-Host ""

# Just call the main validation script with shutdown mode
.\validate.ps1 -Shutdown

Write-Host "`n💤 System shutdown complete. Safe to close your PC!" -ForegroundColor Green
