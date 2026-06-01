#!/bin/sh

set -e

echo "============================================"
echo "  NITO'S PIZZA - Iniciando en Railway"
echo "============================================"
CURRENT_PORT="${PORT:-3000}"
echo "PORT: $CURRENT_PORT"
echo "HOST: 0.0.0.0"
echo "NODE_ENV: ${NODE_ENV:-production}"
echo "============================================"

echo "Iniciando servidor..."
echo "============================================"

# server.js is at /app/server.js — standalone contents were extracted directly by the Dockerfile
PORT=$CURRENT_PORT HOSTNAME=0.0.0.0 exec node server.js

