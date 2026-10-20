## Environment: Podman Desktop, built from this checkout, is running

Podman Desktop was built from this repository's checkout (`pnpm build`) and is running with Electron (on a virtual display on Linux, on the runner's desktop on Windows). Its window is reachable over the Chrome DevTools Protocol on port **9222**. Podman is installed on the machine.

**Driving it: the `podman-desktop-mcp` MCP server** (Podman Desktop's own `mcp-testing` skill).
- Follow `$MACARON_ENV/skill/agent-prompt.md`: connect with `connect({ port: 9222 })`, check the title, handle the welcome dialog (click **Skip**), then work through selectors.
- The selectors for Podman Desktop's screens are in `$MACARON_ENV/skill/references/operations/` (start with `navigation.md`). For screens they don't cover, use `snapshot` and the selectors you find there.
- That skill was written for an interactive session. Here, the start, probe and stop scripts and every `AskUserQuestion` step are already done or don't apply: Podman Desktop is up, and nobody can answer questions.

**After changing the code:** rebuild and restart it with `bash "$MACARON_ENV/podman-desktop.sh"` (a few minutes), then reconnect the MCP server. Check your change in the running application before you report it.

**Podman machines:**
- Linux (when this run asked for one): QEMU with KVM is installed and a stopped machine named `podman-machine-default` exists (`podman machine list`). `podman machine start` takes a minute or two; `podman machine set` needs the machine stopped.
- Windows: Podman was installed with its Windows installer (user scope, in `$LOCALAPPDATA/Programs/Podman`) and a WSL machine named `podman-machine-default` is running. Hyper-V works too: it is installed and you are an administrator.
  - The installer records the provider it was installed for in `$APPDATA/containers/containers.conf.d/99-podman-machine-provider.conf` (`provider="wsl"` here, `"hyperv"` after a Hyper-V install). That drop-in overrides `$APPDATA/containers/containers.conf`.
  - One machine runs at a time: `podman machine stop` the WSL machine before starting a Hyper-V one. A Hyper-V machine takes about a minute to create and start.

**Evidence: screenshots of what you show.**
1. Save a screenshot of the window, or of one element:
   ```sh
   node "$MACARON_ENV/tools/screenshot.mjs" --out "$RUNNER_TEMP/settings.png" --selector 'CSS selector'
   ```
2. Attach it, and use the printed reference in your message or pull request body:
   ```sh
   macaron-agent attach "$RUNNER_TEMP/settings.png" --kind image --caption "What the screenshot shows"
   ```
   Keep the files out of the repository checkout.

Logs: `$MACARON_ENV/podman-desktop.log` (the application), `$MACARON_ENV/build.log`, `$MACARON_ENV/machine-init.log`.
