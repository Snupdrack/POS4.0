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

RUN bunx prisma generate
RUN bun run build

RUN cp -r .next/static .next/standalone/.next/static || true
RUN cp -r public .next/standalone/public || true

# ==========================
# Runtime
# ==========================
FROM oven/bun:1 AS runner

WORKDIR /app

RUN groupadd --system --gid 1001 nodejs || true
RUN useradd --system --uid 1001 -g nodejs nextjs || true

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/railway-start.sh ./railway-start.sh

RUN chmod 755 railway-start.sh
RUN chown -R nextjs:nodejs /app

ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0

USER nextjs

EXPOSE 3000

CMD ["sh", "./railway-start.sh"]