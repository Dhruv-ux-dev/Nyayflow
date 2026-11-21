# Single-container image for small free hosts (e.g. SnapDeploy): nginx serves the React UI on $PORT
# and forwards /api to Spring Boot on 127.0.0.1:9090. For local development use docker-compose.yml.
FROM node:22-alpine AS web
WORKDIR /app
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY frontend/ ./
RUN npm run build

FROM maven:3.9-eclipse-temurin-25 AS api
WORKDIR /app
COPY backend/pom.xml .
RUN mvn -q -B dependency:go-offline
COPY backend/src src
RUN mvn -q -B package -DskipTests

FROM eclipse-temurin:25-jre
RUN apt-get update && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=api /app/target/nyayaflow.jar app.jar
COPY --from=web /app/dist /usr/share/nginx/html
COPY deploy/single/nginx.conf /app/nginx.conf.template
COPY deploy/single/start.sh /app/start.sh
RUN chmod +x /app/start.sh && mkdir -p /tmp/uploads && chmod 777 /tmp/uploads
# Sized for a 512 MB container: small heap, serial GC, C1-only JIT for faster startup.
ENV NYAYAFLOW_STORAGE_LOCATION=/tmp/uploads \
    NYAYAFLOW_SEED_DEMO_DATA=true \
    SERVER_PORT=9090 \
    JAVA_TOOL_OPTIONS="-Xmx300m -Xss512k -XX:MaxMetaspaceSize=140m -XX:ReservedCodeCacheSize=48m -XX:+UseSerialGC -XX:TieredStopAtLevel=1 -XX:+ExitOnOutOfMemoryError"
EXPOSE 8080
CMD ["/app/start.sh"]
