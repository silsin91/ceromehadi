#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

PUBLIC_PORT="${PUBLIC_PORT:-6080}"
XRAY_UUID="${XRAY_UUID:-b831381d-6324-4d53-ad4f-8cda48b30811}"
XRAY_WS_PATH="${XRAY_WS_PATH:-/vless}"
PUBLIC_TAG="${PUBLIC_TAG:-Chrome-Codespace}"
VNC_PASSWORD="${VNC_PASSWORD:-codespace}"
XRAY_PUBLIC_PORT="${XRAY_PUBLIC_PORT:-8080}"
XRAY_SOCKS_PORT="${XRAY_SOCKS_PORT:-10808}"

PUBLIC_HOST="${PUBLIC_HOST:-}"
if [ -z "${PUBLIC_HOST}" ] && [ -n "${CODESPACE_NAME:-}" ] && [ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]; then
  PUBLIC_HOST="${CODESPACE_NAME}-${PUBLIC_PORT}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
fi

NOVNC_QUERY="vnc.html?autoconnect=true&resize=scale&password=${VNC_PASSWORD}"

if [ -n "${PUBLIC_HOST}" ]; then
  NOVNC_URL="https://${PUBLIC_HOST}/${NOVNC_QUERY}"
  VLESS_HOST="${PUBLIC_HOST}"
  VLESS_PORT="443"
  VLESS_SECURITY="tls"
else
  NOVNC_URL="http://localhost:${PUBLIC_PORT}/${NOVNC_QUERY}"
  VLESS_HOST="localhost"
  VLESS_PORT="${PUBLIC_PORT}"
  VLESS_SECURITY="none"
fi

ENCODED_PATH="${XRAY_WS_PATH//\//%2F}"
VLESS_LINK="vless://${XRAY_UUID}@${VLESS_HOST}:${VLESS_PORT}?encryption=none&security=${VLESS_SECURITY}&type=ws&host=${VLESS_HOST}&sni=${VLESS_HOST}&path=${ENCODED_PATH}#${PUBLIC_TAG}"

cat > .devcontainer/vless-config.generated.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "public-vless-ws",
      "listen": "0.0.0.0",
      "port": ${XRAY_PUBLIC_PORT},
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${XRAY_UUID}",
            "flow": ""
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${XRAY_WS_PATH}"
        }
      }
    },
    {
      "tag": "chrome-socks",
      "listen": "0.0.0.0",
      "port": ${XRAY_SOCKS_PORT},
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
EOF

sudo chmod 666 /var/run/docker.sock 2>/dev/null || true

if [ "${1:-}" = "--build" ]; then
  docker compose up -d --build
else
  docker compose up -d
fi

echo
echo "================ Chrome Codespace Ready ================"
echo "Chrome/noVNC:"
echo "${NOVNC_URL}"
echo
echo "VNC password:"
echo "${VNC_PASSWORD}"
echo
echo "Ready VLESS link:"
echo "${VLESS_LINK}"
echo "========================================================"
echo

code --openExternal "${NOVNC_URL}" >/dev/null 2>&1 || true
