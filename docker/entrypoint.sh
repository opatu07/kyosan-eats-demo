#!/usr/bin/env sh
set -e

APP_DIR="/src"
cd "$APP_DIR"

# 依存インストール（初回/空の場合）
if [ -f package.json ]; then
  # node_modules が存在しない「または空」の場合にインストール
  if [ ! -d node_modules ] || [ -z "$(ls -A node_modules 2>/dev/null)" ]; then
    if [ -f package-lock.json ]; then
      echo "[entrypoint] Installing dependencies with npm ci..."
      npm ci || (
        echo "[entrypoint] npm ci failed, retrying with npm install";
        rm -rf node_modules;
        npm install --no-audit --no-fund
      )
    else
      echo "[entrypoint] Installing dependencies with npm install..."
      npm install --no-audit --no-fund
    fi
  fi
else
  echo "[entrypoint] No package.json in $APP_DIR."
  echo "[entrypoint] Create a React app under ./app (host) which is mounted to $APP_DIR, then restart the container."
  exit 1
fi

echo "[entrypoint] Starting: $*"
exec "$@"
