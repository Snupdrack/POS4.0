FROM oven/bun:1 AS base
WORKDIR /app

# Install dependencies
FROM base AS deps
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

# Build
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN bunx prisma generate
RUN bun run build

# Copy static assets to standalone build
RUN cp -r .next/static .next/standalone/.next/static
RUN cp -r public .next/standalone/public

# Production
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0

# CORRECCIÓN: Comandos nativos para la imagen de Bun (Debian)
RUN groupadd --system --gid 1001 nodejs || true
RUN useradd --system --uid 1001 -g nodejs nextjs || true

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/railway-start.sh ./railway-start.sh

# Dar permisos al script de arranque
RUN chmod +x railway-start.sh

USER nextjs

EXPOSE 3000

CMD ["bash", "railway-start.sh"]
