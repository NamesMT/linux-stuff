# Interactive zsh smoke tests

Checks what a user actually notices in the `-node-dev` images: clean startup, syntax
highlighting, Up-arrow history, Tab completion, autosuggestions, type-ahead, and no
glitching while typing.

```sh
tests/run.sh namesmt/linux-stuff:alpine-node-dev
tests/run.sh                       # both dev images, if built locally
```

Needs `docker` and `python3`. Exits non-zero on any failed check.

## Why a pty

`zsh -c` cannot test this layer — prompts, ZLE widgets, highlighters and completion only
exist in an interactive session. `drive.py` boots the image's real zsh inside
`docker run -i -t` attached to a pty, types at it, and reports observable state as JSON.
`-t` is required: without an allocated tty inside the container, zsh disables ZLE and every
widget check would silently pass or fail for the wrong reason.

Assertions live in `run.sh`; `drive.py` only observes. That split lets the same driver be
pointed at a candidate image (e.g. a different `zsh-autocomplete` pin) without rewriting checks.

## Two things that make it honest

- **Type-ahead runs with `HISTFILE=/dev/null`.** Otherwise `zsh-autosuggestions` replays
  history and a rendered word looks like autocomplete working. That false positive is why
  `scenario_typeahead` exists separately from `scenario_autosuggest`.
- **State is read from ZLE, not from the screen.** A `^G` widget dumps `$BUFFER`,
  `$POSTDISPLAY` and `$region_highlight`, so assertions do not depend on ANSI rendering.
  `POSTDISPLAY` holds only the *untyped remainder*, hence the concatenation in
  `scenario_autosuggest`.

## Adding a check

Add a `scenario_*` function to `drive.py`, register it in `SCENARIOS`, then assert on it in
`run.sh`. Break the thing it guards and confirm the suite fails before committing it.
