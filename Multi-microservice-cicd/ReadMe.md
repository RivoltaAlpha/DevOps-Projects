# Multi-Microservice Jenkins CI/CD Pipeline Guide

## Architecture Overview

This guide covers setting up Jenkins pipelines for multiple microservices, each in separate GitHub repositories, with containerization and inter-service communication.

### Architecture Components

```
┌─────────────────────────────────────────────────────────────┐
│                        GitHub Repos                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ user-service │  │ order-service│  │  api-gateway │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Jenkins Server                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Pipeline 1  │  │  Pipeline 2  │  │  Pipeline 3  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                  Docker Registry                             │
│  localhost:5000 or private registry                         │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│              Deployment Environment                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Docker Compose / Kubernetes              │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │  │
│  │  │  User   │  │  Order  │  │   API   │             │  │
│  │  │ Service │◄─┤ Service │◄─┤ Gateway │             │  │
│  │  └─────────┘  └─────────┘  └─────────┘             │  │
│  │       │            │             │                   │  │
│  │       └────────────┴─────────────┘                   │  │
│  │              Shared Network                          │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Repository Structure](#repository-structure)
3. [Jenkins Setup](#jenkins-setup)
4. [Pipeline Templates](#pipeline-templates)
5. [Service Communication](#service-communication)
6. [Deployment Strategies](#deployment-strategies)
7. [Best Practices](#best-practices)

---

## Prerequisites

### Required Tools
- Jenkins server with Docker installed
- Docker Registry (local or cloud-based)
- GitHub/GitLab accounts
- Docker & Docker Compose
- SonarQube (optional, for code quality)
- Trivy (for security scanning)

### Jenkins Plugins Required
```bash
# Install these plugins via Jenkins UI or CLI
- Git Plugin
- GitHub Branch Source Plugin
- Docker Plugin
- Docker Pipeline Plugin
- Pipeline Plugin
- Multibranch Pipeline Plugin
- Credentials Binding Plugin
- HTML Publisher Plugin
- JUnit Plugin
- SonarQube Scanner Plugin
- Blue Ocean (optional, for better UI)
```

---

## Repository Structure

### Recommended Structure for Each Microservice

```
microservice-name/
├── Jenkinsfile                  # Pipeline definition
├── Dockerfile                   # Container image definition
├── docker-compose.yml           # Local development
├── .dockerignore               # Files to exclude from image
├── src/                        # Source code
│   ├── index.js
│   ├── routes/
│   ├── controllers/
│   └── services/
├── tests/                      # Test files
│   ├── unit/
│   └── integration/
├── package.json                # Dependencies
├── .env.example               # Environment variables template
└── README.md
```

### Shared Configuration Repository (Optional)

```
infrastructure/
├── docker-compose.prod.yml     # Production compose file
├── docker-compose.test.yml     # Test environment
├── nginx/                      # Reverse proxy config
├── monitoring/                 # Prometheus, Grafana configs
└── scripts/                    # Deployment scripts
```

---

## Jenkins Setup

### 1. Configure Multibranch Pipeline for Each Service

Create a new Multibranch Pipeline job for each microservice:

**Jenkins Dashboard → New Item → Multibranch Pipeline**

Configuration:
- **Branch Sources**: Add GitHub
- **Credentials**: Add GitHub credentials
- **Repository URL**: `https://github.com/your-org/service-name`
- **Behaviors**: Discover branches, tags
- **Build Configuration**: by Jenkinsfile
- **Scan Multibranch Pipeline Triggers**: Periodically (e.g., every 5 minutes)

### 2. Create Shared Library (Optional but Recommended)

**Jenkins Dashboard → Manage Jenkins → Configure System → Global Pipeline Libraries**

Create a shared library repository:

