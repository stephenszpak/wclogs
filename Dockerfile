# Multi-stage build for Phoenix + React app

# Stage 1: Build React frontend
FROM node:18-alpine AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci --only=production
COPY frontend/ ./
RUN npm run build

# Stage 2: Build Elixir/Phoenix backend
FROM elixir:1.14-alpine AS backend-builder

# Install build dependencies
RUN apk add --no-cache build-base git

# Set environment variables
ENV MIX_ENV=prod

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Create app directory
WORKDIR /app

# Copy mix files
COPY mix.exs mix.lock ./

# Install dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy source code
COPY lib lib
COPY config config
COPY priv priv

# Copy compiled frontend from previous stage
COPY --from=frontend-builder /app/frontend/build priv/static

# Compile assets and release
RUN mix assets.deploy
RUN mix compile
RUN mix release

# Stage 3: Runtime
FROM alpine:3.17

# Install runtime dependencies
RUN apk add --no-cache \
    bash \
    openssl \
    postgresql-client \
    curl

# Create non-root user
RUN addgroup -g 1000 -S wclogs && \
    adduser -u 1000 -S wclogs -G wclogs

# Set work directory
WORKDIR /app

# Copy release from builder stage
COPY --from=backend-builder --chown=wclogs:wclogs /app/_build/prod/rel/wc_logs ./

# Copy entrypoint script
COPY docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

# Change ownership
RUN chown -R wclogs:wclogs /app

# Switch to non-root user
USER wclogs

# Expose port
EXPOSE 4001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4001/api/reports || exit 1

# Start the application
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bin/wc_logs", "start"]