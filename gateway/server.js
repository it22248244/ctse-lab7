const express = require('express');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'gateway',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'CTSE Lab 7 - API Gateway',
    status: 'running',
    endpoints: ['/health', '/api/status', '/api/services']
  });
});

// API status endpoint
app.get('/api/status', (req, res) => {
  res.status(200).json({
    gateway: 'online',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Services listing endpoint
app.get('/api/services', (req, res) => {
  res.status(200).json({
    services: [
      { name: 'gateway', status: 'online', port: PORT }
    ]
  });
});

// Catch-all for unknown routes
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found', path: req.path });
});

app.listen(PORT, () => {
  console.log(`Gateway service running on port ${PORT}`);
});

module.exports = app;
