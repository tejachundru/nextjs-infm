# Build from repo root so shared/ is available
# In Railway: set Root Directory to / and Dockerfile Path to server/Dockerfile

FROM node:20-alpine AS builder
WORKDIR /app

# Copy shared package first (needed for @shared alias resolution)
COPY shared/ ./shared/

# Copy server source
COPY server/package*.json ./server/
COPY server/prisma ./server/prisma/
COPY server/nest-cli.json ./server/
COPY server/tsconfig*.json ./server/
COPY server/src ./server/src/

WORKDIR /app/server

# Install all dependencies (including devDeps needed for build)
RUN npm ci

# Generate Prisma client
RUN npx prisma generate

# Build NestJS app
RUN npm run build

# Compile seed script to JS
RUN npx ts-node --version && \
    npx tsc prisma/seed.ts \
      --outDir dist-seed \
      --module commonjs \
      --target ES2021 \
      --esModuleInterop \
      --skipLibCheck \
      --resolveJsonModule

# ---- Production image ----
FROM node:20-alpine
WORKDIR /app/server

COPY --from=builder /app/server/package*.json ./
COPY --from=builder /app/server/prisma ./prisma/
COPY --from=builder /app/server/dist ./dist/
COPY --from=builder /app/server/dist-seed ./dist-seed/
COPY --from=builder /app/server/node_modules ./node_modules/

# Startup: migrate → seed → start server
COPY server/docker-entrypoint.sh ./
RUN chmod +x docker-entrypoint.sh

EXPOSE 3001

CMD ["./docker-entrypoint.sh"]
