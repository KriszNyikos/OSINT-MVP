# OSINT Platform MVP

## About the Project
This project is a technical Minimum Viable Product (MVP) for an open-source intelligence (OSINT) platform. The software aims to provide a stable foundation for data collection, storage, and search, while demonstrating the feasibility of the system and the extensibility of its architecture. The project was created as part of an assessment task, which also included a business requirements analysis.

## Key Features
*   **Secure Authentication:** OIDC-based login and authorization (Admin and Viewer roles) using Keycloak.
*   **Modular Data Collectors:** Data collection processes (a CSV processor and a deterministic simulator) that can be triggered via a unified interface.
*   **Unified Data Model:** Normalized storage of data originating from various sources and handling of duplicate records.
*   **Search and Filtering:** Free-text search in the content, as well as filtering by source and collection period.
*   **Dashboard:** Monitoring the execution status of data collectors and visualizing stored data (e.g., distribution by source).

## Technology Stack
*   **Frontend:** Angular
*   **Backend:** .NET Web API
*   **Database:** Entity Framework Core (SQL)
*   **IAM:** Keycloak
*   **Infrastructure:** Docker & Docker Compose