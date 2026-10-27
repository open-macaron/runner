## Environment: Podman Desktop, ready to show this catalog

This repository is Podman Desktop's extension catalog. `static/api/extensions.json` lists the extensions and their versions, and each version's assets are in `static/api/extensions/<publisher>/<name>/<version>/`. The latest Podman Desktop build is installed (`$PODMAN_DESKTOP_VERSION`), with a virtual display. It isn't running yet.

**When the pull request you look at, or the change you make, touches `static/`,** show it in Podman Desktop:
```sh
bash "$MACARON_ENV/catalog.sh"
```
It serves a copy of `static/` on `http://localhost:3000`, with README and LICENSE URLs rewritten from `https://registry.podman-desktop.io/` to there. Icons still come from `registry.podman-desktop.io`, since Podman Desktop only loads images over https: a version's new icon shows as broken until the pull request is merged. Check that its file exists in `static/` instead. Then it starts Podman Desktop with `"extensions.registryUrl": "http://localhost:3000/api/extensions.json"` and the Chrome DevTools Protocol on port **9222**. It takes about 30 s. Run it again after each edit of `static/`, then `connect` the MCP server again. For changes outside `static/` (dependencies, the website's code), don't run it: the repository's own commands are enough.

**Driving it: the `podman-desktop-mcp` MCP server** (Podman Desktop's own `mcp-testing` skill).
- Follow `$MACARON_ENV/skill/agent-prompt.md`: connect with `connect({ port: 9222 })`, check the title, handle the welcome dialog (click **Skip**), then work through selectors.
- The selectors for Podman Desktop's screens are in `$MACARON_ENV/skill/references/operations/` (start with `navigation.md`). For the catalog (**Extensions**, then its **Catalog** tab), use `snapshot` and the selectors you find there.
- That skill was written for an interactive session. Here, the start, probe and stop scripts and every `AskUserQuestion` step are already done or don't apply: `catalog.sh` starts Podman Desktop, and nobody can answer questions.

**What to check for an extension version that is added or changed:**
1. The extension is in the catalog, with its name, description and the expected version. Its `icon.png`, `README.md` and `LICENSE` are in `static/api/extensions/<publisher>/<name>/<version>/`, matching the URLs in `extensions.json`.
2. Its details page shows its README.
3. **Install** succeeds: Podman Desktop pulls the version's `ociUri` image. The extension then appears among the installed extensions.
4. When an install fails because the extension needs a newer Podman Desktop than `$PODMAN_DESKTOP_VERSION`, say so. That's not a defect of the pull request.

**Evidence: screenshots of what you show.**
1. Save a screenshot of the window, or of one element:
   ```sh
   node "$MACARON_ENV/tools/screenshot.mjs" --out "$RUNNER_TEMP/catalog.png" --selector 'CSS selector'
   ```
2. Attach it, and use the printed reference in your message or pull request body:
   ```sh
   macaron-agent attach "$RUNNER_TEMP/catalog.png" --kind image --caption "What the screenshot shows"
   ```
   Keep the files out of the repository checkout.

**Logs:** `$MACARON_ENV/podman-desktop.log`, `$MACARON_ENV/catalog-server.log` (each request Podman Desktop made to the catalog).
