## Environment: Podman Desktop is running, with this extension

Podman Desktop is running on a virtual display, with this repository's extension installed from its `Containerfile`, built from the checkout before you started. Its window is reachable over the Chrome DevTools Protocol on port **9222**.

**Driving it: the `podman-desktop-mcp` MCP server** (Podman Desktop's own `mcp-testing` skill).
- Follow `$MACARON_ENV/skill/agent-prompt.md`: connect with `connect({ port: 9222 })`, check the title, handle the welcome dialog (click **Skip**), then work through selectors.
- The selectors for Podman Desktop's screens are in `$MACARON_ENV/skill/references/operations/` (start with `navigation.md`). For the extension's own pages (e.g. **Quadlets** in the navigation), use `snapshot` and the selectors you find there.
- That skill was written for an interactive session. Here, the start, probe and stop scripts and every `AskUserQuestion` step are already done or don't apply: Podman Desktop is up, and nobody can answer questions.

**Evidence: screenshots of what you show.**
1. Save a screenshot of the window, or of one element:
   ```sh
   node "$MACARON_ENV/tools/screenshot.mjs" --out /tmp/editor.png --selector 'CSS selector'
   ```
2. Attach it, and use the printed reference in your message or pull request body:
   ```sh
   macaron-agent attach /tmp/editor.png --kind image --caption "What the screenshot shows"
   ```
   Keep the files out of the repository checkout.

**After you change the extension's code,** rebuild it and restart Podman Desktop before taking "after" screenshots (about a minute), then `connect` the MCP server again:
```sh
bash "$MACARON_ENV/podman-desktop.sh"
```

**Podman** is the runner's (rootless, `podman` CLI, systemd `--user`). To show a quadlet, create its files under `~/.config/containers/systemd/`, run `systemctl --user daemon-reload`, then refresh the Quadlets page. Logs: `$MACARON_ENV/podman-desktop.log`.
