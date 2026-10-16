<#
.SYNOPSIS
    OSINT Platform MVP - Docker Initialization and Startup Script

.DESCRIPTION
    Initializes the local environment (.env), starts MySQL, OpenLDAP, and Keycloak,
    and displays service endpoints and credentials.
#>

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  OSINT Platform MVP - Starting Docker Infrastructure    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Check: .env file existence
if (-not (Test-Path ".env")) {
    Write-Host "[INFO] .env not found, copying from .env.example..." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
    Write-Host "[OK] .env successfully created." -ForegroundColor Green
} else {
    Write-Host "[OK] .env file found." -ForegroundColor Green
}

# 2. Check: Docker daemon running
Write-Host "[INFO] Checking Docker connection..." -ForegroundColor Yellow
try {
    $null = docker info 2>&1
    Write-Host "[OK] Docker is running and accessible." -ForegroundColor Green
} catch {
    Write-Error "[ERROR] Docker daemon is not accessible! Please start Docker Desktop."
    exit 1
}

# 3. Start containers
Write-Host "`n[INFO] Starting infrastructure containers (docker compose up -d)..." -ForegroundColor Yellow
docker compose up -d

# 4. Container status
Write-Host "`n[INFO] Container status:" -ForegroundColor Yellow
docker compose ps

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  Infrastructure Services and Connection Details         " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Keycloak Admin Console:  http://localhost:8080" -ForegroundColor White
Write-Host "  - Username:            admin" -ForegroundColor Gray
Write-Host "  - Password:            admin_password_dev" -ForegroundColor Gray
Write-Host "Keycloak OSINT Realm:    http://localhost:8080/realms/osint-realm" -ForegroundColor White
Write-Host ""
Write-Host "Test OIDC / LDAP Users (for Keycloak OIDC login):" -ForegroundColor Cyan
Write-Host "  1. Administrator:      admin_user / AdminPassword123!   (Role: admin)" -ForegroundColor White
Write-Host "  2. Viewer:             viewer_user / ViewerPassword123! (Role: viewer)" -ForegroundColor White
Write-Host "  3. Local fallback:     local_admin / LocalAdmin123!     (Role: admin)" -ForegroundColor Gray
Write-Host ""
Write-Host "MySQL Database:          localhost:3306" -ForegroundColor White
Write-Host "  - Username:            osint_user" -ForegroundColor Gray
Write-Host "  - Password:            osint_db_password_dev" -ForegroundColor Gray
Write-Host "  - Application DB:      osint_db (for EF Core / Backend)" -ForegroundColor Gray
Write-Host "  - Keycloak DB:         keycloak_db" -ForegroundColor Gray
Write-Host "==========================================================" -ForegroundColor Cyan
