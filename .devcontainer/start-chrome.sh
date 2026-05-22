#!/usr/bin/env bash
set -euo pipefail

DISPLAY="${DISPLAY:-:99}"
SCREEN_WIDTH="${SCREEN_WIDTH:-1365}"
SCREEN_HEIGHT="${SCREEN_HEIGHT:-768}"
SCREEN_DEPTH="${SCREEN_DEPTH:-24}"
NOVNC_PORT="${NOVNC_PORT:-6080}"
VNC_PORT="${VNC_PORT:-5900}"
VNC_PASSWORD="${VNC_PASSWORD:-codespace}"
CHROME_PROFILE_DIR="${CHROME_PROFILE_DIR:-/data/chrome}"
CHROME_DOWNLOAD_DIR="${CHROME_DOWNLOAD_DIR:-/data/downloads}"
CHROME_PROXY_SERVER="${CHROME_PROXY_SERVER-socks5://v2ray:10808}"

export DISPLAY XDG_RUNTIME_DIR=/tmp/runtime-chrome
mkdir -p "${XDG_RUNTIME_DIR}" "${CHROME_PROFILE_DIR}" "${CHROME_DOWNLOAD_DIR}" /tmp/.X11-unix
chmod 700 "${XDG_RUNTIME_DIR}"

cleanup() {
  jobs -p | xargs -r kill 2>/dev/null || true
}
trap cleanup EXIT INT TERM

Xvfb "${DISPLAY}" -screen 0 "${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH}" -ac -nolisten tcp &
sleep 1

mkdir -p /var/run/dbus
dbus-daemon --system --fork >/tmp/dbus.log 2>&1 || true

fluxbox -display "${DISPLAY}" >/tmp/fluxbox.log 2>&1 &

x11vnc \
  -display "${DISPLAY}" \
  -forever \
  -shared \
  -repeat \
  -rfbport "${VNC_PORT}" \
  -passwd "${VNC_PASSWORD}" \
  -noxdamage \
  -noxfixes \
  -noxrecord \
  -wait 5 \
  -defer 10 \
  -quiet >/tmp/x11vnc.log 2>&1 &

websockify \
  --web=/usr/share/novnc/ \
  --heartbeat=30 \
  "${NOVNC_PORT}" \
  "127.0.0.1:${VNC_PORT}" >/tmp/websockify.log 2>&1 &

CHROME_FLAGS=(
  "--no-sandbox"
  "--no-first-run"
  "--no-default-browser-check"
  "--disable-background-networking"
  "--disable-background-timer-throttling"
  "--disable-client-side-phishing-detection"
  "--disable-component-update"
  "--disable-features=Translate,OptimizationHints,MediaRouter"
  "--disable-popup-blocking"
  "--disable-prompt-on-repost"
  "--disable-renderer-backgrounding"
  "--disable-sync"
  "--force-device-scale-factor=1"
  "--password-store=basic"
  "--use-mock-keychain"
  "--user-data-dir=${CHROME_PROFILE_DIR}"
  "--window-size=${SCREEN_WIDTH},${SCREEN_HEIGHT}"
)

if [ -n "${CHROME_PROXY_SERVER}" ]; then
  CHROME_FLAGS+=("--proxy-server=${CHROME_PROXY_SERVER}")
fi

google-chrome-stable "${CHROME_FLAGS[@]}" "about:blank" >/tmp/chrome.log 2>&1 &
chrome_pid="$!"

echo "Chrome: http://localhost:${NOVNC_PORT}/vnc.html"
echo "VNC password: ${VNC_PASSWORD}"

wait "${chrome_pid}"
