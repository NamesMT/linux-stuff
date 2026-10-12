# AGENTS.md

`linux-stuff` ships opinionated Node images and host bootstrap scripts for Alpine, Arch and Ubuntu.
There is no package.json, no build system and no test suite — the Dockerfiles and shell scripts are
the product. Images are published to Docker Hub as `namesmt/linux-stuff`, with legacy mirrors
`namesmt/images-alpine` and `namesmt/images-arch` pushed alongside.

Each distro has four variants: `{alpine,arch}-node` (Node LTS + pnpm + `@antfu/ni`), `-node-dev`
(adds git, less, zsh + Oh My Zsh with the spaceship theme) and the two `-node-aws`/`-node-aws-dev`
variants that add the distro's aws-cli v2. Every build also pushes a suffixed tag for CI pinning:
`<image>:<variant>_pnpm<version>` (e.g. `namesmt/linux-stuff:alpine-node-dev_pnpm11.22.0`); the
suffix is the `pnpm*` git tag the build read.

## Docs

Where knowledge lives, and when to reach for each:

| tier | what it holds | when you use it |
| --- | --- | --- |
| `AGENTS.md` — this file | orientation and the rules that prevent defects | read every session; write when a rule is learned the hard way |
| `.agentDocs/` | depth: module rationale, traps with their causes, compatibility | read on demand, before touching that area; write when a rule needs its reasoning kept |
| `docs/` | how-to and reference for a person using this package | read when the task is user-facing; write in the same commit as the change |
| `README.md` | the first read, for a person | write alongside `docs/` |

- **One home per fact.** State the rule here, keep the reasoning in `.agentDocs/` and link it — never both.
- **A dead pointer is a bug.** If the target is gone, delete the pointer rather than leave it.
- Move depth behind a pointer once a section outgrows a screen or two; keep the rule inline.

[`README.md`](./README.md) is the only doc tier here: the user-facing tag list, `docker run` examples
and the host bootstrap one-liners.

## Commands

```sh
# Alpine (multi-arch buildx, amd64 + arm64)
docker build -f alpine/alpine-node.Dockerfile -t namesmt/linux-stuff:alpine-node .
docker push namesmt/linux-stuff:alpine-node

# Arch (amd64 only; each stage builds FROM the previously pushed image)
docker build -f arch/arch-node.Dockerfile -t namesmt/linux-stuff:arch-node .
docker push namesmt/linux-stuff:arch-node

# The CI-pinned form is the suffixed tag, not the plain one:
docker push namesmt/linux-stuff:alpine-node-dev_pnpm11.22.0

# Force a rebuild of a stage when a new pnpm is published (default build-arg is `latest`)
docker build --build-arg PNPM_VERSION=11.22.0 -f alpine/alpine-node.Dockerfile .
```

## Structure

- `alpine/` — the four Alpine Dockerfiles, `alpine-node-dev.sh` (host bootstrap), `scripts/` (`install-fnm.sh`, `install-docker.sh`, `install-glibc.sh`, `install-bun.sh`) and `assets/` (a patched fnm 1.35.1 archive that no tracked script references).
- `arch/` — the four Arch Dockerfiles, `arch-init.sh` (new-install setup: keyring, packages, user, WSL default user) and `arch-node-dev.sh` (host bootstrap).
- `ubuntu/` — `ubuntu-node-dev.sh` host bootstrap only; there is no Ubuntu image.
- `.github/workflows/` — `build_image_alpine_pnpm.yml` and `build_image_arch_pnpm.yml` (on `pnpm*` tags or manual dispatch), `check_new_release_pnpm.yml` (daily cron).
- `.github/scripts/new_release_check_pnpm.sh` — tags `pnpm<version>` and pushes it, which is what triggers the two build workflows.

## Conventions

