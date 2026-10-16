# Backend Layer (.NET Modular Monolith Web API)

This directory contains the **.NET Web API** backend for the OSINT Platform MVP, structured as a clean **Modular Monolith** adhering to strict separation of concerns.

---

## Architectural Responsibilities & Projects

The backend is decomposed into 4 dedicated projects under `backend/src/`:

### 1. `OsintPlatform.Api` (Presentation & Web API Host)
* **Responsibility:** Serves REST endpoints, routes requests, handles CORS, and exposes `/health` monitoring.
* **Authentication:** Cryptographic validation of Keycloak OIDC JWT tokens (signature, issuer, audience, expiration, and role claims).
* **Thin Controllers:** Delegates business operations and data queries to underlying services.

### 2. `OsintPlatform.Core` (Domain & Contracts)
* **Responsibility:** Pure C# domain model and abstractions independent of any external frameworks.
* **Entities:** Data models representing intelligence records, collector execution logs, and data sources.
* **Interfaces:** Shared contracts including the unified collector interface (`IDataCollector`) and repository abstractions.
* **DTOs & Enums:** Data transfer objects for API contracts and status enumerations.

### 3. `OsintPlatform.Persistence` (Data Persistence & MySQL Access)
* **Responsibility:** Manages the unified data model in MySQL using Entity Framework Core.
* **Context:** `OsintDbContext` managing database connections and entity sets.
* **Configurations:** Fluent API entity configurations enforcing indices and deduplication policies.
* **Migrations:** EF Core database schema migrations.

### 4. `OsintPlatform.Collectors` (Intelligence Data Ingestion)
* **Responsibility:** Dedicated business logic for data gathering, parsing, and normalization.
* **Module 1 (File Collector):** CSV and JSON sample file ingestion engine.
* **Module 2 (Synthetic Collector):** Deterministic synthetic intelligence data simulator.
* **Lifecycle & Services:** Execution tracking, error handling, and collector status monitoring.

---

## Directory Structure
```text
backend/
├── OsintPlatform.sln           # Standard Visual Studio solution file
├── OsintPlatform.slnx          # Modern XML solution format (.NET 10)
├── Dockerfile                  # Multi-stage container build (SDK 10.0 -> ASP.NET 10.0 runtime)
├── .dockerignore
└── src/
    ├── OsintPlatform.Api/
    │   ├── Controllers/        # HealthController, future endpoints
    │   ├── Properties/         # launchSettings.json (ports 5000 / 5001)
    │   ├── Program.cs          # Pipeline, CORS, HealthChecks, OpenAPI
    │   └── appsettings.json    # DB connection string & Keycloak OIDC configuration
    │
    ├── OsintPlatform.Core/
    │   ├── Entities/
    │   ├── Interfaces/
    │   ├── DTOs/
    │   └── Enums/
    │
    ├── OsintPlatform.Persistence/
    │   ├── Context/
    │   ├── Configurations/
    │   ├── Repositories/
    │   └── Migrations/
    │
    └── OsintPlatform.Collectors/
        ├── Modules/
        │   ├── FileCollector/
        │   └── Synthetic/
        └── Services/
```

---

## Versions & Stack
* **.NET SDK:** `10.0.401`
* **Target Framework:** `net10.0`
* **C# Language Version:** Latest (`13 / 14`)
* **ORM:** Entity Framework Core
* **Database Engine:** MySQL 8.0

---

## Build & Execution Commands

### 1. Build the Entire Solution
```bash
dotnet build backend/OsintPlatform.sln
```

### 2. Run the Web API Locally
```bash
dotnet run --project backend/src/OsintPlatform.Api --launch-profile http
```
The API is served at `http://localhost:5000`:
* **Health Check Endpoint:** [http://localhost:5000/api/health](http://localhost:5000/api/health) and [http://localhost:5000/health](http://localhost:5000/health)
* **OpenAPI Documentation:** [http://localhost:5000/openapi/v1.json](http://localhost:5000/openapi/v1.json)
