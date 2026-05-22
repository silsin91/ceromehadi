#!/bin/sh
set -eu

V2RAY_UUID="${V2RAY_UUID:-b831381d-6324-4d53-ad4f-8cda48b30811}"
V2RAY_WS_PATH="${V2RAY_WS_PATH:-/v2ray}"
V2RAY_PUBLIC_PORT="${V2RAY_PUBLIC_PORT:-8080}"
V2RAY_SOCKS_PORT="${V2RAY_SOCKS_PORT:-10808}"

cat > /tmp/v2ray-config.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "public-vmess-ws",
      "listen": "0.0.0.0",
      "port": ${V2RAY_PUBLIC_PORT},
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "${V2RAY_UUID}",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "${V2RAY_WS_PATH}"
        }
      }
    },
    {
      "tag": "chrome-socks",
      "listen": "0.0.0.0",
      "port": ${V2RAY_SOCKS_PORT},
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
    },
    {
      "tag": "blocked",
      "protocol": "blackhole",
      "settings": {}
    }
  ]
}
EOF

echo "V2Ray VMess WebSocket path: ${V2RAY_WS_PATH}"
echo "V2Ray UUID: ${V2RAY_UUID}"
exec /opt/v2ray/bin/v2ray run -c /tmp/v2ray-config.json