```groovy
// vars/buildMicroservice.groovy
def call(Map config) {
    pipeline {
        agent any
        
        environment {
            REGISTRY = config.registry ?: 'localhost:5000'
            SERVICE_NAME = config.serviceName
            SERVICE_PORT = config.port
        }
        
        stages {
            stage('Checkout') {
                steps {
                    script {
                        echo "Building ${SERVICE_NAME}..."
                    }
                }
            }
            // Common stages here
        }
    }
}
```

Usage in Jenkinsfile:
```groovy
@Library('shared-pipeline-library') _
buildMicroservice(
    serviceName: 'user-service',
    port: 3001,
    registry: 'localhost:5000'
)
```

---

## Pipeline Templates

### Template 1: Node.js Microservice Pipeline

```groovy
// Jenkinsfile for user-service
pipeline {
    agent any
    
    environment {
        REGISTRY = 'localhost:5000'
        SERVICE_NAME = 'user-service'
        SERVICE_PORT = '3001'
        IMAGE_NAME = "${REGISTRY}/${SERVICE_NAME}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "🔄 Checking out ${SERVICE_NAME}"
                    env.APP_VERSION = sh(
                        script: "cat package.json | grep version | head -1 | awk -F: '{ print \$2 }' | sed 's/[\",]//g' | tr -d '[[:space:]]'",
                        returnStdout: true
                    ).trim()
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
                script {
                    echo "📦 Installing dependencies..."
                    sh '''
                        npm install -g pnpm || true
                        pnpm install --frozen-lockfile
                    '''
                }
            }
        }
        
        stage('Lint & Test') {
            parallel {
                stage('Lint') {
                    steps {
                        sh 'pnpm run lint || true'
                    }
                }
                stage('Unit Tests') {
                    steps {
                        sh 'pnpm run test:ci'
                    }
                    post {
                        always {
                            junit testResults: 'junit.xml', allowEmptyResults: true
                            publishHTML(target: [
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: 'coverage/lcov-report',
                                reportFiles: 'index.html',
                                reportName: 'Coverage Report'
                            ])
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'test'
                    branch 'main'
                }
            }
            steps {
                script {
                    def imageTag = determineImageTag()
                    env.IMAGE_TAG = imageTag
                    
                    echo "🐳 Building Docker image: ${IMAGE_NAME}:${imageTag}"
                    sh """
                        docker build \
                            --build-arg SERVICE_PORT=${SERVICE_PORT} \
                            --build-arg VERSION=${env.APP_VERSION} \
                            --build-arg BUILD_DATE=\$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                            --build-arg VCS_REF=${env.GIT_COMMIT_SHORT} \
                            -t ${IMAGE_NAME}:${imageTag} \
                            .
                    """
                    
                    // Tag as latest for main branch
                    if (env.BRANCH_NAME == 'main') {
                        sh "docker tag ${IMAGE_NAME}:${imageTag} ${IMAGE_NAME}:latest"
                    }
                }
            }
        }
        
        stage('Security Scan') {
            when {
                anyOf {
                    branch 'test'
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "🔒 Running security scan..."
                    sh """
                        trivy image \
                            --severity HIGH,CRITICAL \
                            --format json \
                            --output trivy-report.json \
                            ${IMAGE_NAME}:${env.IMAGE_TAG}
                    """
                }
            }
        }
        
        stage('Push to Registry') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'test'
                    branch 'main'
                }
            }
            steps {
                script {
                    echo "📤 Pushing to registry..."
                    sh "docker push ${IMAGE_NAME}:${env.IMAGE_TAG}"
                    
                    if (env.BRANCH_NAME == 'main') {
                        sh "docker push ${IMAGE_NAME}:latest"
                    }
                }
            }
        }
        
        stage('Deploy to Test Environment') {
            when {
                branch 'test'
            }
            steps {
                script {
                    echo "🚀 Deploying to test environment..."
                    // Trigger deployment pipeline or update docker-compose
                    build job: 'deploy-to-test',
                          parameters: [
                              string(name: 'SERVICE_NAME', value: SERVICE_NAME),
                              string(name: 'IMAGE_TAG', value: env.IMAGE_TAG)
                          ],
                          wait: false
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    // Require manual approval for production
                    input message: 'Deploy to production?',
                          ok: 'Deploy',
                          submitter: 'admin,devops-team'
                    
                    echo "🚀 Deploying to production..."
                    build job: 'deploy-to-production',
                          parameters: [
                              string(name: 'SERVICE_NAME', value: SERVICE_NAME),
                              string(name: 'IMAGE_TAG', value: env.IMAGE_TAG)
                          ],
                          wait: true
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            script {
                echo "✅ ${SERVICE_NAME} pipeline completed successfully!"
                // Send notification (Slack, email, etc.)
            }
        }
        failure {
            script {
                echo "❌ ${SERVICE_NAME} pipeline failed!"
                // Send failure notification
            }
        }
    }
}

// Helper function to determine image tag
def determineImageTag() {
    switch(env.BRANCH_NAME) {
        case 'develop':
            return "dev-${env.BUILD_NUMBER}"
        case 'test':
            return "test-${env.APP_VERSION}-${env.BUILD_NUMBER}"
        case 'main':
            return "v${env.APP_VERSION}"
        default:
            return "feature-${env.BUILD_NUMBER}"
    }
}
```

