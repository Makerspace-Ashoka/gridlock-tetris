# GRIDLOCK deployment

GRIDLOCK is a single self-contained `index.html`. There is no build step: the
Docker image is `caddy:2-alpine` with the file baked in, serving every path as
`index.html`. That last detail matters — because the app answers *any* path,
the edge proxy never has to strip path prefixes such as `/dev` or `/pr/12`.

## Architecture

```
                 https://tetris.makerspace.tools
                              |
                   external Caddy (user's box)
                              |
                    http://192.168.8.3:8080
                              |
              +---------------------------------+
              |   gridlock-edge (caddy:2-alpine)|
              |   deploy/Caddyfile              |
              +---------------------------------+
                 |            |              |
        /        |     /dev*  |     /pr/<n>* |
                 v            v              v
        gridlock-prod   gridlock-dev   gridlock-pr-<n>
           :prod           :dev           :pr-<n>
              \             |             /
               +--- docker network `gridlock` (external) ---+
```

PR routing is dynamic: the edge resolves `gridlock-pr-<n>` through Docker DNS,
so spinning a preview up or down needs **no edge reload**. Unreachable
backends fall through to `handle_errors`, which returns a small "not currently
deployed" page instead of a raw 502.

## Pipeline stages

| Stage | Workflow | Trigger | What happens |
|---|---|---|---|
| PR preview | `.github/workflows/pr-preview.yml` | PR opened / synchronize / reopened | Build + push `:pr-<n>` on GitHub-hosted runner, then the self-hosted runner starts `gridlock-pr-<n>`, smoke-tests it and posts a sticky PR comment |
| PR teardown | `.github/workflows/pr-teardown.yml` | PR closed (merged or not) | Removes `gridlock-pr-<n>`, deletes the `:pr-<n>` image, prunes dangling images |
| Dev | `.github/workflows/deploy-dev.yml` | Push to `main` | Build + push `:dev` and `:sha-<full-sha>`, sync edge config + compose file to `/opt/gridlock`, reload edge, pull and restart `gridlock-dev`, smoke-test `/dev` |
| Prod | `.github/workflows/deploy-prod.yml` | Manual `workflow_dispatch` | Retags the **existing** `:dev` image as `:prod`, pushes it, restarts `gridlock-prod`, smoke-tests `/`, writes the promoted digest to the run summary |

Builds happen only on `ubuntu-latest`. The self-hosted runner only pulls
images and moves containers around.

## URLs

| Environment | Public | LAN |
|---|---|---|
| Production | https://tetris.makerspace.tools/ | http://192.168.8.3:8080/ |
| Dev (`main`) | https://tetris.makerspace.tools/dev | http://192.168.8.3:8080/dev |
| PR preview | https://tetris.makerspace.tools/pr/&lt;n&gt; | http://192.168.8.3:8080/pr/&lt;n&gt; |

## Promoting to production

Production is never deployed automatically. To ship what is currently on
`/dev`:

1. GitHub → **Actions** → **Deploy Prod** → **Run workflow** (branch `main`).
2. The job pulls `:dev`, retags it `:prod`, pushes, and restarts the prod
   container. No rebuild happens, so the promoted artifact is byte-identical
   to the one tested on `/dev`.
3. Check the run summary for the promoted digest.

## PR previews

Every PR from a branch **in this repository** gets its own container and a
sticky comment (marker `<!-- gridlock-preview -->`) carrying the preview URL,
the LAN URL, and the deployed short SHA. Pushing more commits updates the same
comment rather than adding new ones.

**Fork PRs are excluded by design.** Both PR workflows are gated on
`github.event.pull_request.head.repo.full_name == github.repository`, so
untrusted code never reaches the self-hosted runner and never gets a registry
token. Fork contributions must be reviewed and merged (or pushed to a branch
in this repo) before they can be previewed.

## Server layout

- Host: `192.168.8.3`, deploy directory `/opt/gridlock`, owned by `gha`.
- `gha` runs the self-hosted GitHub Actions runner and is in the `docker`
  group. Runner labels: `self-hosted`, `gridlock`.
- `/opt/gridlock/Caddyfile` and `/opt/gridlock/docker-compose.yml` are
  **managed by the pipeline** — they are overwritten from `deploy/` on every
  push to `main`. Edit them in this repo, not on the server.
- Docker network `gridlock` is external (created once during bootstrap):
  `docker network create gridlock`.
- Registry: `ghcr.io/makerspace-ashoka/gridlock-tetris`, tags `pr-<n>`, `dev`,
  `sha-<full-sha>`, `prod`.

## Rollback

Every push to `main` also publishes an immutable `sha-<full-sha>` tag, so any
past state can be restored.

Fast path — swap the prod container to a known-good build:

```bash
cd /opt/gridlock
docker pull ghcr.io/makerspace-ashoka/gridlock-tetris:sha-<full-sha>
docker rm -f gridlock-prod
docker run -d --name gridlock-prod --network gridlock --restart unless-stopped \
  ghcr.io/makerspace-ashoka/gridlock-tetris:sha-<full-sha>
```

Note this leaves the `:prod` registry tag pointing at the bad build, so the
next `docker compose up -d prod` would undo it. To make the rollback durable,
retag and re-promote:

```bash
docker tag ghcr.io/makerspace-ashoka/gridlock-tetris:sha-<full-sha> \
           ghcr.io/makerspace-ashoka/gridlock-tetris:dev
docker push ghcr.io/makerspace-ashoka/gridlock-tetris:dev
```

then run **Deploy Prod** again — it promotes whatever `:dev` points at.
Alternatively, revert the offending commit on `main` (which rebuilds `:dev`)
and run **Deploy Prod**.

<!-- Pipeline verification: PR preview smoke test, 2026-08-19. Safe to remove. -->
