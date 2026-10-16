# Backend Layer (.NET Web API)

This directory contains the upcoming **.NET Web API** layer.

## Architectural Responsibilities (based on the project specification):
* **API & Endpoints:** Serve REST endpoints and perform cryptographic validation of OIDC JWT tokens (signature, issuer, audience, expiration, and role claims).
* **Data Persistence (EF Core):** Manage the unified data model in the MySQL database, execute schema migrations, and enforce deduplication policies.
* **Data Collectors:**
  * Define the unified collector interface (`IDataCollector`).
  * **Collector Module 1:** Real CSV / JSON sample file processor.
  * **Collector Module 2:** Deterministic synthetic data simulator.
  * Collector execution lifecycle, execution logging, error handling, and status monitoring.