### Template 2: Python Microservice Pipeline

```groovy
// Jenkinsfile for order-service (Python/FastAPI)
pipeline {
    agent any
    
    environment {
        REGISTRY = 'localhost:5000'
        SERVICE_NAME = 'order-service'
        SERVICE_PORT = '3002'
        IMAGE_NAME = "${REGISTRY}/${SERVICE_NAME}"
        PYTHON_VERSION = '3.11'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "🔄 Checking out ${SERVICE_NAME}"
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Setup Python Environment') {
            steps {
                script {
                    sh '''
                        python3 -m venv venv
                        . venv/bin/activate
                        pip install --upgrade pip
                        pip install -r requirements.txt
                        pip install -r requirements-dev.txt
                    '''
                }
            }
        }
        
        stage('Code Quality & Tests') {
            parallel {
                stage('Lint with Flake8') {
                    steps {
                        sh '''
                            . venv/bin/activate
                            flake8 app/ --max-line-length=120 --statistics
                        '''
                    }
                }
                stage('Type Check with MyPy') {
                    steps {
                        sh '''
                            . venv/bin/activate
                            mypy app/
                        '''
                    }
                }
                stage('Run Tests') {
                    steps {
                        sh '''
                            . venv/bin/activate
                            pytest tests/ \
                                --cov=app \
                                --cov-report=html \
                                --cov-report=xml \
                                --junitxml=junit.xml
                        '''
                    }
                    post {
                        always {
                            junit testResults: 'junit.xml', allowEmptyResults: true
                            publishHTML(target: [
                                reportDir: 'htmlcov',
                                reportFiles: 'index.html',
                                reportName: 'Coverage Report'
                            ])
                        }
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'test'
                    branch 'main'
                }
            }
            steps {
                script {
                    def imageTag = determineImageTag()
                    env.IMAGE_TAG = imageTag
                    
                    sh """
                        docker build \
                            --build-arg PYTHON_VERSION=${PYTHON_VERSION} \
                            --build-arg SERVICE_PORT=${SERVICE_PORT} \
                            -t ${IMAGE_NAME}:${imageTag} \
                            .
                    """
                }
            }
        }
        
        stage('Push & Deploy') {
            when {
                anyOf {
                    branch 'test'
                    branch 'main'
                }
            }
            steps {
                script {
                    sh "docker push ${IMAGE_NAME}:${env.IMAGE_TAG}"
                    
                    // Trigger deployment
                    def environment = env.BRANCH_NAME == 'main' ? 'production' : 'test'
                    build job: "deploy-to-${environment}",
                          parameters: [
                              string(name: 'SERVICE_NAME', value: SERVICE_NAME),
                              string(name: 'IMAGE_TAG', value: env.IMAGE_TAG)
                          ]
                }
            }
        }
    }
}

def determineImageTag() {
    switch(env.BRANCH_NAME) {
        case 'develop':
            return "dev-${env.BUILD_NUMBER}"
        case 'test':
            return "test-${env.BUILD_NUMBER}"
        case 'main':
            return "prod-${env.BUILD_NUMBER}"
        default:
            return "feature-${env.BUILD_NUMBER}"
    }
}
```

