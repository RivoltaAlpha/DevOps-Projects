// MongoDB initialization script
// This script runs when the MongoDB container is first created

db = db.getSiblingDB('appdb');

// Create a user for the application database
db.createUser({
  user: 'admin',
  pwd: 'password123',
  roles: [
    {
      role: 'readWrite',
      db: 'appdb'
    }
  ]
});

// Create initial collection with index
db.createCollection('items');
db.items.createIndex({ createdAt: -1 });

print('Database initialized successfully');
