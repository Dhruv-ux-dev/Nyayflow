# Runtime-only image used on the `deploy` branch. CI has already built app.jar and html/,
# so the host only installs nginx and copies files (one build stage, fits small free tiers).
FROM eclipse-temurin:25-jre
RUN apt-get update && apt-get install -y --no-install-recommends nginx \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY app.jar app.jar
COPY html /usr/share/nginx/html
COPY nginx.conf /app/nginx.conf.template
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh && mkdir -p /tmp/uploads && chmod 777 /tmp/uploads
# Sized for a 512 MB container: small heap, serial GC, C1-only JIT for faster startup.
ENV NYAYAFLOW_STORAGE_LOCATION=/tmp/uploads \
    NYAYAFLOW_SEED_DEMO_DATA=true \
    SERVER_PORT=9090 \
    JAVA_TOOL_OPTIONS="-Xmx300m -Xss512k -XX:MaxMetaspaceSize=140m -XX:ReservedCodeCacheSize=48m -XX:+UseSerialGC -XX:TieredStopAtLevel=1 -XX:+ExitOnOutOfMemoryError"
EXPOSE 8080
CMD ["/app/start.sh"]