---

## Service Communication

### Docker Compose Configuration

#### Development Environment

```yaml
# docker-compose.dev.yml
version: '3.8'

networks:
  microservices-network:
    driver: bridge

services:
  # User Service
  user-service:
    build:
      context: ./user-service
      dockerfile: Dockerfile
    container_name: user-service
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=development
      - PORT=3001
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=users_db
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - ORDER_SERVICE_URL=http://order-service:3002
    networks:
      - microservices-network
    depends_on:
      - postgres
      - redis
    volumes:
      - ./user-service:/app
      - /app/node_modules
    command: npm run dev

  # Order Service
  order-service:
    build:
      context: ./order-service
      dockerfile: Dockerfile
    container_name: order-service
    ports:
      - "3002:3002"
    environment:
      - PYTHON_ENV=development
      - PORT=3002
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_NAME=orders_db
      - REDIS_HOST=redis
      - USER_SERVICE_URL=http://user-service:3001
      - PAYMENT_SERVICE_URL=http://payment-service:3003
    networks:
      - microservices-network
    depends_on:
      - postgres
      - redis
    volumes:
      - ./order-service:/app

  # Payment Service
  payment-service:
    build:
      context: ./payment-service
      dockerfile: Dockerfile
    container_name: payment-service
    ports:
      - "3003:3003"
    environment:
      - NODE_ENV=development
      - PORT=3003
      - DB_HOST=postgres
      - REDIS_HOST=redis
      - ORDER_SERVICE_URL=http://order-service:3002
    networks:
      - microservices-network
    depends_on:
      - postgres
      - redis

  # API Gateway
  api-gateway:
    build:
      context: ./api-gateway
      dockerfile: Dockerfile
    container_name: api-gateway
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
      - PORT=3000
      - USER_SERVICE_URL=http://user-service:3001
      - ORDER_SERVICE_URL=http://order-service:3002
      - PAYMENT_SERVICE_URL=http://payment-service:3003
      - REDIS_HOST=redis
    networks:
      - microservices-network
    depends_on:
      - user-service
      - order-service
      - payment-service

  # PostgreSQL Database
  postgres:
    image: postgres:15-alpine
    container_name: postgres
    ports:
      - "5432:5432"
    environment:
      - POSTGRES_USER=admin
      - POSTGRES_PASSWORD=password
      - POSTGRES_MULTIPLE_DATABASES=users_db,orders_db,payments_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init-scripts:/docker-entrypoint-initdb.d
    networks:
      - microservices-network

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - microservices-network

  # Message Queue (RabbitMQ)
  rabbitmq:
    image: rabbitmq:3-management-alpine
    container_name: rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      - RABBITMQ_DEFAULT_USER=admin
      - RABBITMQ_DEFAULT_PASS=password
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - microservices-network

volumes:
  postgres_data:
  redis_data:
  rabbitmq_data:
```

#### Test/Production Environment

