# Architecture Diagram

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          CLIENT BROWSER                          │
│                      (http://localhost)                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTP Request
                             │ Port 80
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      NGINX REVERSE PROXY                         │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ • Rate Limiting (10 req/s API, 50 req/s general)         │  │
│  │ • Security Headers (XSS, Frame Options, etc.)            │  │
│  │ • Gzip Compression                                        │  │
│  │ • Static Asset Caching                                    │  │
│  │ • Load Balancing                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────┬────────────────────────────────────┬─────────────────┘
           │                                    │
           │                                    │
┌──────────▼────────────┐          ┌───────────▼────────────┐
│  FRONTEND NETWORK     │          │  BACKEND NETWORK       │
│  (172.x.x.x/16)       │          │  (172.x.x.x/16)        │
└──────────┬────────────┘          └───────────┬────────────┘
           │                                    │
           │                                    │
     ┌─────▼─────┐                      ┌──────▼──────┐
     │           │                      │             │
     │ FRONTEND  │                      │  BACKEND    │
     │           │                      │             │
     │ React App │                      │ Node.js API │
     │ + Nginx   │                      │  Express    │
     │           │                      │             │
     │ Port: 80  │                      │  Port: 3000 │
     │           │                      │             │
     │ Image:    │                      │ Image:      │
     │ ~50 MB    │                      │ ~180 MB     │
     │           │                      │             │
     │ Features: │                      │ Features:   │
     │ • SPA     │                      │ • REST API  │
     │ • Multi-  │                      │ • MongoDB   │
     │   stage   │                      │ • Redis     │
     │   build   │                      │ • Secrets   │
     │ • Non-    │                      │ • Health    │
     │   root    │                      │   checks    │
     └───────────┘                      └──────┬──────┘
                                               │
                                               │
                                  ┌────────────┴───────────┐
                                  │                        │
                            ┌─────▼─────┐          ┌──────▼──────┐
                            │           │          │             │
                            │  MONGODB  │          │    REDIS    │
                            │           │          │             │
                            │ Database  │          │    Cache    │
                            │           │          │             │
                            │ Port:     │          │ Port: 6379  │
                            │ 27017     │          │             │
                            │           │          │ Max Memory: │
                            │ Volume:   │          │   256 MB    │
                            │ Persistent│          │             │
                            │           │          │ Volume:     │
                            │ Secrets:  │          │ Persistent  │
                            │ • Root    │          │             │
                            │   password│          │ Strategy:   │
                            │ • User    │          │ LRU eviction│
                            │   password│          │             │
                            └───────────┘          └─────────────┘
```

## Data Flow

### Request Flow (GET /api/items)
```
1. Browser → Nginx (Port 80)
   ↓
2. Nginx → Backend (Port 3000)
   ↓
3. Backend → Check Redis Cache
   ↓
4a. Cache Hit → Return cached data
   OR
4b. Cache Miss → Query MongoDB
   ↓
5. MongoDB → Return data → Store in Redis (60s TTL)
   ↓
6. Backend → Return JSON to Nginx
   ↓
7. Nginx → Return to Browser
```

### Write Flow (POST /api/items)
```
1. Browser → Nginx
   ↓
2. Nginx → Backend
   ↓
3. Backend → Save to MongoDB
   ↓
4. Backend → Invalidate Redis cache
   ↓
5. Backend → Return success to Nginx
   ↓
6. Nginx → Return to Browser
```

## Network Topology

```
┌─────────────────────────────────────────────────┐
│           DOCKER HOST (127.0.0.1)               │
│                                                 │
│  ┌───────────────────────────────────────────┐ │
│  │      FRONTEND NETWORK (Bridge)            │ │
│  │                                           │ │
│  │  ┌────────┐              ┌─────────┐     │ │
│  │  │ Nginx  │◄────────────►│Frontend │     │ │
│  │  └────┬───┘              └─────────┘     │ │
│  │       │                                   │ │
│  └───────┼───────────────────────────────────┘ │
│          │                                     │
│          │                                     │
│  ┌───────┼───────────────────────────────────┐ │
│  │       │   BACKEND NETWORK (Bridge)        │ │
│  │       │                                   │ │
│  │  ┌────▼───┐    ┌─────────┐    ┌───────┐ │ │
│  │  │ Nginx  │◄──►│ Backend │◄──►│MongoDB│ │ │
│  │  └────────┘    └────┬────┘    └───────┘ │ │
│  │                     │                    │ │
│  │                     ▼                    │ │
│  │                ┌────────┐                │ │
│  │                │ Redis  │                │ │
│  │                └────────┘                │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  Port Mapping:                                  │
│  Host:80 → Nginx:80                             │
└─────────────────────────────────────────────────┘

Network Isolation:
✓ Frontend CANNOT access MongoDB directly
✓ Frontend CANNOT access Redis directly
✓ Backend CAN access MongoDB
✓ Backend CAN access Redis
✓ Nginx acts as gateway between networks
```

## Volume Structure

```
Docker Volumes (Persistent Storage)
│
├── mongodb-data
│   └── /data/db (MongoDB data files)
│       • Survives container restarts
│       • Can be backed up
│       • Size grows with data
│
├── redis-data
│   └── /data (Redis append-only file)
│       • Persistence enabled
│       • Max 256MB in memory
│       • LRU eviction policy
│
├── nginx-logs
│   └── /var/log/nginx
│       • access.log (combined format)
│       • error.log (warn level)
│       • Rotation: 10MB max, 5 files
│
└── backend-logs
    └── /app/logs
        • access.log (morgan format)
        • Rotation: 10MB max, 5 files
```

## Secret Management

```
Docker Secrets (Read-Only)
│
├── db_password
│   └── Mounted at: /run/secrets/db_password
│       • Backend: MongoDB user password
│       • Not in environment variables
│       • Not in images
│       • Not in version control
│
└── db_root_password
    └── Mounted at: /run/secrets/db_root_password
        • MongoDB: Root password
        • Used during initialization
        • Secure storage
```

## Build Process

```
Multi-Stage Build (Frontend)
│
├── Stage 1: Builder (node:18-alpine)
│   ├── Install dependencies
│   ├── Build React app
│   └── Output: /app/build (optimized)
│
├── Stage 2: Base (nginx:alpine)
│   ├── Install curl
│   └── Remove default config
│
└── Stage 3: Production
    ├── Copy from builder
    ├── Add nginx config
    ├── Create non-root user
    └── Result: 50MB image

Custom Base Build (Backend)
│
├── Stage 1: Base (node:18-alpine)
│   ├── Install dumb-init
│   └── Install curl
│
├── Stage 2: Dependencies
│   ├── Copy package files
│   └── Install production deps
│
└── Stage 3: Production
    ├── Copy dependencies
    ├── Copy source code
    ├── Use non-root user
    └── Result: 180MB image
```

## Health Check System

```
Health Check Hierarchy
│
├── Nginx
│   ├── Check: curl http://localhost/health
│   ├── Interval: 30s
│   ├── Depends on: Backend healthy
│   └── Proxy to backend /health endpoint
│
├── Frontend
│   ├── Check: curl http://localhost/
│   ├── Interval: 30s
│   └── Independent health
│
├── Backend
│   ├── Check: curl http://localhost:3000/health
│   ├── Interval: 30s
│   ├── Depends on: MongoDB + Redis healthy
│   └── Returns: uptime, mongodb, redis status
│
├── MongoDB
│   ├── Check: mongosh ping
│   ├── Interval: 30s
│   └── Independent health
│
└── Redis
    ├── Check: redis-cli ping
    ├── Interval: 30s
    └── Independent health

Startup Order:
1. MongoDB + Redis (parallel)
2. Backend (waits for 1)
3. Frontend (parallel with 2)
4. Nginx (waits for 2 + 3)
```

## Security Layers

```
Security Implementation
│
├── Container Level
│   ├── Non-root users (all containers)
│   ├── Read-only secrets
│   ├── Minimal base images (Alpine)
│   └── No unnecessary packages
│
├── Network Level
│   ├── Network isolation
│   ├── No direct DB access from frontend
│   └── Bridge networks (not host)
│
├── Application Level
│   ├── Rate limiting (Nginx)
│   ├── Security headers
│   ├── Input validation
│   └── CORS configuration
│
└── Data Level
    ├── Secrets for passwords
    ├── Persistent volumes
    └── Encrypted at rest (host level)
```

This architecture provides:
✓ Scalability (can scale services independently)
✓ Security (network isolation, non-root, secrets)
✓ Performance (caching, optimization)
✓ Reliability (health checks, restart policies)
✓ Maintainability (clear separation of concerns)
