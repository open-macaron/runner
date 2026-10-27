#!/usr/bin/env bash
# Serves the checkout's static/ as Podman Desktop's extension catalog on http://localhost:3000, then
# (re)starts Podman Desktop on the virtual display with that catalog as its registry and the Chrome
# DevTools Protocol on port 9222, and waits for its window.
#
# Run by the agent when a change touches static/, and again after it edits static/:
# `bash "$MACARON_ENV/catalog.sh"` (then reconnect the MCP server).
set -euo pipefail
: "${MACARON_ENV:?}" "${MACARON_WORK:?}" "${PODMAN_DESKTOP_HOME_DIR:?}" "${PODMAN_DESKTOP_BINARY:?}"

port=3000
site="$MACARON_ENV/site"

stop() {
  local pid_file="$MACARON_ENV/$1.pid"
  if [[ -f "$pid_file" ]]; then kill "$(cat "$pid_file")" 2>/dev/null || true; rm -f "$pid_file"; fi
}
stop catalog-server
if [[ -f "$MACARON_ENV/podman-desktop.pid" ]]; then
  stop podman-desktop
  for _ in $(seq 1 20); do curl -sf http://127.0.0.1:9222/json/version >/dev/null 2>&1 || break; sleep 1; done
fi

# A copy of static/ whose README and LICENSE URLs point here: what a pull request adds is on
# registry.podman-desktop.io only once it is merged. Icons stay there: the renderer's CSP allows
# images over https only (img-src 'self' https: data: blob:).
rm -rf "$site" && cp -R "$MACARON_WORK/static" "$site"
jq --arg from "https://registry.podman-desktop.io/" --arg to "http://localhost:$port/" '
  (.extensions[].versions[].files[] | select(.assetType != "icon") | .data) |= sub("^" + $from; $to)
' "$MACARON_WORK/static/api/extensions.json" >"$site/api/extensions.json" \
  || { echo "static/api/extensions.json is not valid JSON or not a catalog" >&2; exit 1; }

nohup python3 -m http.server "$port" --bind 127.0.0.1 --directory "$site" >>"$MACARON_ENV/catalog-server.log" 2>&1 &
echo $! >"$MACARON_ENV/catalog-server.pid"
for _ in $(seq 1 20); do curl -sf "http://localhost:$port/api/extensions.json" >/dev/null 2>&1 && break; sleep 0.5; done
curl -sf "http://localhost:$port/api/extensions.json" >/dev/null || { tail -20 "$MACARON_ENV/catalog-server.log" >&2; exit 1; }

# As the Playwright runner of @podman-desktop/tests-playwright, plus no telemetry and this catalog
# (the setting podman-desktop/podman-desktop-catalog's reviewers use to check a pull request).
cat >"$PODMAN_DESKTOP_HOME_DIR/configuration/settings.json" <<JSON
{
  "preferences.OpenDevTools": "none",
  "extensions.autoUpdate": false,
  "extensions.autoCheckUpdates": false,
  "extensions.registryUrl": "http://localhost:$port/api/extensions.json",
  "telemetry.enabled": false,
  "telemetry.check": true
}
JSON

# Electron runs without its sandbox: the Linux runner restricts unprivileged user namespaces.
XDG_SESSION_TYPE=x11 ELECTRON_DISABLE_SANDBOX=1 \
  nohup "$PODMAN_DESKTOP_BINARY" --no-sandbox --remote-debugging-port=9222 >>"$MACARON_ENV/podman-desktop.log" 2>&1 &
echo $! >"$MACARON_ENV/podman-desktop.pid"

for _ in $(seq 1 120); do
  if curl -sf http://127.0.0.1:9222/json/list | jq -e 'any(.[]; .type == "page" and (.title | test("Podman Desktop")))' >/dev/null 2>&1; then
    echo "Podman Desktop ${PODMAN_DESKTOP_VERSION:-} is running (CDP on port 9222), with the catalog of $MACARON_WORK/static on http://localhost:$port"
    exit 0
  fi
  sleep 1
done
echo "Podman Desktop didn't open its window within 120 s; last log lines:" >&2
tail -40 "$MACARON_ENV/podman-desktop.log" >&2
exit 1
