#!/bin/sh

set -e

echo "============================================"
echo "  NITO'S PIZZA - Iniciando en Railway"
echo "============================================"
echo "PORT: ${PORT:-3000}"
echo "HOST: 0.0.0.0"
echo "NODE_ENV: ${NODE_ENV:-production}"
echo "DATABASE_URL set: $([ -n "$DATABASE_URL" ] && echo 'YES' || echo 'NO')"
echo "============================================"

echo "[1/4] Generando cliente Prisma..."
npx prisma generate

echo "[2/4] Sincronizando base de datos..."
npx prisma db push --skip-generate

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
echo "Iniciando servidor..."
echo "============================================"

exec node server.js