FROM node:22-bookworm-slim AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --ignore-scripts
COPY tsconfig.json ./
COPY scripts ./scripts
COPY src ./src
COPY static ./static
RUN npm run build

FROM node:22-bookworm-slim AS runtime
LABEL org.opencontainers.image.title="MediaSteru"
LABEL org.opencontainers.image.description="Headless MediaSteru desktop companion service"

ENV NODE_ENV=production \
    MEDIASTERU_DATA_DIR=/data \
    MEDIASTERU_DOWNLOAD_DIR=/downloads \
    MEDIASTERU_PORT=8765

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg yt-dlp util-linux \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /data /downloads \
    && chown -R node:node /app /data /downloads
COPY --from=builder --chown=node:node /app/dist ./dist
COPY docker/entrypoint.sh /usr/local/bin/mediasteru-entrypoint
RUN chmod +x /usr/local/bin/mediasteru-entrypoint

VOLUME ["/data", "/downloads"]
EXPOSE 8765
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:8765/ping').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
ENTRYPOINT ["/usr/local/bin/mediasteru-entrypoint"]
CMD ["node", "dist/daemon.js"]
