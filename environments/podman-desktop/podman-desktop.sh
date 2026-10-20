#!/usr/bin/env bash
# (Re)builds Podman Desktop from the checkout, then (re)starts it with Electron (on the virtual
# display on Linux, on the runner's desktop on Windows) with the Chrome DevTools Protocol on port
# 9222, and waits for its window.
#
# Used by the environment before the agent starts (with --no-build: it was just built), and by the
# agent after it changes the code: `bash "$MACARON_ENV/podman-desktop.sh"` (then reconnect the MCP
# server). A full `pnpm build` takes a few minutes.
set -euo pipefail
: "${MACARON_ENV:?}" "${PODMAN_DESKTOP_HOME_DIR:?}" "${MACARON_WORK:?}"

# Stop a running Podman Desktop. On Windows, Electron is a native process Git Bash can't signal.
if [[ -f "$MACARON_ENV/podman-desktop.pid" ]]; then
  if [[ "${RUNNER_OS:-}" == Windows ]]; then taskkill //F //T //IM electron.exe >/dev/null 2>&1 || true
  else kill "$(cat "$MACARON_ENV/podman-desktop.pid")" 2>/dev/null || true; fi
  for _ in $(seq 1 20); do curl -sf http://127.0.0.1:9222/json/version >/dev/null 2>&1 || break; sleep 1; done
fi

cd "$MACARON_WORK"
if [[ "${1:-}" != "--no-build" ]]; then
  pnpm build >"$MACARON_ENV/build.log" 2>&1 || { tail -60 "$MACARON_ENV/build.log"; exit 1; }
fi

# As its e2e tests run it: Electron on the repository root (main: packages/main/dist/index.cjs).
# Electron runs without its sandbox: the Linux runner restricts unprivileged user namespaces.
XDG_SESSION_TYPE=x11 ELECTRON_DISABLE_SANDBOX=1 \
  nohup "$MACARON_WORK/node_modules/.bin/electron" "$MACARON_WORK" --no-sandbox --remote-debugging-port=9222 >>"$MACARON_ENV/podman-desktop.log" 2>&1 &
echo $! >"$MACARON_ENV/podman-desktop.pid"

for _ in $(seq 1 180); do
  if curl -sf http://127.0.0.1:9222/json/list | jq -e 'any(.[]; .type == "page" and (.title | test("Podman Desktop")))' >/dev/null 2>&1; then
    echo "Podman Desktop is running (CDP on port 9222), built from $MACARON_WORK"
    exit 0
  fi
  sleep 1
done
echo "Podman Desktop didn't open its window within 180 s; last log lines:" >&2
tail -40 "$MACARON_ENV/podman-desktop.log" >&2
exit 1