```yaml
# docker-compose.test.yml
version: '3.8'

networks:
  microservices-network:
    driver: bridge

services:
  user-service:
    image: localhost:5000/user-service:${USER_SERVICE_TAG:-latest}
    container_name: user-service
    restart: unless-stopped
    ports:
      - "3001:3001"
    environment:
      - NODE_ENV=test
      - PORT=3001
      - DB_HOST=postgres
      - ORDER_SERVICE_URL=http://order-service:3002
    networks:
      - microservices-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  order-service:
    image: localhost:5000/order-service:${ORDER_SERVICE_TAG:-latest}
    container_name: order-service
    restart: unless-stopped
    ports:
      - "3002:3002"
    environment:
      - PYTHON_ENV=test
      - PORT=3002
      - DB_HOST=postgres
      - USER_SERVICE_URL=http://user-service:3001
    networks:
      - microservices-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3002/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  payment-service:
    image: localhost:5000/payment-service:${PAYMENT_SERVICE_TAG:-latest}
    container_name: payment-service
    restart: unless-stopped
    ports:
      - "3003:3003"
    environment:
      - NODE_ENV=test
      - PORT=3003
      - ORDER_SERVICE_URL=http://order-service:3002
    networks:
      - microservices-network

  api-gateway:
    image: localhost:5000/api-gateway:${API_GATEWAY_TAG:-latest}
    container_name: api-gateway
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=test
      - PORT=3000
      - USER_SERVICE_URL=http://user-service:3001
      - ORDER_SERVICE_URL=http://order-service:3002
      - PAYMENT_SERVICE_URL=http://payment-service:3003
    networks:
      - microservices-network
    depends_on:
      user-service:
        condition: service_healthy
      order-service:
        condition: service_healthy

  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      - POSTGRES_USER=admin
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - microservices-network

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    networks:
      - microservices-network

volumes:
  postgres_data:
```

### Service Communication Patterns

#### 1. Synchronous HTTP Communication

**User Service calling Order Service:**

```javascript
// user-service/src/services/orderService.js
const axios = require('axios');

class OrderService {
  constructor() {
    this.baseURL = process.env.ORDER_SERVICE_URL || 'http://order-service:3002';
    this.client = axios.create({
      baseURL: this.baseURL,
      timeout: 5000,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }

  async getUserOrders(userId) {
    try {
      const response = await this.client.get(`/api/orders/user/${userId}`);
      return response.data;
    } catch (error) {
      console.error('Error fetching user orders:', error.message);
      throw new Error('Failed to fetch orders');
    }
  }

  async createOrder(userId, orderData) {
    try {
      const response = await this.client.post('/api/orders', {
        userId,
        ...orderData
      });
      return response.data;
    } catch (error) {
      console.error('Error creating order:', error.message);
      throw new Error('Failed to create order');
    }
  }
}

module.exports = new OrderService();
```

#### 2. Asynchronous Message Queue Communication

**Using RabbitMQ:**

```javascript
// shared/messaging/rabbitmq.js
const amqp = require('amqplib');

class MessageQueue {
  constructor() {
    this.connection = null;
    this.channel = null;
  }

  async connect() {
    try {
      this.connection = await amqp.connect(
        process.env.RABBITMQ_URL || 'amqp://admin:password@rabbitmq:5672'
      );
      this.channel = await this.connection.createChannel();
      console.log('✅ Connected to RabbitMQ');
    } catch (error) {
      console.error('❌ RabbitMQ connection failed:', error);
      setTimeout(() => this.connect(), 5000); // Retry
    }
  }

  async publish(queue, message) {
    await this.channel.assertQueue(queue, { durable: true });
    this.channel.sendToQueue(
      queue,
      Buffer.from(JSON.stringify(message)),
      { persistent: true }
    );
  }

  async subscribe(queue, callback) {
    await this.channel.assertQueue(queue, { durable: true });
    this.channel.consume(queue, async (msg) => {
      if (msg) {
        const content = JSON.parse(msg.content.toString());
        await callback(content);
        this.channel.ack(msg);
      }
    });
  }
}

module.exports = new MessageQueue();
```

**Publishing events:**

```javascript
// order-service/src/controllers/orderController.js
const messageQueue = require('../messaging/rabbitmq');

async function createOrder(req, res) {
  const order = await Order.create(req.body);
  
  // Publish event to queue
  await messageQueue.publish('order.created', {
    orderId: order.id,
    userId: order.userId,
    amount: order.amount,
    timestamp: new Date()
  });
  
  res.json(order);
}
```

