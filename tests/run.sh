#!/usr/bin/env bash
# Interactive smoke tests for the zsh layer of the dev images.
#
# Boots each image's real zsh on a pty and checks what a user would notice:
# clean startup, working highlighting, history (Up), Tab completion, type-ahead
# (when zsh-autocomplete is installed), autosuggestions, and no glitching while typing.
#
# Usage:
#   tests/run.sh                                  # default dev images, if built locally
#   tests/run.sh namesmt/linux-stuff:arch-node-dev
set -uo pipefail

here=$(cd "$(dirname "$0")" && pwd)

images=("$@")
if [ ${#images[@]} -eq 0 ]; then
  images=(namesmt/linux-stuff:alpine-node-dev namesmt/linux-stuff:arch-node-dev)
fi

status=0
for image in "${images[@]}"; do
  if ! docker image inspect "$image" >/dev/null 2>&1; then
    echo "SKIP  $image (not present locally)"
    continue
  fi

  echo "== $image"
  report=$(mktemp)
  trap 'rm -f "$report"' EXIT

  if ! python3 "$here/drive.py" --image "$image" >"$report"; then
    echo "  FAIL  could not drive the image (see output above)"
    status=1
    rm -f "$report"; trap - EXIT
    continue
  fi

  python3 - "$report" <<'PY' || status=1
import json, sys

report = json.load(open(sys.argv[1]))
scen = report['scenarios']
checks = []

def check(name, ok, detail=''):
    checks.append((name, bool(ok), detail))

s = scen.get('startup', {})
check('startup is clean', not s.get('errors'), ', '.join(s.get('errors', [])))

h = scen.get('highlight', {})
check('syntax highlighting active', h.get('has_fsh_paint'), h.get('region_highlight', ''))

hi = scen.get('history_up', {})
check('Up arrow recalls history', hi.get('recalled'), repr(hi.get('buffer', ''))[:60])

t = scen.get('tab_complete', {})
check('Tab completion works', t.get('completed'), repr(t.get('buffer', ''))[:60])

ty = scen.get('typing', {})
check('typing is not glitched', ty.get('intact'), repr(ty.get('buffer', ''))[:60])
check('no errors while typing', not ty.get('errors'), ', '.join(ty.get('errors', [])))

a = scen.get('autosuggest', {})
check('autosuggestions work', a.get('suggested'), repr(a.get('postdisplay', ''))[:60])

ta = scen.get('typeahead', {})
if 'skipped' in ta:
    print('  SKIP  type-ahead (%s)' % ta['skipped'])
else:
    check('type-ahead renders (no history to fake it)', ta.get('candidates'), str(ta.get('candidates')))
    # Versions predating the zasync rewrite have no such function, so absence is fine;
    # an unresolved `builtin autoload` stub is the failure.
    zasync = ta.get('zasync', 'MISSING')
    check('zasync is not an unresolved stub', not zasync.startswith('builtin autoload'), zasync[:60])

failed = 0
for name, ok, detail in checks:
    if ok:
        print('  PASS  %s' % name)
    else:
        failed += 1
        print('  FAIL  %s%s' % (name, ('  <- %s' % detail) if detail else ''))

sys.exit(1 if failed else 0)
PY
  rm -f "$report"; trap - EXIT
done

echo
if [ "$status" -ne 0 ]; then
  echo "FAILED"
  exit 1
fi
echo "OK"
