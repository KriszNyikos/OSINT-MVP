#!/usr/bin/env bash
# ==============================================================================
# OSINT Platform MVP - IAM & Infrastructure Automated Test Suite (Bash / CI)
# ==============================================================================
set -euo pipefail

TOTAL=0
PASSED=0
FAILED=0

assert_test() {
    local name="$1"
    local command="$2"
    TOTAL=$((TOTAL + 1))
    echo ""
    echo "=========================================="
    echo "[TEST $TOTAL] $name..."
    echo "=========================================="
    if eval "$command"; then
        PASSED=$((PASSED + 1))
        echo "  -> PASS: $name"
    else
        FAILED=$((FAILED + 1))
        echo "  -> FAIL: $name"
    fi
}

# Test 1: Container Health Status
assert_test "Docker Containers Health Status" '
    for c in osint-mysql osint-openldap osint-keycloak; do
        status=$(docker inspect -f "{{.State.Health.Status}}" "$c" 2>/dev/null || echo "not_found")
        if [ "$status" != "healthy" ]; then
            echo "Container $c is not healthy! Status: $status"
            exit 1
        fi
    done
'

# Test 2: OIDC Discovery
assert_test "Keycloak OIDC Discovery Endpoint" '
    code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/realms/osint-realm/.well-known/openid-configuration)
    [ "$code" -eq 200 ]
'

# Test 3: OpenLDAP Admin login
assert_test "OpenLDAP admin_user login & token acquisition" '
    res=$(curl -s -X POST "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" \
        -d "grant_type=password" \
        -d "client_id=osint-frontend" \
        -d "username=admin_user" \
        -d "password=AdminPassword123!")
    echo "$res" | grep -q "access_token"
'

# Test 4: OpenLDAP Viewer login
assert_test "OpenLDAP viewer_user login & token acquisition" '
    res=$(curl -s -X POST "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" \
        -d "grant_type=password" \
        -d "client_id=osint-frontend" \
        -d "username=viewer_user" \
        -d "password=ViewerPassword123!")
    echo "$res" | grep -q "access_token"
'

# Test 5: Fallback Local Admin login
assert_test "Fallback local_admin authentication" '
    res=$(curl -s -X POST "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" \
        -d "grant_type=password" \
        -d "client_id=osint-frontend" \
        -d "username=local_admin" \
        -d "password=LocalAdmin123!")
    echo "$res" | grep -q "access_token"
'

# Test 6: Invalid Credentials Rejection
assert_test "Security: Rejection of invalid credentials (401)" '
    code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" \
        -d "grant_type=password" \
        -d "client_id=osint-frontend" \
        -d "username=admin_user" \
        -d "password=WrongPassword999!")
    [ "$code" -eq 401 ]
'

# Test 7: MySQL Databases verification
assert_test "MySQL Database availability (osint_db and keycloak_db)" '
    dbs=$(docker exec osint-mysql mysql -u osint_user -posint_db_password_dev -e "SHOW DATABASES;" 2>&1)
    echo "$dbs" | grep -q "osint_db" && echo "$dbs" | grep -q "keycloak_db"
'

# Test 8: Backend API Health Check
assert_test "Backend API Health Endpoint (/health)" '
    code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/health)
    [ "$code" -eq 200 ]
'

# Test 9: Backend JWT Authentication (Status with admin token)
assert_test "Backend JWT Authentication (GET /api/collection/status)" '
    token=$(curl -s -X POST "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" \
        -d "grant_type=password" \
        -d "client_id=osint-frontend" \
        -d "username=admin_user" \
        -d "password=AdminPassword123!" | grep -o "\"access_token\": *\"[^\"]*\"" | cut -d "\"" -f4)
    code=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $token" http://localhost:5000/api/collection/status)
    [ "$code" -eq 200 ]
'

# Test 10: Backend Role Authorization - Admin allowed to start collection (202)
assert_test "Backend Role Authorization: Admin allowed to start collection (202)" '
    token=$(curl -s -X POST "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" \
        -d "grant_type=password" \
        -d "client_id=osint-frontend" \
        -d "username=admin_user" \
        -d "password=AdminPassword123!" | grep -o "\"access_token\": *\"[^\"]*\"" | cut -d "\"" -f4)
    code=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $token" http://localhost:5000/api/collection/start)
    [ "$code" -eq 202 ]
'

# Test 11: Backend Role Authorization - Viewer forbidden to start collection (403)
assert_test "Backend Role Authorization: Viewer forbidden to start collection (403)" '
    token=$(curl -s -X POST "http://localhost:8080/realms/osint-realm/protocol/openid-connect/token" \
        -d "grant_type=password" \
        -d "client_id=osint-frontend" \
        -d "username=viewer_user" \
        -d "password=ViewerPassword123!" | grep -o "\"access_token\": *\"[^\"]*\"" | cut -d "\"" -f4)
    code=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "Authorization: Bearer $token" http://localhost:5000/api/collection/start)
    [ "$code" -eq 403 ]
'

# Test 12: Backend Security: Rejection of unauthenticated requests (401)
assert_test "Backend Security: Rejection of unauthenticated requests (401)" '
    code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/api/collection/status)
    [ "$code" -eq 401 ]
'

echo ""
echo "=========================================================="
echo "  Test Summary: Total: $TOTAL | Passed: $PASSED | Failed: $FAILED"
echo "=========================================================="

if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