**Subscribing to events:**

```javascript
// payment-service/src/subscribers/orderSubscriber.js
const messageQueue = require('../messaging/rabbitmq');

async function handleOrderCreated(data) {
  console.log('Processing payment for order:', data.orderId);
  // Process payment logic
}

// Start listening
messageQueue.subscribe('order.created', handleOrderCreated);
```

#### 3. Service Discovery Pattern

```javascript
// shared/service-discovery.js
const axios = require('axios');

class ServiceRegistry {
  constructor() {
    this.services = {
      'user-service': process.env.USER_SERVICE_URL || 'http://user-service:3001',
      'order-service': process.env.ORDER_SERVICE_URL || 'http://order-service:3002',
      'payment-service': process.env.PAYMENT_SERVICE_URL || 'http://payment-service:3003'
    };
  }

  getServiceUrl(serviceName) {
    return this.services[serviceName];
  }

  async callService(serviceName, endpoint, options = {}) {
    const baseURL = this.getServiceUrl(serviceName);
    const client = axios.create({ baseURL, timeout: 5000 });
    
    try {
      const response = await client.request({
        url: endpoint,
        ...options
      });
      return response.data;
    } catch (error) {
      console.error(`Error calling ${serviceName}:`, error.message);
      throw error;
    }
  }
}

module.exports = new ServiceRegistry();
```

---

## Deployment Strategies

### Deployment Pipeline

```groovy
// Jenkinsfile for deployment
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['test', 'staging', 'production'],
            description: 'Target environment'
        )
        string(
            name: 'USER_SERVICE_TAG',
            defaultValue: 'latest',
            description: 'User service image tag'
        )
        string(
            name: 'ORDER_SERVICE_TAG',
            defaultValue: 'latest',
            description: 'Order service image tag'
        )
        string(
            name: 'PAYMENT_SERVICE_TAG',
            defaultValue: 'latest',
            description: 'Payment service image tag'
        )
        string(
            name: 'API_GATEWAY_TAG',
            defaultValue: 'latest',
            description: 'API Gateway image tag'
        )
    }
    
    environment {
        COMPOSE_FILE = "docker-compose.${params.ENVIRONMENT}.yml"
        DEPLOY_HOST = getDeployHost(params.ENVIRONMENT)
    }
    
    stages {
        stage('Validate Images') {
            steps {
                script {
                    echo "🔍 Validating images exist in registry..."
                    def services = [
                        'user-service': params.USER_SERVICE_TAG,
                        'order-service': params.ORDER_SERVICE_TAG,
                        'payment-service': params.PAYMENT_SERVICE_TAG,
                        'api-gateway': params.API_GATEWAY_TAG
                    ]
                    
                    services.each { service, tag ->
                        sh """
                            docker pull localhost:5000/${service}:${tag} || {
                                echo "❌ Image not found: ${service}:${tag}"
                                exit 1
                            }
                        """
                    }
                }
            }
        }
        
        stage('Backup Current State') {
            when {
                expression { params.ENVIRONMENT == 'production' }
            }
            steps {
                script {
                    echo "💾 Creating backup..."
                    sh """
                        ssh ${DEPLOY_HOST} '
                            docker-compose -f ${COMPOSE_FILE} config > backup-\$(date +%Y%m%d-%H%M%S).yml
                        '
                    """
                }
            }
        }
        
        stage('Deploy Services') {
            steps {
                script {
                    echo "🚀 Deploying to ${params.ENVIRONMENT}..."
                    
                    // Copy compose file to deployment host
                    sh """
                        scp ${COMPOSE_FILE} ${DEPLOY_HOST}:/opt/microservices/
                    """
                    
                    // Deploy services
                    sh """
                        ssh ${DEPLOY_HOST} '
                            cd /opt/microservices
                            
                            export USER_SERVICE_TAG=${params.USER_SERVICE_TAG}
                            export ORDER_SERVICE_TAG=${params.ORDER_SERVICE_TAG}
                            export PAYMENT_SERVICE_TAG=${params.PAYMENT_SERVICE_TAG}
                            export API_GATEWAY_TAG=${params.API_GATEWAY_TAG}
                            
                            # Pull latest images
                            docker-compose -f ${COMPOSE_FILE} pull
                            
                            # Deploy with zero-downtime
                            docker-compose -f ${COMPOSE_FILE} up -d --no-deps --build
                            
                            # Wait for services to be healthy
                            sleep 10
                            docker-compose -f ${COMPOSE_FILE} ps
                        '
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    echo "🏥 Running health checks..."
                    sh """
                        ssh ${DEPLOY_HOST} '
                            # Check each service
                            curl -f http://localhost:3001/health || exit 1
                            curl -f http://localhost:3002/health || exit 1
                            curl -f http://localhost:3003/health || exit 1
                            curl -f http://localhost:3000/health || exit 1
                        '
                    """
                }
            }
        }
        
        stage('Smoke Tests') {
            steps {
                script {
                    echo "🧪 Running smoke tests..."
                    sh """
                        ssh ${DEPLOY_HOST} '
                            # Run basic integration tests
                            cd /opt/microservices/tests
                            npm run test:smoke
                        '
                    """
                }
            }
        }
        
        stage('Rollback on Failure') {
            when {
                expression { currentBuild.result == 'FAILURE' }
            }
            steps {
                script {
                    echo "⚠️ Deployment failed, rolling back..."
                    sh """
                        ssh ${DEPLOY_HOST} '
                            cd /opt/microservices
                            docker-compose -f ${COMPOSE_FILE} down
                            # Restore from backup
                            # docker-compose -f backup-latest.yml up -d
                        '
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Deployment to ${params.ENVIRONMENT} successful!"
        }
        failure {
            echo "❌ Deployment to ${params.ENVIRONMENT} failed!"
        }
    }
}

def getDeployHost(environment) {
    switch(environment) {
        case 'test':
            return 'deploy@test-server.example.com'
        case 'staging':
            return 'deploy@staging-server.example.com'
        case 'production':
            return 'deploy@prod-server.example.com'
        default:
            return 'deploy@test-server.example.com'
    }
}
```

