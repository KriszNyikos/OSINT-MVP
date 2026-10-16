# Frontend Layer (Angular SPA)

This directory contains the **Angular SPA** client for the OSINT Platform MVP.

## Architectural Responsibilities:
* **Authentication & Navigation:** OIDC PKCE login and session lifecycle via Keycloak (`admin` and `viewer` role-based view guarding).
* **Search & Filter Interface:** Full-text search, filtering by data source and collection period, combined filtering, pagination, and record detail inspector.
* **Dashboard & Visualizations:**
  * Collector execution status monitoring and execution history.
  * Analytical dashboards and charts (distribution by source, collection timeline trends).
* **User Experience (UX):** Clean and intuitive interface with consistent state handling (loading, empty, error, and unauthorized / forbidden states).

---

## Directory & Modular Structure
```text
frontend/
├── src/
│   ├── app/
│   │   ├── core/              # OIDC / Keycloak auth services, HTTP interceptors, route guards
│   │   ├── features/          # Feature views: dashboard, search, collectors, admin
│   │   ├── shared/            # Reusable UI components, widgets, and shared models
│   │   ├── app.config.ts      # Application routing & provider configuration
│   │   ├── app.routes.ts      # Angular standalone routes
│   │   └── app.ts             # Root standalone component
│   ├── environments/          # Environment configuration (API URL, Keycloak config)
│   │   ├── environment.ts
│   │   └── environment.development.ts
│   ├── main.ts                # Bootstrap file
│   └── styles.scss            # Global styling
├── Dockerfile                 # Multi-stage production container build (Node 22 -> Nginx Alpine)
├── nginx.conf                 # Nginx configuration with SPA fallback routing
├── angular.json               # Angular CLI configuration
└── package.json               # Dependencies & build scripts
```

---

## Versions & Stack
* **Angular:** `22.2.x`
* **Node.js:** `v22.23.2` LTS
* **npm:** `10.9.8`
* **TypeScript:** `~6.0.2`
* **Style Preprocessor:** SCSS
* **Architecture:** Standalone Components with modern Angular Signals

---

## Development & Execution Commands

### 1. Install Dependencies
```bash
npm install
```

### 2. Run Development Server
```bash
npm start
# or
npx ng serve --port 4200
```
Application will be accessible at: `http://localhost:4200`

### 3. Build for Production
```bash
npm run build
```
Output directory: `dist/osint-frontend/browser`
