#!/bin/sh

set -e

echo "============================================"
echo "  NITO'S PIZZA - Iniciando en Railway"
echo "============================================"
# Forzamos a que si Railway da un puerto (ej. 8080) se use ese, si no, usa 3000 por defecto
CURRENT_PORT="${PORT:-3000}"
echo "PORT: $CURRENT_PORT"
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
echo "Iniciando servidor optimizado..."
echo "============================================"

# SOLUCIÓN: Si Next.js generó el standalone, entramos a la carpeta para ejecutar el server real
if [ -f ".next/standalone/server.js" ]; then
  echo "Ejecutando servidor desde la carpeta standalone..."
  cd .next/standalone
  PORT=$CURRENT_PORT HOST=0.0.0.0 exec node server.js
else
  echo "Servidor standalone no encontrado, intentando arranque directo..."
  PORT=$CURRENT_PORT HOST=0.0.0.0 exec node server.js
fi
