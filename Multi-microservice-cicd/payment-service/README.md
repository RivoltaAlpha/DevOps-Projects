# Payment Service

Microservice for handling payment processing, payment verification, and payment history.

## Features

- Payment processing and gateway integration
- Payment verification and validation
- Payment status tracking
- Integration with order service
- Event-driven architecture with RabbitMQ
- PCI-DSS compliance considerations
- Payment refunds and cancellations

## Tech Stack

- Node.js / TypeScript
- Express.js
- PostgreSQL
- Redis (caching)
- RabbitMQ (message queue)
- Jest (testing)
- Stripe/PayPal integration (example)

## Getting Started

### Prerequisites

- Node.js 18+
- Docker & Docker Compose
- PostgreSQL 15+
- Redis 7+
- RabbitMQ 3+
- Payment gateway credentials (Stripe/PayPal)

### Installation

```bash
# Install dependencies
npm install

# Copy environment variables
cp .env.example .env

# Update .env with your payment gateway credentials

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

#### Payment Management
- `POST /api/payments` - Process new payment
- `GET /api/payments/:id` - Get payment by ID
- `GET /api/payments/order/:orderId` - Get payments by order ID
- `POST /api/payments/:id/refund` - Refund a payment
- `POST /api/payments/:id/cancel` - Cancel a payment
- `GET /api/payments` - List all payments

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
docker build -t payment-service:latest .

# Run container
docker run -p 3003:3003 --env-file .env payment-service:latest
```

## CI/CD

This service uses Jenkins for CI/CD. See `Jenkinsfile` for pipeline configuration.

## Project Structure

```
payment-service/
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
- `payment.confirmed` - When payment is successfully processed
- `payment.failed` - When payment processing fails
- `payment.refunded` - When payment is refunded

### Subscribed Events
- `order.created` - When a new order is created (to process payment)
- `order.cancelled` - When an order is cancelled (to refund payment)

## Security Considerations

- Never log sensitive payment data
- Use HTTPS for all API communications
- Implement rate limiting
- Validate all input data
- Use environment variables for secrets
- Follow PCI-DSS compliance guidelines

## License

MIT
