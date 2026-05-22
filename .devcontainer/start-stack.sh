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
XRAY_VMESS_PATH="${XRAY_VMESS_PATH:-/vmess}"
PUBLIC_TAG="${PUBLIC_TAG:-Chrome-Codespace}"
VNC_PASSWORD="${VNC_PASSWORD:-codespace}"
XRAY_PUBLIC_PORT="${XRAY_PUBLIC_PORT:-8080}"
XRAY_VMESS_PORT="${XRAY_VMESS_PORT:-8081}"
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
  VLESS_SNI="&sni=${VLESS_HOST}&alpn=http/1.1"
else
  NOVNC_URL="http://localhost:${PUBLIC_PORT}/${NOVNC_QUERY}"
  VLESS_HOST="127.0.0.1"
  VLESS_PORT="${PUBLIC_PORT}"
  VLESS_SECURITY="none"
  VLESS_SNI=""
fi

VLESS_LINK="vless://${XRAY_UUID}@${VLESS_HOST}:${VLESS_PORT}?encryption=none&security=${VLESS_SECURITY}&type=ws&host=${VLESS_HOST}${VLESS_SNI}&path=${XRAY_WS_PATH}#${PUBLIC_TAG}-VLESS"

VMESS_JSON=$(cat <<EOF
{
  "v": "2",
  "ps": "${PUBLIC_TAG}-VMess",
  "add": "${VLESS_HOST}",
  "port": "${VLESS_PORT}",
  "id": "${XRAY_UUID}",
  "aid": "0",
  "scy": "auto",
  "net": "ws",
  "type": "none",
  "host": "${VLESS_HOST}",
  "path": "${XRAY_VMESS_PATH}",
  "tls": "${VLESS_SECURITY}",
  "sni": "${VLESS_HOST}",
  "alpn": "http/1.1"
}
EOF
)
VMESS_LINK="vmess://$(echo -n "$VMESS_JSON" | base64 -w 0 2>/dev/null || echo -n "$VMESS_JSON" | base64)"

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
      "tag": "public-vmess-ws",
      "listen": "0.0.0.0",
      "port": ${XRAY_VMESS_PORT},
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${XRAY_UUID}",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${XRAY_VMESS_PATH}"
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
echo
echo "Ready VMESS link:"
echo "${VMESS_LINK}"
echo "========================================================"
echo

code --openExternal "${NOVNC_URL}" >/dev/null 2>&1 || true
