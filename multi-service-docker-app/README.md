# Multi-Service Docker Application

A production-ready multi-service application demonstrating advanced Docker concepts including multi-stage builds, custom base images, Docker secrets, volumes, networks, health checks, and comprehensive logging.

## 🏗️ Architecture

This application consists of five interconnected services:

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    Nginx    │  ← Reverse Proxy (Port 80)
│   (Alpine)  │
└──────┬──────┘
       │
       ├───────────────┬───────────────┐
       ▼               ▼               ▼
┌──────────┐    ┌──────────┐    ┌──────────┐
│ Frontend │    │ Backend  │    │          │
│  (React) │    │(Node.js) │    │          │
│  nginx   │    │ Express  │    │          │
└──────────┘    └────┬─────┘    │          │
                     │           │          │
                     ▼           ▼          │
              ┌──────────┐ ┌─────────┐     │
              │ MongoDB  │ │  Redis  │     │
              │          │ │ (Cache) │     │
              └──────────┘ └─────────┘     │
                                            │
Networks:                                   │
├─ frontend-network ────────────────────────┘
└─ backend-network
```

## 🚀 Features Implemented

### Docker Best Practices
- ✅ **Multi-stage builds** - Frontend uses build and production stages
- ✅ **Custom base images** - Optimized base images for frontend and backend
- ✅ **Non-root users** - All containers run as non-root for security
- ✅ **Health checks** - Every service has proper health monitoring
- ✅ **Docker secrets** - Sensitive data (passwords) stored securely
- ✅ **Volume management** - Persistent storage for MongoDB and Redis
- ✅ **Network isolation** - Frontend and backend networks separated
- ✅ **Logging & rotation** - JSON logging with size limits
- ✅ **Image optimization** - Minimal image sizes using Alpine Linux
- ✅ **.dockerignore files** - Reduced build context and faster builds

### Application Features
- **Frontend**: React SPA with modern UI
- **Backend**: RESTful API with Express.js
- **Database**: MongoDB for data persistence
- **Cache**: Redis for performance optimization
- **Proxy**: Nginx with rate limiting and security headers

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 4GB RAM available for Docker
- Ports 80 available on host machine

## 🛠️ Quick Start

### 1. Clone and Navigate
```bash
cd multi-service-docker-app
```

### 2. Build and Start Services
```bash
# Build all images
docker-compose build

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### 3. Access the Application
- **Web Application**: http://localhost
- **API Health Check**: http://localhost/health
- **Nginx Status**: http://localhost/nginx_status (from inside Docker network)

### 4. Stop Services
```bash
# Stop all services
docker-compose down

# Stop and remove volumes (CAUTION: deletes data)
docker-compose down -v
```

## 📁 Project Structure

```
multi-service-docker-app/
├── frontend/                 # React frontend application
│   ├── src/
│   │   ├── App.js           # Main React component
│   │   ├── App.css          # Styling
│   │   └── index.js         # React entry point
│   ├── public/
│   │   └── index.html       # HTML template
│   ├── Dockerfile           # Multi-stage build
│   ├── nginx.conf           # Nginx config for serving React
│   └── package.json
│
├── backend/                  # Node.js Express API
│   ├── server.js            # Main server file
│   ├── Dockerfile           # Optimized backend image
│   └── package.json
│
├── nginx/                    # Reverse proxy
│   ├── nginx.conf           # Proxy configuration
│   └── Dockerfile
│
├── secrets/                  # Docker secrets
│   ├── db_password.txt      # MongoDB user password
│   └── db_root_password.txt # MongoDB root password
│
├── docker-compose.yml        # Main orchestration file
├── init-mongo.js            # MongoDB initialization script
├── .env                     # Environment variables
└── README.md                # This file
```

## 🔐 Security Features

### Docker Secrets
Sensitive information is stored using Docker secrets:
```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt
  db_root_password:
    file: ./secrets/db_root_password.txt
```

### Non-Root Users
All containers run as non-root users:
- Frontend: `appuser` (UID 1001)
- Backend: `node` (built-in)
- Nginx: `nginx` (built-in)

