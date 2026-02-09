# Stage 1: Create custom base image
FROM node:18-alpine AS base

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init curl

# Create app directory
WORKDIR /app

# Stage 2: Dependencies
FROM base AS dependencies

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Stage 3: Production image
FROM base AS production

# Set labels
LABEL maintainer="your-email@example.com"
LABEL description="Multi-service Docker app - Backend API"
LABEL version="1.0"

# Set NODE_ENV to production
ENV NODE_ENV=production

# Copy dependencies from dependencies stage
COPY --from=dependencies /app/node_modules ./node_modules

# Copy application code
COPY . .

# Create logs directory
RUN mkdir -p logs && \
    chown -R node:node logs

# Create non-root user (node user already exists in base image)
USER node

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["node", "server.js"]
