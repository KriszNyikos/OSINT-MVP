-- ==============================================================================
-- OSINT Platform - MySQL Database Initialization Script
-- ==============================================================================

-- 1. Create Keycloak database if not already created
CREATE DATABASE IF NOT EXISTS `keycloak_db` 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

-- 2. Create Application database if not already created
CREATE DATABASE IF NOT EXISTS `osint_db` 
    CHARACTER SET utf8mb4 
    COLLATE utf8mb4_unicode_ci;

-- 3. Grant full privileges on both databases to the application user
GRANT ALL PRIVILEGES ON `osint_db`.* TO 'osint_user'@'%';
GRANT ALL PRIVILEGES ON `keycloak_db`.* TO 'osint_user'@'%';

FLUSH PRIVILEGES;
