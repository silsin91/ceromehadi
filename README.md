# Chrome Docker Codespace

This Codespace starts a public noVNC Chrome desktop and a ready-to-copy VLESS WebSocket proxy on the same forwarded port.

## Quick Start

1. Open the repository in GitHub Codespaces.
2. Wait for the `postCreateCommand` terminal to finish.
3. The terminal prints:
   - Chrome/noVNC URL
   - VNC password
   - Complete `vless://...` link
4. Codespaces should also open Chrome/noVNC automatically.

Chrome/noVNC URL format:

```text
https://<codespace>-6080.app.github.dev/vnc.html?autoconnect=true&resize=scale&password=codespace
```

Default VNC password:

```text
codespace
```

Change `VNC_PASSWORD` in `.env` before exposing the port publicly.

## Ready VLESS Link

The startup script prints the full VLESS link automatically. It looks like this:

```text
vless://<uuid>@<codespace>-6080.app.github.dev:443?encryption=none&security=tls&type=ws&host=<codespace>-6080.app.github.dev&sni=<codespace>-6080.app.github.dev&path=%2Fvless#Chrome-Codespace
```

Manual client settings:

```text
Protocol: VLESS
Address: <codespace>-6080.app.github.dev
Port: 443
UUID: value of XRAY_UUID in .env
Encryption: none
Security: TLS
Transport: WebSocket
Path: /vless
Host/SNI: <codespace>-6080.app.github.dev
```

## Configuration

Edit `.env`:

```text
PUBLIC_PORT=6080
SCREEN_WIDTH=1365
SCREEN_HEIGHT=768
SCREEN_DEPTH=24

VNC_PASSWORD=codespace

XRAY_UUID=b831381d-6324-4d53-ad4f-8cda48b30811
XRAY_WS_PATH=/vless
PUBLIC_TAG=Chrome-Codespace

CHROME_PROXY_SERVER=socks5://xray:10808
```

For better noVNC speed, keep the resolution near `1365x768` or lower.

## Commands

Start or restart and print the Chrome URL plus VLESS link:

```bash
bash .devcontainer/start-stack.sh
```

Rebuild everything:

```bash
bash .devcontainer/start-stack.sh --build
```

Check services:

```bash
docker compose ps
docker compose logs -f chrome
docker compose logs -f xray
docker compose logs -f gateway
```

Stop:

```bash
docker compose down
```

## Files

- `.devcontainer/devcontainer.json`: Codespaces startup and public port configuration.
- `.devcontainer/start-stack.sh`: starts the stack, prints Chrome URL, prints VLESS link, opens noVNC.
- `.devcontainer/Dockerfile`: lightweight devcontainer with Docker Compose v2.
- `.devcontainer/Dockerfile.chrome`: Chrome/noVNC runtime image.
- `.devcontainer/Dockerfile.xray`: Xray runtime image for VLESS.
- `.devcontainer/start-chrome.sh`: starts Xvfb, Fluxbox, x11vnc, noVNC, and Chrome.
- `.devcontainer/xray-entrypoint.sh`: generates Xray VLESS + SOCKS config from `.env`.
- `.devcontainer/nginx.conf`: routes `/vless` to Xray and everything else to noVNC.
- `docker-compose.yml`: service orchestration.

## Troubleshooting

### Chrome/noVNC does not open

Run:

```bash
docker compose ps
docker compose logs --tail=100 chrome
docker compose logs --tail=100 gateway
```

Then open the printed URL manually.

### VLESS does not connect

Check these values:

- Codespaces port `6080` is Public.
- Client uses port `443`.
- TLS is enabled.
- WebSocket path is `/vless`.
- UUID matches `XRAY_UUID` in `.env`.

### Need a fresh rebuild

```bash
docker compose down
bash .devcontainer/start-stack.sh --build
```

## Security

Do not keep the default `VNC_PASSWORD` or `XRAY_UUID` on a public Codespaces port. Replace both in `.env`.
