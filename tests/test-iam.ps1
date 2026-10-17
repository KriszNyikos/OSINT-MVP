<#
.SYNOPSIS
    OSINT Platform MVP - IAM & Infrastructure Automated Test Suite (PowerShell)

.DESCRIPTION
    Validates Docker container health, Keycloak OIDC discovery, OpenLDAP user authentication,
    role assignments (admin/viewer), fallback accounts, and invalid credentials rejection.
#>

$ErrorActionPreference = "Stop"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "  OSINT Platform MVP - IAM & Docker Integration Tests    " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$TotalTests = 0
$PassedTests = 0
$FailedTests = 0

function Assert-Test {
    param(
        [string]$Name,
        [scriptblock]$TestBlock
    )
    $script:TotalTests++
    Write-Host "`n[TEST $script:TotalTests] $Name..." -ForegroundColor Yellow
    try {
        $result = & $TestBlock
        if ($result -eq $false) {
            throw "Assertion evaluated to false."
        }
        $script:PassedTests++
        Write-Host "  -> PASS: $Name" -ForegroundColor Green
    } catch {
        $script:FailedTests++
        Write-Host "  -> FAIL: $Name" -ForegroundColor Red
        Write-Host "     Error: $($_.Exception.Message)" -ForegroundColor DarkRed
    }
}

# ------------------------------------------------------------------------------
# Test 1: Container Health Check
# ------------------------------------------------------------------------------
Assert-Test "Docker Containers Health Status" {
    $containers = @("osint-mysql", "osint-openldap", "osint-keycloak")
    foreach ($c in $containers) {
        $status = (docker inspect -f '{{.State.Health.Status}}' $c 2>&1).Trim()
        if ($status -ne "healthy") {
            throw "Container $c is not healthy! Current status: $status"
        }
    }
    return $true
}

# ------------------------------------------------------------------------------
# Test 2: OIDC Discovery Endpoint
# ------------------------------------------------------------------------------
Assert-Test "Keycloak OIDC Discovery Endpoint (.well-known)" {
    $discovery = Invoke-RestMethod -Uri "http://localhost:8080/realms/osint-realm/.well-known/openid-configuration" -Method Get
    if ($discovery.issuer -ne "http://localhost:8080/realms/osint-realm") {
        throw "Invalid issuer: $($discovery.issuer)"
    }
    if (-not $discovery.token_endpoint) {
        throw "Missing token_endpoint!"
    }
    if (-not $discovery.jwks_uri) {
        throw "Missing jwks_uri!"
    }
    return $true
}

# ------------------------------------------------------------------------------
# Test 3: OpenLDAP Admin Authentication & Role Assignment
# ------------------------------------------------------------------------------
Assert-Test "OpenLDAP admin_user login & 'admin' role assignment" {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" -Method Post -Body @{
        grant_type = "password"
        client_id  = "osint-frontend"
        username   = "admin_user"
        password   = "AdminPassword123!"
    }
    if (-not $response.access_token) {
        throw "No access_token received in response!"
    }

    $tokenParts = $response.access_token.Split(".")
    $payloadJson = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($tokenParts[1].PadRight(4 * [math]::Ceiling($tokenParts[1].Length / 4), '=')))
    $payload = $payloadJson | ConvertFrom-Json

    if ($payload.preferred_username -ne "admin_user") {
        throw "preferred_username mismatch: $($payload.preferred_username)"
    }
    if ($payload.realm_access.roles -notcontains "admin") {
        throw "Token does not contain 'admin' role! Roles found: $($payload.realm_access.roles -join ', ')"
    }
    return $true
}

# ------------------------------------------------------------------------------
# Test 4: OpenLDAP Viewer Authentication & Role Restriction
# ------------------------------------------------------------------------------
Assert-Test "OpenLDAP viewer_user login & 'viewer' role restriction" {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" -Method Post -Body @{
        grant_type = "password"
        client_id  = "osint-frontend"
        username   = "viewer_user"
        password   = "ViewerPassword123!"
    }
    if (-not $response.access_token) {
        throw "No access_token received in response!"
    }

    $tokenParts = $response.access_token.Split(".")
    $payloadJson = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($tokenParts[1].PadRight(4 * [math]::Ceiling($tokenParts[1].Length / 4), '=')))
    $payload = $payloadJson | ConvertFrom-Json

    if ($payload.realm_access.roles -notcontains "viewer") {
        throw "Token does not contain 'viewer' role!"
    }
    if ($payload.realm_access.roles -contains "admin") {
        throw "Security failure: viewer user received 'admin' role!"
    }
    return $true
}

# ------------------------------------------------------------------------------
# Test 5: Fallback Local Admin Authentication
# ------------------------------------------------------------------------------
Assert-Test "Fallback local_admin authentication" {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" -Method Post -Body @{
        grant_type = "password"
        client_id  = "osint-frontend"
        username   = "local_admin"
        password   = "LocalAdmin123!"
    }
    if (-not $response.access_token) {
        throw "local_admin failed to acquire access_token!"
    }
    return $true
}

