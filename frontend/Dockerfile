# Multi-stage Dockerfile for Angular SPA
FROM node:22-alpine AS build
WORKDIR /app

# Cache dependencies layer
COPY package*.json ./
RUN npm ci

# Copy source code and build production bundle
COPY . .
RUN npm run build

# Nginx Alpine runtime image
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/osint-frontend/browser /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