- Conventional commits (`feat:`, `fix:`, `chore:`, …); scope by area (`alpine`, `arch`, `zsh`, `ci`).
- One Dockerfile per stage, `FROM namesmt/linux-stuff:<previous-stage>` — stages are chained, never self-contained.
- Keep the `dev` and `aws` overlays as thin layers on the corresponding base; a change to shared basics belongs in the base image.
- Keep the host bootstrap scripts (`*.sh`) behaviourally aligned with their Dockerfile, since they install the same environment for WSL/bare metal.

## How to work here

- **Check the callers before you change anything.** Grep who uses it and which tests name it. If the
  impact is unclear, say so — do not guess.
- **Never overwrite or delete a large section you have not understood.** Read it, or say what you could
  not determine and ask.
- **Do not invent requirements.** Build what was asked; surface what else you notice and let it be
  decided.
- **Fix the class, not the instance.** A copied helper, a rule stated twice, a guard bypassed by a
  second path is one problem: one implementation, one guard. That is the work, not a follow-up to ask
  for. Stay inside the task rather than refactoring the world.
- **Verify before claiming, and say what you checked.** A passing test is not evidence it pins
  anything — **break the thing it guards and watch it fail.** If it still passes, either the test is
  decoration or a different guard is running; find out which. Where a stub cannot answer the question,
  drive the real thing.
- **Never write an identifier from memory.** A commit hash, path, line number or version must be quoted
  from the source; a plausible-looking invented one is worse than none.
- **A stated blocker is a hypothesis, not a fact.** Re-test "cannot install X" / "tool unavailable"
  before inheriting it, and never report a failure your own flag forced.
- **Report the risk with the change** — correctness, security, operational and integration; plus what
  you could not verify and every assumption you made. An unverified claim marked as such beats a
  confident one that is wrong.
- **Missing recall of this repo?** Read this file, `.agentDocs/` and `git log` before acting, then ask
  1–3 focused questions rather than guessing at intent.

## Conciseness

**Prune verbose, keep correctness** — code, comments, docs alike.

- Code: a comment only for non-obvious *intent*, never to restate the line, and never long. A block
  arguing for its own change is a commit message.
- Docs: one idea per sentence. Cut anything that would not change what a reader does.
- Delete history `git log` already holds — keep the *rule* that came out of it, not the story.
- **Never drop a caveat to save a line.** Concise means no filler, not fewer facts.

## Gotchas

- Arch images are `linux/amd64` only — `archlinux:latest` publishes no arm64 manifest; Alpine builds `linux/amd64,linux/arm64`.
- Alpine takes aws-cli from the distro repo: the official prebuilt aws-cli v2 binary is glibc-only and fails on musl (`dladdr1`) even with `gcompat`.
- `mandoc` is installed with aws-cli so `aws help` can render man pages; `groff` is avoided to keep the layer small.
- `ADD https://registry.npmjs.org/-/package/pnpm/dist-tags latest_pnpm` is the cache-buster that re-runs `corepack prepare` on a new pnpm release — it deliberately uses the npm registry instead of the rate-limited GitHub API.
- `new_release_check_pnpm.sh` only accepts plain `vX.Y.Z` tags (skips rc/alpha/beta and `@pnpm/foo@…` subpackage tags); a manual dispatch has no tag to read and falls back to `git tag --sort=-v:refname | head -1`.
- `install-bun.sh` pins glibc `2.34-r0` (with its own removal of `gcompat`/`glibc`/`glibc-bin`) because bun's musl build breaks on the newer glibc; `install-glibc.sh` is the general-purpose installer and pins `2.35-r1`. A real glibc conflicts with the `gcompat` shim, so remove `gcompat` before installing one.
- The build workflows derive the image name from `GITHUB_REPOSITORY` lowercased, so they push `namesmt/linux-stuff` regardless of the git remote's casing, plus the legacy mirror tags.
- Both images switch the default shell to zsh by rewriting `/etc/passwd` and set `SHELL=/bin/zsh`; Alpine's base image also clears the `node` image `ENTRYPOINT`.
- Releasing is automated: pushing a `pnpm*` tag rebuilds every variant and pushes both the plain and suffixed tags. A manual dispatch reads the newest tag instead.
