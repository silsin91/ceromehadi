#!/bin/sh
set -eu

XRAY_UUID="${XRAY_UUID:-b831381d-6324-4d53-ad4f-8cda48b30811}"
XRAY_WS_PATH="${XRAY_WS_PATH:-/vless}"
XRAY_PUBLIC_PORT="${XRAY_PUBLIC_PORT:-8080}"
XRAY_SOCKS_PORT="${XRAY_SOCKS_PORT:-10808}"
PUBLIC_PORT="${PUBLIC_PORT:-6080}"
PUBLIC_HOST="${PUBLIC_HOST:-}"
PUBLIC_TAG="${PUBLIC_TAG:-Chrome-Codespace}"

if [ -z "${PUBLIC_HOST}" ] && [ -n "${CODESPACE_NAME:-}" ] && [ -n "${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN:-}" ]; then
  PUBLIC_HOST="${CODESPACE_NAME}-${PUBLIC_PORT}.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}"
fi

if [ -z "${PUBLIC_HOST}" ]; then
  PUBLIC_HOST="localhost"
  CLIENT_PORT="${PUBLIC_PORT}"
  CLIENT_SECURITY="none"
else
  CLIENT_PORT="443"
  CLIENT_SECURITY="tls"
fi

ENCODED_PATH="$(printf '%s' "${XRAY_WS_PATH}" | sed 's#/#%2F#g')"

cat > /tmp/xray-config.json <<EOF
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
        "destOverride": ["http", "tls", "quic"]
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

echo
echo "================ Chrome Codespace Proxy ================"
echo "VLESS:"
echo "vless://${XRAY_UUID}@${PUBLIC_HOST}:${CLIENT_PORT}?encryption=none&security=${CLIENT_SECURITY}&type=ws&host=${PUBLIC_HOST}&sni=${PUBLIC_HOST}&path=${ENCODED_PATH}#${PUBLIC_TAG}"
echo "WebSocket path: ${XRAY_WS_PATH}"
echo "Chrome proxy: socks5://xray:${XRAY_SOCKS_PORT}"
echo "========================================================"
echo

exec /usr/local/bin/xray run -config /tmp/xray-config.json
