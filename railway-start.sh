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

echo "[1/4] Generando cliente Prisma..."
bunx prisma@6 generate

echo "[2/4] Sincronizando base de datos..."
bunx prisma@6 db push --skip-generate

echo "[3/4] Verificando datos iniciales..."
SEED_NEEDED=0

node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

prisma.product.count()
.then(count => {
  if (count === 0) {
    console.log('No hay productos');
    process.exit(2);
  } else {
    console.log('Productos encontrados: ' + count);
    process.exit(0);
  }
})
.catch(err => {
  console.error(err);
  process.exit(1);
});
" || SEED_NEEDED=$?

if [ "$SEED_NEEDED" = "2" ]; then
  echo "Ejecutando seed..."
  npx tsx prisma/seed.ts
fi

echo "[4/4] Verificando estáticos..."
if [ -d ".next/standalone" ]; then
  mkdir -p .next/standalone/.next
  cp -r .next/static .next/standalone/.next/static 2>/dev/null || true
  cp -r public .next/standalone/public 2>/dev/null || true
  echo "Estáticos copiados."
fi

echo "============================================"
echo "Iniciando servidor optimizado..."
echo "============================================"

# Buscamos el servidor en la ruta real de standalone para evitar fallos de Healthcheck
if [ -f ".next/standalone/server.js" ]; then
  echo "Ejecutando desde la carpeta standalone..."
  cd .next/standalone
  PORT=$CURRENT_PORT HOSTNAME=0.0.0.0 exec node server.js
else
  echo "Ejecutando desde la raíz..."
  PORT=$CURRENT_PORT HOSTNAME=0.0.0.0 exec node server.js
fi
