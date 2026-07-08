# Railway: set RAILWAY_DOCKERFILE_PATH=Dockerfile.server in service variables
# Build context is always the repo root, so both server/ and shared/ are accessible.

# ---- Build stage ----
FROM node:20-alpine AS builder
WORKDIR /app

# shared/ must be available before server build (tsconfig paths: "@shared" -> "../shared")
COPY shared/package*.json ./shared/
RUN cd shared && npm install
COPY shared/ ./shared/

# Install server dependencies
COPY server/package*.json ./server/
RUN cd server && npm ci

# Copy server source files
COPY server/prisma ./server/prisma/
COPY server/nest-cli.json ./server/
COPY server/tsconfig*.json ./server/
COPY server/src ./server/src/

WORKDIR /app/server

# Generate Prisma client (also runs as part of npm run build, but needed early for type checks)
RUN npx prisma generate

# Build NestJS (webpack bundles @shared inline, so no runtime alias needed)
RUN npm run build

# Compile seed.ts -> dist-seed/prisma/seed.js
RUN npx tsc prisma/seed.ts \
      --outDir dist-seed \
      --module commonjs \
      --target ES2021 \
      --esModuleInterop \
      --skipLibCheck \
      --resolveJsonModule

# ---- Production stage ----
FROM node:20-alpine
WORKDIR /app/server

COPY --from=builder /app/server/package*.json ./
COPY --from=builder /app/server/prisma ./prisma/
COPY --from=builder /app/server/dist ./dist/
COPY --from=builder /app/server/dist-seed ./dist-seed/
COPY --from=builder /app/server/node_modules ./node_modules/

EXPOSE 3001

# Push schema to DB, seed, then start the API
CMD sh -c "npx prisma db push --accept-data-loss && node dist-seed/prisma/seed.js && node dist/server/src/main"
