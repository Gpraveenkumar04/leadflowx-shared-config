#!/usr/bin/env pwsh

# LeadFlowX Quick Startup Script
# One-command startup for when you come back to your PC

Write-Host "🚀 LeadFlowX Quick Startup" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Just call the main validation script with startup mode
.\validate.ps1 -Startup

Write-Host "`n🎯 System is ready for development!" -ForegroundColor Green
Write-Host "💡 Use '.\validate.ps1 -Shutdown' when you're done." -ForegroundColor Gray