### Blue-Green Deployment Script

```bash
#!/bin/bash
# deploy-blue-green.sh

ENVIRONMENT=$1
SERVICE_NAME=$2
NEW_TAG=$3

CURRENT_COLOR=$(docker-compose ps | grep ${SERVICE_NAME} | grep -o 'blue\|green' | head -1)
NEW_COLOR=$([ "$CURRENT_COLOR" = "blue" ] && echo "green" || echo "blue")

echo "Current: $CURRENT_COLOR, Deploying: $NEW_COLOR"

# Start new version
docker-compose up -d ${SERVICE_NAME}-${NEW_COLOR}

# Wait for health check
sleep 10
curl -f http://localhost:3000/health || exit 1

# Switch traffic (update load balancer/nginx)
./switch-traffic.sh ${SERVICE_NAME} ${NEW_COLOR}

# Stop old version
docker-compose stop ${SERVICE_NAME}-${CURRENT_COLOR}

echo "✅ Deployment complete: ${SERVICE_NAME} now running on ${NEW_COLOR}"
```

---

## Best Practices

### 1. Environment Variables Management

```bash
# .env.example for each service
NODE_ENV=development
PORT=3001
LOG_LEVEL=info

# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mydb
DB_USER=admin
DB_PASSWORD=

# Service URLs
USER_SERVICE_URL=http://user-service:3001
ORDER_SERVICE_URL=http://order-service:3002
PAYMENT_SERVICE_URL=http://payment-service:3003

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# RabbitMQ
RABBITMQ_URL=amqp://admin:password@rabbitmq:5672

# Monitoring
ENABLE_METRICS=true
METRICS_PORT=9090
```

### 2. Health Check Endpoints

