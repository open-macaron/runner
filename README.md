# runner

Where [macaron-bot](https://github.com/open-macaron/macaron) agents run.

- `.github/workflows/run.yml` is dispatched by the macaron controller only. The job holds no secret: it exchanges its GitHub Actions OIDC token, once, for its run's capped OpenRouter key and context (`macaron-agent bootstrap`). Its logs are public.
- `environments/` holds the composite actions that set projects up (`generic`, and families such as Podman Desktop extensions). A repository can also ship its own in `.github/macaron/env/`. See [SCALING.md](https://github.com/open-macaron/macaron/blob/main/docs/SCALING.md).

`macaron-agent` is pinned by URL and sha256; bump it in a PR after verifying the release's attestation:

```sh
gh release download agent-cli-<sha> -R open-macaron/macaron -p macaron-agent.mjs
gh attestation verify macaron-agent.mjs --owner open-macaron \
  --signer-workflow open-macaron/macaron/.github/workflows/release-agent-cli.yml --source-ref refs/heads/main
sha256sum macaron-agent.mjs
```