### Security Headers
Nginx adds security headers:
- X-Frame-Options
- X-Content-Type-Options
- X-XSS-Protection
- Referrer-Policy

### Rate Limiting
API endpoints are rate-limited:
- API: 10 requests/second
- General: 50 requests/second

## 🔍 Health Checks

All services implement health checks:

```bash
# Check service health
docker-compose ps

# View specific service health
docker inspect --format='{{json .State.Health}}' <container_name>
```

Health check endpoints:
- Frontend: `GET /`
- Backend: `GET /health`
- MongoDB: `mongosh --eval "db.adminCommand('ping')"`
- Redis: `redis-cli ping`
- Nginx: `GET /health`

## 📊 Monitoring & Logs

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend

# Last 100 lines
docker-compose logs --tail=100
```

### Log Rotation
Logs are automatically rotated with limits:
- Max size: 10MB per file
- Max files: 3-5 files kept
- Format: JSON

### Access Logs
- Nginx logs: `/var/log/nginx/` (in nginx-logs volume)
- Backend logs: `/app/logs/` (in backend-logs volume)

## 🌐 Networks

Two isolated networks:

1. **frontend-network**: Nginx ↔ Frontend
2. **backend-network**: Nginx ↔ Backend ↔ MongoDB ↔ Redis

This isolation ensures the frontend cannot directly access the database.

## 💾 Volumes

Persistent data storage:

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect multi-service-app_mongodb-data

# Backup MongoDB data
docker run --rm -v multi-service-app_mongodb-data:/data -v $(pwd):/backup alpine tar czf /backup/mongodb-backup.tar.gz -C /data .

# Restore MongoDB data
docker run --rm -v multi-service-app_mongodb-data:/data -v $(pwd):/backup alpine tar xzf /backup/mongodb-backup.tar.gz -C /data
```

## 🧪 Testing the Application

### API Endpoints

```bash
# Health check
curl http://localhost/health

# Get all items
curl http://localhost/api/items

# Create item
curl -X POST http://localhost/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item"}'

# Delete item
curl -X DELETE http://localhost/api/items/<item_id>

# Get stats
curl http://localhost/api/stats
```

### Cache Testing
1. Create items via the UI or API
2. Check backend logs to see "Cache miss"
3. Refresh within 60 seconds to see "Cache hit"
4. Create/delete items to see cache invalidation

## 🐛 Troubleshooting

### Services won't start
```bash
# Check service status
docker-compose ps

# View logs for errors
docker-compose logs

# Rebuild from scratch
docker-compose down -v
docker-compose build --no-cache
docker-compose up -d
```

### Port already in use
```bash
# Find process using port 80
lsof -i :80  # macOS/Linux
netstat -ano | findstr :80  # Windows

# Kill the process or change the port in docker-compose.yml
```

### Database connection issues
```bash
# Verify MongoDB is running
docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"

# Check secrets are mounted
docker-compose exec backend ls -la /run/secrets/
```

### Clear all data and restart
```bash
# WARNING: This deletes all data!
docker-compose down -v
docker system prune -a
docker-compose up --build -d
```

## 📈 Performance Optimization

### Image Sizes
```bash
# View image sizes
docker images | grep multi-service

# Typical sizes:
# frontend: ~50MB (multi-stage build)
# backend: ~180MB (Alpine-based)
# nginx: ~40MB (Alpine-based)
```

### Build Cache
```bash
# Build with cache
docker-compose build

# Build without cache (slower but fresh)
docker-compose build --no-cache
```

## 🔄 Development vs Production

### Development Mode
```bash
# Use development docker-compose
docker-compose -f docker-compose.dev.yml up
```

### Production Mode
- Uses optimized multi-stage builds
- Runs as non-root users
- Implements health checks
- Configured logging and monitoring
- Uses secrets for sensitive data

## 📚 Learning Resources

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Docker Security](https://docs.docker.com/engine/security/)
- [Health Checks](https://docs.docker.com/engine/reference/builder/#healthcheck)

## 🤝 Contributing

Feel free to submit issues and enhancement requests!

## 📝 License

MIT License - feel free to use this project for learning and development.

---

**Built with ❤️ as a Docker learning project**
