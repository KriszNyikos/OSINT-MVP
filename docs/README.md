# System Documentation & Architectural Decisions

## 1. Separation of Concerns
In accordance with the assessment specifications, the architectural responsibilities are decoupled into dedicated layers:
1. **Presentation Layer (Frontend):** Angular SPA communicating strictly with the Keycloak OIDC endpoint (user authentication) and the .NET Web API REST endpoints. It has no direct access to the database or LDAP.
2. **API & Business Logic Layer (Backend):** .NET Web API designed as a modular monolith, responsible for cryptographic validation of JWT tokens (signature, issuer, audience, lifetime, roles) and processing business queries.
3. **Data Persistence Layer:** MySQL 8.0 relational database accessed via Entity Framework Core ORM with transaction support and deduplication enforcement.
4. **Data Collectors:** Modular components implementing a shared interface (`IDataCollector`) within the backend to fetch, parse, and normalize intelligence data.
5. **IAM & Directory Services:** Keycloak 24 and OpenLDAP 1.5 containers managing enterprise authentication, user federation, and role assignments.

---

## 2. Demo Environment Simplifications
The specification explicitly requires documenting all demo environment trade-offs and simplifications:
* **Plain HTTP on Internal Network:** Standard HTTP is utilized on the local Docker network and for local browser access, eliminating the need for reviewers to install and trust custom self-signed SSL/TLS certificates.
* **Keycloak Development Mode (`start-dev`):** Keycloak runs with automated single-step realm import (`--import-realm`), allowing zero-configuration startup without requiring manual clicks in the admin console.
* **Co-located Single Database Instance:** A single, resource-efficient MySQL 8.0 container hosts both the application database (`osint_db`) and Keycloak database (`keycloak_db`) under isolated schemas, minimizing host memory consumption.
* **Pre-seeded Development Credentials:** Default development credentials are provided in `.env.example` to ensure immediate, reproducible evaluation out of the box.
