#!/bin/bash
# ============================================
# Nito's Pizza - Script de inicio para Railway
# ============================================
# REGLA 1: PORT siempre desde process.env.PORT
# REGLA 2: Host siempre 0.0.0.0

set -e

echo "============================================"
echo "  NITO'S PIZZA - Iniciando en Railway"
echo "============================================"
echo "PORT: ${PORT:-3000}"
echo "HOST: 0.0.0.0"
echo "NODE_ENV: ${NODE_ENV:-production}"
echo "DATABASE_URL set: $([ -n "$DATABASE_URL" ] && echo 'YES' || echo 'NO')"
echo "============================================"

# Generar cliente Prisma
echo "[1/4] Generando cliente Prisma..."
npx prisma generate

# Hacer push del esquema a la base de datos
echo "[2/4] Sincronizando base de datos (db push)..."
npx prisma db push --skip-generate

# Si no hay productos, hacer seed
echo "[3/4] Verificando datos iniciales..."
SEED_NEEDED=0
node -e "
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
prisma.product.count().then(count => {
  if (count === 0) {
    console.log('No hay productos, ejecutando seed...');
    process.exit(2);
  } else {
    console.log('Base de datos ya tiene ' + count + ' productos.');
    process.exit(0);
  }
}).catch(err => {
  console.error('Error checking DB:', err.message);
  process.exit(1);
});
" || SEED_NEEDED=$?

if [ "$SEED_NEEDED" = "2" ]; then
  echo "Ejecutando seed..."
  npx tsx prisma/seed.ts
fi

# Copiar estáticos al standalone build (si existe)
echo "[4/4] Verificando estáticos..."
if [ -d ".next/standalone" ]; then
  cp -r .next/static .next/standalone/.next/static 2>/dev/null || true
  cp -r public .next/standalone/public 2>/dev/null || true
  echo "Estáticos copiados al standalone build."
fi

# Iniciar el servidor
echo "Iniciando servidor en 0.0.0.0:\${PORT:-3000}..."
exec node server.ts
