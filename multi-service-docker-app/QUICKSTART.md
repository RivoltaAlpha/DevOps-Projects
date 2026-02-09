# Quick Start Guide

## 🚀 Get Started in 3 Steps

### Step 1: Build the Images
```bash
./manage.sh build
```
This will build all Docker images with multi-stage builds and optimizations.

### Step 2: Start the Services
```bash
./manage.sh start
```
This starts all services in the background.

### Step 3: Open Your Browser
Navigate to: **http://localhost**

You should see the Multi-Service Docker Application running!

---

## ✅ Verify Everything is Working

```bash
# Check service status
./manage.sh status

# View logs
./manage.sh logs

# Test the application
./manage.sh test
```

---

## 🎯 Try These Features

1. **Add Items**: Use the input box to add items to the database
2. **Cache in Action**: Add items, then refresh - first load hits DB, next hits cache
3. **Delete Items**: Remove items and watch the cache invalidate
4. **Monitor Logs**: Run `./manage.sh logs backend` to see cache hits/misses

---

## 📊 What's Running?

- **Frontend** (React): Modern web interface
- **Backend** (Node.js): RESTful API with Express
- **MongoDB**: Database storing your items
- **Redis**: Cache for performance
- **Nginx**: Reverse proxy handling all requests

---

## 🛑 Stop the Application

```bash
./manage.sh stop
```

---

## 🔧 Common Commands

```bash
./manage.sh build      # Build images
./manage.sh start      # Start services
./manage.sh stop       # Stop services
./manage.sh restart    # Restart services
./manage.sh logs       # View all logs
./manage.sh status     # Check health
./manage.sh help       # See all commands
```

---

## 🐛 Troubleshooting

### Port 80 Already in Use
```bash
# Option 1: Stop the conflicting service
# Option 2: Edit docker-compose.yml and change port mapping:
#   ports:
#     - "8080:80"  # Use port 8080 instead
```

### Services Not Starting
```bash
# Check Docker is running
docker info

# View detailed logs
./manage.sh logs

# Rebuild from scratch
./manage.sh clean
./manage.sh build
./manage.sh start
```

### Need Fresh Start
```bash
# Reset everything (DELETES DATA!)
./manage.sh reset
./manage.sh build
./manage.sh start
```

---

## 📚 Learn More

Check out the full [README.md](README.md) for:
- Architecture details
- Security features
- Advanced configuration
- Monitoring and logs
- Best practices

---

**Happy Dockerizing! 🐳**