```javascript
// health-check.js (reusable for all Node.js services)
const express = require('express');
const router = express.Router();

router.get('/health', async (req, res) => {
  const health = {
    status: 'UP',
    timestamp: new Date().toISOString(),
    service: process.env.SERVICE_NAME,
    version: process.env.APP_VERSION,
    checks: {}
  };

  // Database check
  try {
    await db.ping();
    health.checks.database = 'UP';
  } catch (error) {
    health.checks.database = 'DOWN';
    health.status = 'DEGRADED';
  }

  // Redis check
  try {
    await redis.ping();
    health.checks.redis = 'UP';
  } catch (error) {
    health.checks.redis = 'DOWN';
  }

  const statusCode = health.status === 'UP' ? 200 : 503;
  res.status(statusCode).json(health);
});

router.get('/ready', async (req, res) => {
  // Readiness check - can accept traffic
  res.json({ ready: true });
});

router.get('/live', (req, res) => {
  // Liveness check - service is running
  res.json({ alive: true });
});

module.exports = router;
```

### 3. Centralized Logging

```javascript
// shared/logger.js
const winston = require('winston');

const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: {
    service: process.env.SERVICE_NAME,
    version: process.env.APP_VERSION
  },
  transports: [
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize(),
        winston.format.simple()
      )
    })
    // Add remote logging (e.g., ELK, CloudWatch)
  ]
});

module.exports = logger;
```

### 4. API Versioning

```javascript
// api-gateway/src/routes/index.js
const express = require('express');
const router = express.Router();

// API v1
router.use('/v1/users', require('./v1/users'));
router.use('/v1/orders', require('./v1/orders'));
router.use('/v1/payments', require('./v1/payments'));

// API v2 (when you need breaking changes)
router.use('/v2/users', require('./v2/users'));

module.exports = router;
```

### 5. Monitoring and Metrics

```yaml
# docker-compose.monitoring.yml
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    networks:
      - microservices-network

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - microservices-network

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"
      - "14268:14268"
    networks:
      - microservices-network

volumes:
  prometheus_data:
  grafana_data:
```

### 6. Security Best Practices

- Use secrets management (HashiCorp Vault, AWS Secrets Manager)
- Implement API authentication (JWT, OAuth2)
- Network segmentation with Docker networks
- Regular security scanning in pipeline
- Rate limiting and DDoS protection
- HTTPS/TLS for all external communication

### 7. Testing Strategy

```groovy
// Integration test stage
stage('Integration Tests') {
    steps {
        script {
            sh '''
                # Start services with docker-compose
                docker-compose -f docker-compose.test.yml up -d
                
                # Wait for services
                sleep 20
                
                # Run integration tests
                npm run test:integration
                
                # Cleanup
                docker-compose -f docker-compose.test.yml down
            '''
        }
    }
}
```

---

## Quick Start Checklist

- [ ] Set up Jenkins server with required plugins
- [ ] Create GitHub repositories for each microservice
- [ ] Add Jenkinsfile to each repository
- [ ] Configure Jenkins multibranch pipelines
- [ ] Set up Docker registry
- [ ] Create docker-compose files for each environment
- [ ] Implement health check endpoints
- [ ] Configure service-to-service communication
- [ ] Set up monitoring and logging
- [ ] Create deployment pipelines
- [ ] Test the entire flow
- [ ] Document the architecture

---

## Troubleshooting

### Common Issues

**Issue: Services can't communicate**
```bash
# Check network connectivity
docker network inspect microservices-network
docker exec -it user-service ping order-service
```

**Issue: Pipeline fails on image push**
```bash
# Check registry connectivity
curl http://localhost:5000/v2/_catalog
docker login localhost:5000
```

**Issue: Container health checks failing**
```bash
# Check container logs
docker-compose logs service-name
docker inspect service-name
```

---

This guide provides a comprehensive foundation for building a multi-microservice CI/CD pipeline with Jenkins. Adjust based on your specific requirements and scale.