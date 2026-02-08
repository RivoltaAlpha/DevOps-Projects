# User Service

Microservice for managing user accounts, authentication, and profiles.

## Features

- User registration and authentication
- User profile management
- JWT-based authentication
- Password hashing and security
- Integration with order service

## Tech Stack

- Node.js / TypeScript
- Express.js
- PostgreSQL
- Redis (caching)
- Jest (testing)

## Getting Started

### Prerequisites

- Node.js 18+
- Docker & Docker Compose
- PostgreSQL 15+
- Redis 7+

### Installation

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.example .env

# Run with Docker Compose
docker-compose up -d

# Run locally
npm run dev
```

### Environment Variables

See `.env.example` for all required environment variables.

### API Endpoints

#### Health Check
- `GET /health` - Service health status
- `GET /ready` - Readiness check
- `GET /live` - Liveness check

#### User Management
- `POST /api/users` - Create new user
- `GET /api/users/:id` - Get user by ID
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user
- `GET /api/users` - List all users

#### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/logout` - Logout user
- `GET /api/auth/me` - Get current user

## Testing

```bash
# Run all tests
npm test

# Run tests with coverage
npm run test:coverage

# Run tests in watch mode
npm run test:watch
```

## Docker

```bash
# Build image
docker build -t user-service:latest .

# Run container
docker run -p 3001:3001 --env-file .env user-service:latest
```

## CI/CD

This service uses Jenkins for CI/CD. See `Jenkinsfile` for pipeline configuration.

## Project Structure

```
user-service/
├── src/
│   ├── index.ts           # Application entry point
│   ├── routes/            # API routes
│   ├── controllers/       # Request handlers
│   ├── services/          # Business logic
│   ├── models/            # Data models
│   ├── middleware/        # Express middleware
│   └── utils/             # Utility functions
├── tests/
│   ├── unit/              # Unit tests
│   └── integration/       # Integration tests
├── Dockerfile
├── docker-compose.yml
├── Jenkinsfile
└── package.json
```

## License

MIT
