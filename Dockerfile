# FROM node:20-alpine AS test
# WORKDIR /app
# COPY package*.json ./
# RUN npm ci
# COPY src ./src
# COPY test ./test
# RUN npm test

# FROM node:20-alpine AS production
# WORKDIR /app
# ENV NODE_ENV=production
# COPY package*.json ./
# RUN npm ci --omit=dev
# COPY src ./src
# USER node
# EXPOSE 3000
# HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -qO- http://127.0.0.1:3000/health >/dev/null || exit 1
# CMD ["node", "src/index.js"]

#----------------------------
# FICHIER DOCKERFILE OPTIMISE

# ── Stage 1 : Dependencies ──
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
# Installer les dépendances sans scripts pour éviter les effets de bord
RUN npm ci --ignore-scripts

# ── Stage 2 : Tests ──
FROM deps AS test
COPY . .
RUN npm test

# ── Stage 3 : Production ──
FROM node:20-alpine AS production

# Sécurité : user non-root dédié
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -s /bin/sh -D appuser

WORKDIR /app
ENV NODE_ENV=production

# Installer uniquement les dépendances prod
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force

# Copier le code (les dépendances prod viennent d'npm ci juste au-dessus)
COPY src/ ./src/

LABEL maintainer="devops-team"
LABEL version="1.0"

RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "src/index.js"]
