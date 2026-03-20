# Use official lightweight Node.js 18 image
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy dependency files first (layer caching)
COPY package*.json ./

# Install production dependencies only
RUN npm install --production

# Copy application source code
COPY . .

# Expose the port the gateway listens on
EXPOSE 3000

# Start the gateway service
CMD ["node", "server.js"]
