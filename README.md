# Chrome Docker Codespace

Runs Google Chrome in GitHub Codespaces with a browser-accessible noVNC desktop and an optional V2Ray endpoint on the same public Codespaces port.

## What It Starts

- `chrome`: Xvfb + Fluxbox + x11vnc + noVNC + Google Chrome.
- `v2ray`: VMess over WebSocket for external clients, plus a local SOCKS inbound used by Chrome.
- `gateway`: Nginx reverse proxy on port `6080`.

The public Codespaces URL is:

```text
https://<codespace>-6080.app.github.dev/vnc.html
```

V2Ray is available on the same host through:

```text
wss://<codespace>-6080.app.github.dev/v2ray
```

## Quick Start

1. Fork or clone this repository.
2. Open it in GitHub Codespaces.
3. Wait for `postCreateCommand` to finish.
4. Open the forwarded `6080` port or visit:

```text
https://<codespace>-6080.app.github.dev/vnc.html
```

Default VNC password:

```text
codespace
```

Change it in `.env` before using a public port.

## V2Ray Client Settings

Use these settings in a VMess client:

```text
Address: <codespace>-6080.app.github.dev
Port: 443
UUID: value of V2RAY_UUID in .env
Alter ID: 0
Transport: WebSocket
Path: /v2ray
TLS: enabled
SNI/Host: <codespace>-6080.app.github.dev
```

Chrome inside the noVNC desktop uses the internal V2Ray SOCKS inbound by default:

```text
socks5://v2ray:10808
```

To disable Chrome's proxy, leave `CHROME_PROXY_SERVER` empty in `.env` and restart the stack.

## Configuration

Main settings live in `.env`:

```text
PUBLIC_PORT=6080
SCREEN_WIDTH=1365
SCREEN_HEIGHT=768
SCREEN_DEPTH=24
VNC_PASSWORD=codespace
V2RAY_UUID=b831381d-6324-4d53-ad4f-8cda48b30811
V2RAY_WS_PATH=/v2ray
CHROME_PROXY_SERVER=socks5://v2ray:10808
```

Lower screen resolutions are faster in noVNC. `1365x768` is intentionally used instead of `1920x1080` because it feels much smoother in Codespaces.

## Useful Commands

```bash
docker compose ps
docker compose logs -f chrome
docker compose logs -f v2ray
docker compose restart
docker compose down
docker compose up -d --build
```

## Files

- `.devcontainer/devcontainer.json`: Codespaces setup, public port, and startup commands.
- `.devcontainer/Dockerfile`: lightweight devcontainer with Docker Compose v2.
- `.devcontainer/Dockerfile.chrome`: Chrome/noVNC runtime image.
- `.devcontainer/Dockerfile.v2ray`: V2Ray runtime image using the official V2Fly binary image.
- `.devcontainer/start-chrome.sh`: starts Xvfb, Fluxbox, x11vnc, noVNC, and Chrome.
- `.devcontainer/v2ray-entrypoint.sh`: generates and starts the V2Ray config from `.env`.
- `.devcontainer/nginx.conf`: routes `/v2ray` to V2Ray and everything else to noVNC.
- `docker-compose.yml`: service orchestration.

## Troubleshooting

### noVNC opens but Chrome is slow

Use a lower resolution in `.env`, then restart:

```bash
SCREEN_WIDTH=1280
SCREEN_HEIGHT=720
docker compose up -d --build
```

### Port is not public

The devcontainer marks port `6080` as public. If Codespaces does not apply it, open the Ports tab and set port `6080` visibility to Public.

### V2Ray client cannot connect

Check:

- The Codespaces port `6080` is Public.
- TLS is enabled in the client.
- The WebSocket path is `/v2ray`.
- The UUID matches `V2RAY_UUID` in `.env`.

### Rebuild everything

```bash
docker compose down
docker compose up -d --build
```

## Notes

Use this environment in line with GitHub Codespaces terms and applicable local rules. Public ports should use non-default passwords and UUIDs.
