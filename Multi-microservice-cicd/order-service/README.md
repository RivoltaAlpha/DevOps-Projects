# Order Service

Microservice for managing orders, order processing, and order history.

## Features

- Order creation and management
- Order status tracking
- Integration with user and payment services
- Event-driven architecture with RabbitMQ
- Order history and analytics

## Tech Stack

- Node.js / TypeScript
- Express.js
- PostgreSQL
- Redis (caching)
- RabbitMQ (message queue)
- Jest (testing)

## Getting Started

### Prerequisites

- Node.js 18+
- Docker & Docker Compose
- PostgreSQL 15+
- Redis 7+
- RabbitMQ 3+

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

#### Order Management
- `POST /api/orders` - Create new order
- `GET /api/orders/:id` - Get order by ID
- `PUT /api/orders/:id` - Update order
- `DELETE /api/orders/:id` - Cancel order
- `GET /api/orders/user/:userId` - Get orders by user ID
- `GET /api/orders` - List all orders

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
docker build -t order-service:latest .

# Run container
docker run -p 3002:3002 --env-file .env order-service:latest
```

## CI/CD

This service uses Jenkins for CI/CD. See `Jenkinsfile` for pipeline configuration.

## Project Structure

```
order-service/
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

## Message Queue Events

### Published Events
- `order.created` - When a new order is created
- `order.updated` - When an order is updated
- `order.cancelled` - When an order is cancelled

### Subscribed Events
- `payment.confirmed` - When payment is confirmed
- `payment.failed` - When payment fails

## License

MIT
