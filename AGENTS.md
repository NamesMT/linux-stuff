# AGENTS.md

`linux-stuff` ships opinionated Node images and host bootstrap scripts for Alpine, Arch and Ubuntu.
There is no package.json, no build system and no test suite — the Dockerfiles and shell scripts are
the product. Images are published to Docker Hub as `namesmt/linux-stuff` (legacy mirrors
`namesmt/images-alpine` and `namesmt/images-arch`).

Each distro has four tags: `{alpine,arch}-node` (Node LTS + pnpm + `@antfu/ni`), `-node-dev` (adds
git, less, zsh + Oh My Zsh with the spaceship theme) and the two `-node-aws`/`-node-aws-dev`
variants that add the distro's aws-cli v2; every tag also gets a `_pnpm<version>` variant for CI
pinning (e.g. `alpine-node-dev_pnpm10.16.0`).

## Commands

```sh
# Alpine (multi-arch buildx, amd64 + arm64)
docker build -f alpine/alpine-node.Dockerfile -t namesmt/linux-stuff:alpine-node .
docker push namesmt/linux-stuff:alpine-node

# Arch (amd64 only; each stage builds FROM the previously pushed image)
docker build -f arch/arch-node.Dockerfile -t namesmt/linux-stuff:arch-node .
docker push namesmt/linux-stuff:arch-node

# Force a rebuild of a stage when a new pnpm is published (default build-arg is `latest`)
docker build --build-arg PNPM_VERSION=10.16.0 -f alpine/alpine-node.Dockerfile .
```

## Structure

- `alpine/` — the four Alpine Dockerfiles, `alpine-node-dev.sh` (host bootstrap) and `scripts/` (`install-fnm.sh`, `install-docker.sh`, `install-glibc.sh`, `install-bun.sh`) plus `assets/` (a patched fnm 1.35.1 archive, not referenced by any tracked script).
- `arch/` — the four Arch Dockerfiles, `arch-init.sh` (new-install setup: keyring, packages, user, WSL default user) and `arch-node-dev.sh` (host bootstrap).
- `ubuntu/` — `ubuntu-node-dev.sh` host bootstrap only; there is no Ubuntu image.
- `.github/workflows/` — `build_image_alpine_pnpm.yml` and `build_image_arch_pnpm.yml` (on `pnpm*` tags or manual dispatch), `check_new_release_pnpm.yml` (daily cron).
- `.github/scripts/new_release_check_pnpm.sh` — tags `pnpm<version>` and pushes it, which is what triggers the two build workflows.

## Conventions

- Conventional commits (`feat:`, `fix:`, `chore:`, …); scope by area (`alpine`, `arch`, `zsh`, `ci`).
- One Dockerfile per stage, `FROM namesmt/linux-stuff:<previous-stage>` — stages are chained, never self-contained.
- Keep the `dev` and `aws` overlays as thin layers on the corresponding base; a change to shared basics belongs in the base image.
- Keep the host bootstrap scripts (`*.sh`) behaviourally aligned with their Dockerfile, since they install the same environment for WSL/bare metal.
- Comment non-obvious intent only; the Dockerfiles already carry short `## +dev:`/`## +aws:` section markers.

## Gotchas

- Arch images are `linux/amd64` only — `archlinux:latest` publishes no arm64 manifest; Alpine builds `linux/amd64,linux/arm64`.
- Alpine takes aws-cli from the distro repo: the official prebuilt aws-cli v2 binary is glibc-only and fails on musl (`dladdr1`) even with `gcompat`.
- `mandoc` is installed with aws-cli so `aws help` can render man pages; `groff` is avoided to keep the layer small.
- `ADD https://registry.npmjs.org/-/package/pnpm/dist-tags latest_pnpm` is the cache-buster that re-runs `corepack prepare` on a new pnpm release — it deliberately uses the npm registry instead of the rate-limited GitHub API.
- `new_release_check_pnpm.sh` only accepts plain `vX.Y.Z` tags (skips rc/alpha/beta and `@pnpm/foo@…` subpackage tags); a manual dispatch has no tag to read and falls back to `git tag --sort=-v:refname | head -1`.
- `install-bun.sh` pins glibc `2.34-r0` (bundled with its own removal of `gcompat`/`glibc`/`glibc-bin`) because bun's musl build breaks on the newer glibc; `install-glibc.sh` is the general-purpose installer and pins `2.35-r1`. A real glibc conflicts with the `gcompat` shim, so remove `gcompat` before installing one.
- The build workflows derive the image name from `GITHUB_REPOSITORY` lowercased, so they push `namesmt/linux-stuff` regardless of the git remote's casing.
- Both images switch the default shell to zsh by rewriting `/etc/passwd` and set `SHELL=/bin/zsh`; Alpine's base image also clears the `node` image `ENTRYPOINT`.
