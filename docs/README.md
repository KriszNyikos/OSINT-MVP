# System Documentation & Architectural Decisions

## 1. Separation of Concerns & Modular Monolith

In accordance with the assessment specifications, the architectural responsibilities are decoupled into dedicated, self-contained layers:

### A. Presentation Layer (Frontend SPA)
* **Location:** `frontend/`
* **Technology:** Angular 22.2 (Standalone Component Architecture with Signals)
* **Responsibilities:**
  * OIDC PKCE login & token refresh with Keycloak.
  * Role-based view authorization (`admin` vs `viewer`).
  * Intelligence search, filtering, and pagination.
  * Analytical dashboards, collector monitoring, and error handling.
  * Communicates strictly via HTTP with Keycloak and the backend REST API.

### B. API & Web Host Layer (Backend API)
* **Location:** `backend/src/OsintPlatform.Api/`
* **Technology:** ASP.NET Core Web API (.NET 10)
* **Responsibilities:**
  * Composition root for dependency injection.
  * Cryptographic validation of OIDC JWT tokens (signature, issuer, audience, lifetime, role claims).
  * Exposes REST endpoints (Thin Controllers).
  * CORS management for Angular origin (`http://localhost:4200`).
  * System health check endpoint (`/health` and `/api/health`).

### C. Domain & Contract Abstractions (Core)
* **Location:** `backend/src/OsintPlatform.Core/`
* **Technology:** Pure C# Class Library (.NET 10, no framework dependencies)
* **Responsibilities:**
  * Core domain entities (`Entities/`).
  * Common interface definitions (`Interfaces/`), including `IDataCollector`.
  * Data transfer objects (`DTOs/`) and domain enumerations (`Enums/`).

### D. Data Persistence Layer (Data Access)
* **Location:** `backend/src/OsintPlatform.Persistence/`
* **Technology:** Entity Framework Core (.NET 10) & MySQL 8.0
* **Responsibilities:**
  * `OsintDbContext` database context and MySQL configurations.
  * Fluent API mapping rules and deduplication unique constraints.
  * Data access repositories and query handlers.
  * EF Core database schema migrations (`Migrations/`).

### E. Data Collectors Module (Intelligence Ingestion)
* **Location:** `backend/src/OsintPlatform.Collectors/`
* **Technology:** .NET 10 Modular Class Library
* **Responsibilities:**
  * Ingestion and parsing logic for intelligence feeds.
  * **Module 1 (File Collector):** Real CSV and JSON data ingestion engine.
  * **Module 2 (Synthetic Collector):** Deterministic mock intelligence generator.
  * Collector coordinator service, execution logging, and error tracking.

### F. Identity & Directory Services (IAM)
* **Location:** `docker/keycloak/` & `docker/ldap/`
* **Technology:** Keycloak 24.0.5 & OpenLDAP 1.5.0
* **Responsibilities:** Enterprise authentication, LDAP federation, and RBAC role assignment (`admin`, `viewer`).

---

## 2. Exact Recorded Software & Runtime Versions

| Component / Layer | Runtime / Technology | Exact Version |
| :--- | :--- | :--- |
| **Frontend Framework** | Angular | `22.2.3` |
| **Frontend Runtime** | Node.js | `v22.23.2` LTS |
| **Node Package Manager** | npm | `10.9.8` |
| **Frontend Web Server** | Nginx Alpine (Docker) | `nginx:alpine` |
| **Backend SDK** | .NET SDK | `10.0.401` |
| **Backend Target Framework**| .NET (C# 13/14) | `net10.0` |
| **Backend ASP.NET Runtime** | ASP.NET Core (Docker) | `mcr.microsoft.com/dotnet/aspnet:10.0` |
| **Relational Database** | MySQL | `8.0` |
| **IAM / OIDC Provider** | Keycloak (Quarkus) | `24.0.5` |
| **Directory Service** | OpenLDAP (slapd) | `1.5.0` |
| **Container Engine** | Docker Engine | `v25+` *(Tested on 29.8.2)* |
| **Container Orchestration** | Docker Compose | `v2.20+` *(Tested on Compose 5.6.0)* |

---

## 3. Demo Environment Simplifications
The specification explicitly requires documenting all demo environment trade-offs and simplifications:
* **Plain HTTP on Internal Network:** Standard HTTP is utilized on the local Docker network and for local browser access, eliminating the need for reviewers to install and trust custom self-signed SSL/TLS certificates.
* **Keycloak Development Mode (`start-dev`):** Keycloak runs with automated single-step realm import (`--import-realm`), allowing zero-configuration startup without requiring manual clicks in the admin console.
* **Co-located Single Database Instance:** A single, resource-efficient MySQL 8.0 container hosts both the application database (`osint_db`) and Keycloak database (`keycloak_db`) under isolated schemas, minimizing host memory consumption.
* **Pre-seeded Development Credentials:** Default development credentials are provided in `.env.example` to ensure immediate, reproducible evaluation out of the box.
* **Reverse Proxy in Frontend Nginx:** The frontend Nginx container includes an optional `/api/` reverse proxy pass to `backend:8080`, allowing single-origin evaluation in containerized testing if needed.
