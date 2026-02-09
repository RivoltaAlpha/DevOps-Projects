import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [items, setItems] = useState([]);
  const [newItem, setNewItem] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const API_URL = '/api';

  useEffect(() => {
    fetchItems();
  }, []);

  const fetchItems = async () => {
    try {
      setLoading(true);
      const response = await fetch(`${API_URL}/items`);
      if (!response.ok) throw new Error('Failed to fetch items');
      const data = await response.json();
      setItems(data);
      setError(null);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  const addItem = async (e) => {
    e.preventDefault();
    if (!newItem.trim()) return;

    try {
      const response = await fetch(`${API_URL}/items`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name: newItem }),
      });
      
      if (!response.ok) throw new Error('Failed to add item');
      
      setNewItem('');
      fetchItems();
    } catch (err) {
      setError(err.message);
    }
  };

  const deleteItem = async (id) => {
    try {
      const response = await fetch(`${API_URL}/items/${id}`, {
        method: 'DELETE',
      });
      
      if (!response.ok) throw new Error('Failed to delete item');
      
      fetchItems();
    } catch (err) {
      setError(err.message);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Multi-Service Docker Application</h1>
        <p className="subtitle">React + Node.js + MongoDB + Redis + Nginx</p>
      </header>

      <main className="container">
        {error && <div className="error">Error: {error}</div>}

        <form onSubmit={addItem} className="add-form">
          <input
            type="text"
            value={newItem}
            onChange={(e) => setNewItem(e.target.value)}
            placeholder="Enter new item..."
            className="input"
          />
          <button type="submit" className="btn btn-primary">
            Add Item
          </button>
        </form>

        <div className="items-container">
          <h2>Items List</h2>
          {loading ? (
            <p className="loading">Loading...</p>
          ) : items.length === 0 ? (
            <p className="empty">No items yet. Add one above!</p>
          ) : (
            <ul className="items-list">
              {items.map((item) => (
                <li key={item._id} className="item">
                  <span>{item.name}</span>
                  <button
                    onClick={() => deleteItem(item._id)}
                    className="btn btn-danger"
                  >
                    Delete
                  </button>
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="stats">
          <p>Total Items: {items.length}</p>
          <p className="info">Data is cached in Redis for performance</p>
        </div>
      </main>

      <footer className="footer">
        <p>Multi-Service Docker Application - Advanced Setup Demo</p>
      </footer>
    </div>
  );
}

export default App;
