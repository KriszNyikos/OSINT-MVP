# Frontend Layer (Angular SPA)

This directory contains the upcoming **Angular SPA** layer.

## Architectural Responsibilities (based on the project specification):
* **Authentication & Navigation:** OIDC PKCE login and session lifecycle via Keycloak (`admin` and `viewer` role-based view guarding).
* **Search & Filter Interface:** Full-text search, filtering by data source and collection period, combined filtering, pagination, and record detail inspector.
* **Dashboard & Visualizations:**
  * Collector execution status monitoring and execution history.
  * Analytical dashboards and charts (distribution by source, collection timeline trends).
* **User Experience (UX):** Clean and intuitive interface with consistent state handling (loading, empty, error, and unauthorized / forbidden states).
