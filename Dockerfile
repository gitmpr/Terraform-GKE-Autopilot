# Multi-stage build
FROM eclipse-temurin:21-jre AS builder
WORKDIR /app
COPY target/*.jar app.jar
RUN java -Djarmode=tools -jar app.jar extract --layers --destination extracted

FROM eclipse-temurin:21-jre

# Create spring group
RUN groupadd -r spring

# Create spring user
RUN useradd -r -g spring spring

WORKDIR /app

# Copy layers from builder stage
COPY --from=builder /app/extracted/dependencies/ ./
COPY --from=builder /app/extracted/spring-boot-loader/ ./
COPY --from=builder /app/extracted/snapshot-dependencies/ ./
COPY --from=builder /app/extracted/application/ ./

# Change ownership to spring user
RUN chown -R spring:spring /app

# Switch to non-root user
USER spring

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