# ------------------------------------------------------------------------------
# Test 6: Security - Invalid Credentials Rejection (401)
# ------------------------------------------------------------------------------
Assert-Test "Security: Rejection of invalid credentials (401 Unauthorized)" {
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" -Method Post -Body @{
            grant_type = "password"
            client_id  = "osint-frontend"
            username   = "admin_user"
            password   = "WrongPassword999!"
        }
        throw "Request succeeded with wrong password, security check failed!"
    } catch {
        $statusCode = [int]$_.Exception.Response.StatusCode
        if ($statusCode -ne 401) {
            throw "Expected status code 401, but received: $statusCode"
        }
    }
    return $true
}

# ------------------------------------------------------------------------------
# Test 7: MySQL Databases Verification
# ------------------------------------------------------------------------------
Assert-Test "MySQL Database availability (osint_db and keycloak_db)" {
    $output = docker exec -e MYSQL_PWD=osint_db_password_dev osint-mysql mysql -u osint_user -e "SHOW DATABASES;"
    $dbs = $output -join " "
    if ($dbs -notmatch "osint_db") {
        throw "osint_db was not found in MySQL databases!"
    }
    if ($dbs -notmatch "keycloak_db") {
        throw "keycloak_db was not found in MySQL databases!"
    }
    return $true
}

# ------------------------------------------------------------------------------
# Test 8: Backend API Health Check
# ------------------------------------------------------------------------------
Assert-Test "Backend API Health Endpoint (/health)" {
    $response = Invoke-RestMethod -Uri "http://localhost:5000/health" -Method Get
    if ($response -ne "Healthy") {
        throw "Expected 'Healthy', received: $response"
    }
    return $true
}

# ------------------------------------------------------------------------------
# Test 9: Backend JWT Authentication (Status with token)
# ------------------------------------------------------------------------------
Assert-Test "Backend JWT Authentication (GET /api/collection/status)" {
    $tokenRes = Invoke-RestMethod -Uri "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" -Method Post -Body @{
        client_id  = "osint-frontend"
        grant_type = "password"
        username   = "admin_user"
        password   = "AdminPassword123!"
    }
    $res = Invoke-RestMethod -Uri "http://localhost:5000/api/collection/status" -Method Get -Headers @{ Authorization = "Bearer $($tokenRes.access_token)" }
    if ($res.status -ne "idle") {
        throw "Unexpected status returned: $($res.status)"
    }
    return $true
}

# ------------------------------------------------------------------------------
# Test 10: Backend Role Authorization - Admin allowed (202)
# ------------------------------------------------------------------------------
Assert-Test "Backend Role Authorization: Admin allowed to start collection (202)" {
    $tokenRes = Invoke-RestMethod -Uri "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" -Method Post -Body @{
        client_id  = "osint-frontend"
        grant_type = "password"
        username   = "admin_user"
        password   = "AdminPassword123!"
    }
    $res = Invoke-RestMethod -Uri "http://localhost:5000/api/collection/start" -Method Post -Headers @{ Authorization = "Bearer $($tokenRes.access_token)" }
    if (-not $res.message) {
        throw "Expected message in response, got none"
    }
    return $true
}

# ------------------------------------------------------------------------------
# Test 11: Backend Role Authorization - Viewer forbidden (403)
# ------------------------------------------------------------------------------
Assert-Test "Backend Role Authorization: Viewer forbidden to start collection (403)" {
    $tokenRes = Invoke-RestMethod -Uri "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" -Method Post -Body @{
        client_id  = "osint-frontend"
        grant_type = "password"
        username   = "viewer_user"
        password   = "ViewerPassword123!"
    }
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:5000/api/collection/start" -Method Post -Headers @{ Authorization = "Bearer $($tokenRes.access_token)" }
        throw "Expected 403 Forbidden, but request succeeded!"
    } catch {
        $statusCode = [int]$_.Exception.Response.StatusCode
        if ($statusCode -ne 403) {
            throw "Expected status code 403, received: $statusCode"
        }
    }
    return $true
}

# ------------------------------------------------------------------------------
# Test 12: Backend Security: Rejection of unauthenticated requests (401)
# ------------------------------------------------------------------------------
Assert-Test "Backend Security: Rejection of unauthenticated requests (401)" {
    try {
        $null = Invoke-RestMethod -Uri "http://localhost:5000/api/collection/status" -Method Get
        throw "Expected 401 Unauthorized, but request succeeded!"
    } catch {
        $statusCode = [int]$_.Exception.Response.StatusCode
        if ($statusCode -ne 401) {
            throw "Expected status code 401, received: $statusCode"
        }
    }
    return $true
}

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "  Test Summary: Total: $TotalTests | Passed: $PassedTests | Failed: $FailedTests  " -ForegroundColor $(if ($FailedTests -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================" -ForegroundColor Cyan

if ($FailedTests -gt 0) {
    exit 1
} else {
    exit 0
}
