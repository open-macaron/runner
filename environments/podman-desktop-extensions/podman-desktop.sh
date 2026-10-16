#!/usr/bin/env bash
# (Re)builds the extension in the checkout from its Containerfile, installs it into Podman Desktop's
# plugins folder, then (re)starts Podman Desktop on the virtual display with the Chrome DevTools
# Protocol on port 9222, and waits for its window.
#
# Used by the environment before the agent starts, and by the agent after it changes the
# extension's code: `bash "$MACARON_ENV/podman-desktop.sh"` (then reconnect the MCP server).
set -euo pipefail
: "${MACARON_ENV:?}" "${PODMAN_DESKTOP_HOME_DIR:?}" "${PODMAN_DESKTOP_BINARY:?}" "${MACARON_WORK:?}" "${DISPLAY:?}"

# Stop a running Podman Desktop (a restart picks up the rebuilt extension).
if [[ -f "$MACARON_ENV/podman-desktop.pid" ]]; then
  kill "$(cat "$MACARON_ENV/podman-desktop.pid")" 2>/dev/null || true
  for _ in $(seq 1 20); do curl -sf http://127.0.0.1:9222/json/version >/dev/null 2>&1 || break; sleep 1; done
fi

# The extension, as its own e2e tests install it: the image's /extension folder in plugins/.
cd "$MACARON_WORK"
# Registries drop connections now and then (seen: unexpected EOF from registry.access.redhat.com).
podman build --retry 3 --retry-delay 10s -t localhost/macaron-extension:latest . >"$MACARON_ENV/extension-build.log" 2>&1 \
  || { tail -40 "$MACARON_ENV/extension-build.log"; exit 1; }
rm -rf "$PODMAN_DESKTOP_HOME_DIR/plugins" && mkdir -p "$PODMAN_DESKTOP_HOME_DIR/plugins"
container="$(podman create localhost/macaron-extension:latest --entrypoint "")"
podman export "$container" | tar -x -C "$PODMAN_DESKTOP_HOME_DIR/plugins/"
podman rm -f "$container" >/dev/null

# Electron runs without its sandbox: the runner restricts unprivileged user namespaces.
XDG_SESSION_TYPE=x11 ELECTRON_DISABLE_SANDBOX=1 \
  nohup "$PODMAN_DESKTOP_BINARY" --no-sandbox --remote-debugging-port=9222 >>"$MACARON_ENV/podman-desktop.log" 2>&1 &
echo $! >"$MACARON_ENV/podman-desktop.pid"

for _ in $(seq 1 120); do
  if curl -sf http://127.0.0.1:9222/json/list | jq -e 'any(.[]; .type == "page" and (.title | test("Podman Desktop")))' >/dev/null 2>&1; then
    echo "Podman Desktop is running (CDP on port 9222), with the extension built from $MACARON_WORK"
    exit 0
  fi
  sleep 1
done
echo "Podman Desktop didn't open its window within 120 s; last log lines:" >&2
tail -40 "$MACARON_ENV/podman-desktop.log" >&2
exit 1
