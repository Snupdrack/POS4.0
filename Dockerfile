FROM oven/bun:1 AS base
WORKDIR /app

# ==========================
# Dependencias
# ==========================
FROM base AS deps

COPY package.json bun.lock ./
COPY prisma ./prisma/

RUN bun install --frozen-lockfile

# ==========================
# Build
# ==========================
FROM base AS builder

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN bunx prisma@6 generate
RUN bun run build

RUN cp -r .next/static .next/standalone/.next/static || true
RUN cp -r public .next/standalone/public || true

# ==========================
# Runtime
# ==========================
FROM oven/bun:1 AS runner

WORKDIR /app

# Mantenemos las variables de producción globales
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0

# Copiamos todo el contenido compilado
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/railway-start.sh ./railway-start.sh

# Aseguramos los permisos del script de inicio
RUN chmod +x railway-start.sh

# CORRECCIÓN DE PUERTO: Railway usa el puerto dinámico asignado a la variable PORT (usualmente 8080)
EXPOSE 8080

# Ejecutamos el inicio directamente para evitar bloqueos de permisos en Prisma
CMD ["bash", "railway-start.sh"]
