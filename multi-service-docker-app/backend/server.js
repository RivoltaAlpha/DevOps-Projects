const express = require('express');
const mongoose = require('mongoose');
const redis = require('redis');
const cors = require('cors');
const morgan = require('morgan');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Logging setup
const logDirectory = path.join(__dirname, 'logs');
if (!fs.existsSync(logDirectory)) {
  fs.mkdirSync(logDirectory);
}

const accessLogStream = fs.createWriteStream(
  path.join(logDirectory, 'access.log'),
  { flags: 'a' }
);

app.use(morgan('combined', { stream: accessLogStream }));
app.use(morgan('dev')); // Console logging

// Read database password from Docker secret
let dbPassword;
try {
  dbPassword = fs.readFileSync('/run/secrets/db_password', 'utf8').trim();
  console.log('✓ Successfully read database password from secrets');
} catch (err) {
  console.warn('⚠ Could not read db_password secret, using environment variable');
  dbPassword = process.env.MONGO_PASSWORD || 'password123';
}

// MongoDB connection
const MONGO_URI = `mongodb://${process.env.MONGO_USER || 'admin'}:${dbPassword}@${process.env.MONGO_HOST || 'mongodb'}:27017/${process.env.MONGO_DB || 'appdb'}?authSource=admin`;

mongoose.connect(MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
  .then(() => console.log('✓ Connected to MongoDB'))
  .catch((err) => console.error('✗ MongoDB connection error:', err));

// Redis client setup
const redisClient = redis.createClient({
  socket: {
    host: process.env.REDIS_HOST || 'redis',
    port: process.env.REDIS_PORT || 6379,
  },
});

redisClient.on('error', (err) => console.error('Redis Client Error', err));
redisClient.on('connect', () => console.log('✓ Connected to Redis'));

(async () => {
  await redisClient.connect();
})();

// Mongoose Schema
const itemSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

const Item = mongoose.model('Item', itemSchema);

// Routes

// Health check endpoint
app.get('/health', (req, res) => {
  const health = {
    uptime: process.uptime(),
    message: 'OK',
    timestamp: Date.now(),
    mongodb: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    redis: redisClient.isOpen ? 'connected' : 'disconnected',
  };
  res.status(200).json(health);
});

// Get all items (with Redis caching)
app.get('/api/items', async (req, res) => {
  try {
    // Try to get from cache first
    const cachedItems = await redisClient.get('items');
    
    if (cachedItems) {
      console.log('✓ Cache hit - returning cached items');
      return res.json(JSON.parse(cachedItems));
    }

    console.log('✗ Cache miss - fetching from database');
    const items = await Item.find().sort({ createdAt: -1 });
    
    // Store in cache for 60 seconds
    await redisClient.setEx('items', 60, JSON.stringify(items));
    
    res.json(items);
  } catch (error) {
    console.error('Error fetching items:', error);
    res.status(500).json({ error: 'Failed to fetch items' });
  }
});

// Create new item
app.post('/api/items', async (req, res) => {
  try {
    const { name } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ error: 'Item name is required' });
    }

    const item = new Item({ name: name.trim() });
    await item.save();

    // Invalidate cache
    await redisClient.del('items');
    console.log('✓ Cache invalidated after creating item');

    res.status(201).json(item);
  } catch (error) {
    console.error('Error creating item:', error);
    res.status(500).json({ error: 'Failed to create item' });
  }
});

// Delete item
app.delete('/api/items/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const item = await Item.findByIdAndDelete(id);

    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }

    // Invalidate cache
    await redisClient.del('items');
    console.log('✓ Cache invalidated after deleting item');

    res.json({ message: 'Item deleted successfully' });
  } catch (error) {
    console.error('Error deleting item:', error);
    res.status(500).json({ error: 'Failed to delete item' });
  }
});

// Get cache stats
app.get('/api/stats', async (req, res) => {
  try {
    const itemCount = await Item.countDocuments();
    const cacheExists = await redisClient.exists('items');
    
    res.json({
      totalItems: itemCount,
      cacheStatus: cacheExists ? 'cached' : 'not cached',
      uptime: process.uptime(),
    });
  } catch (error) {
    console.error('Error getting stats:', error);
    res.status(500).json({ error: 'Failed to get stats' });
  }
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`✓ Server running on port ${PORT}`);
  console.log(`✓ Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM signal received: closing HTTP server');
  await redisClient.quit();
  await mongoose.connection.close();
  process.exit(0);
});
