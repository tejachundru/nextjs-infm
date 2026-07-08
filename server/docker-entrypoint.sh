#!/bin/sh
set -e

echo "⏳ Pushing schema to database..."
npx prisma db push --accept-data-loss

echo "🌱 Seeding database..."
node dist-seed/prisma/seed.js

echo "🚀 Starting server..."
exec node dist/server/src/main
