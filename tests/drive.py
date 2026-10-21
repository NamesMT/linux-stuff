#!/usr/bin/env python3
"""Drive an image's interactive zsh over a pty and report what a user would actually see.

`zsh -c` cannot test this layer: prompts, ZLE widgets, highlighters and completion only
exist in an interactive session. So each scenario boots the image's real zsh inside
`docker run -i` attached to a pty, types at it, and reports observable state.

Emits one JSON object on stdout. Assertions live in run.sh.
"""
from __future__ import annotations

import argparse
import fcntl
import json
import os
import pty
import re
import select
import shutil
import struct
import subprocess
import sys
import tempfile
import termios
import time

READY = '__LINUX_STUFF_READY__'

# Mounted at /probe. Sources the image's own rc, then adds a widget that dumps
# observable ZLE state on ^G. Appending here (not to the image) keeps the image pristine.
PROBE_RC = r'''
source /root/.zshrc
print -r -- "__LINUX_STUFF_READY__"
_probe_dump() {
  {
    print -r -- "BUFFER<<${BUFFER}>>"
    print -r -- "POST<<${POSTDISPLAY}>>"
    print -r -- "ZASYNC<<${functions[zasync]:-MISSING}>>"
    print -r -- "RH<<${(j:|:)region_highlight}>>"
  } > /probe/out.txt
}
zle -N _probe_dump
bindkey '^G' _probe_dump
'''

ANSI_CSI = re.compile(rb'\x1b\[[0-9;?]*[a-zA-Z]')
ANSI_OSC = re.compile(rb'\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)')

# Anything here in output means the shell is misbehaving in front of the user.
ERROR_PATTERNS = (
    'unhandled ZLE widget',
    'command not found',
    'terminfo[',
    'no such file or directory',
    'parse error',
)

TYPEAHEAD_WORDS = ('checkout', 'cherry-pick', 'check-attr', 'check-ignore', 'check-ref-format')


def strip_ansi(data: bytes) -> str:
    data = ANSI_OSC.sub(b'', data)
    data = ANSI_CSI.sub(b'', data)
    return data.decode('utf-8', 'replace')


def errors_in(text: str) -> list[str]:
    return [p for p in ERROR_PATTERNS if p in text]


def parse_probe(text: str) -> dict:
    out = {}
    for key in ('BUFFER', 'POST', 'ZASYNC', 'RH'):
        match = re.search(rf'{key}<<(.*?)>>', text, re.S)
        if match:
            out[key] = match.group(1)
    return out


def image_zshrc(image: str) -> str:
    proc = subprocess.run(
        ['docker', 'run', '--rm', image, 'cat', '/root/.zshrc'],
        capture_output=True, text=True,
    )
    return proc.stdout


class Session:
    """One interactive zsh inside `docker run`, attached to a pty."""

    def __init__(self, image: str, histfile: str = '/dev/null'):
        self.dir = tempfile.mkdtemp(prefix='linux-stuff-zsh-')
        with open(os.path.join(self.dir, '.zshrc'), 'w') as fh:
            fh.write(PROBE_RC)
        self.out_path = os.path.join(self.dir, 'out.txt')
        self.master, slave = pty.openpty()
        fcntl.ioctl(self.master, termios.TIOCSWINSZ, struct.pack('HHHH', 40, 120, 0, 0))
        self.proc = subprocess.Popen(
            [
                # -t is required: without an allocated tty inside the container, zsh
                # disables ZLE, so widgets, completion and highlighting never run.
                'docker', 'run', '--rm', '-i', '-t',
                '-e', 'TERM=xterm-256color',
                '-e', 'LANG=C.UTF-8',
                '-e', f'HISTFILE={histfile}',
                '-e', 'ZDOTDIR=/probe',
                '-v', f'{self.dir}:/probe',
                image, 'zsh', '-i',
            ],
            stdin=slave, stdout=slave, stderr=slave, close_fds=True,
        )
        os.close(slave)

    def drain(self, seconds: float) -> bytes:
        end = time.time() + seconds
        out = b''
        while time.time() < end:
            readable, _, _ = select.select([self.master], [], [], 0.1)
            if not readable:
                continue
            try:
                chunk = os.read(self.master, 65536)
            except OSError:
                break
            if not chunk:
                break
            out += chunk
        return out

    def wait_ready(self, timeout: float = 45.0) -> bytes:
        """Wait for the rc to finish, then for the first prompt to settle."""
        buf = b''
        end = time.time() + timeout
        while time.time() < end and READY not in buf.decode('utf-8', 'replace'):
            buf += self.drain(0.3)
        # Let the first prompt render and any precmd hooks (e.g. autocomplete's
        # helper clone) finish before we start typing.
        idle_deadline = time.time() + 8.0
        while time.time() < idle_deadline:
            chunk = self.drain(0.4)
            if not chunk:
                break
            buf += chunk
        return buf

    def send(self, data: bytes, settle: float = 0.6) -> bytes:
        os.write(self.master, data)
        return self.drain(settle)

    def type_text(self, text: str, per_char: float = 0.25) -> bytes:
        """Type like a human, one keystroke at a time (catches per-keystroke glitches)."""
        out = b''
        for byte in text.encode():
            os.write(self.master, bytes([byte]))
            out += self.drain(per_char)
        return out

    def dump(self, timeout: float = 8.0) -> dict:
        try:
            os.unlink(self.out_path)
        except FileNotFoundError:
            pass
        os.write(self.master, b'\x07')
        end = time.time() + timeout
        while time.time() < end:
            self.drain(0.25)
            if os.path.exists(self.out_path):
                time.sleep(0.2)
                with open(self.out_path, errors='replace') as fh:
                    return parse_probe(fh.read())
        return {}

    def kill_line(self) -> None:
        os.write(self.master, b'\x15')
        self.drain(0.3)

    def close(self) -> None:
        try:
            os.write(self.master, b'\x03')
            self.drain(0.2)
            os.write(self.master, b'exit\n')
            self.drain(0.5)
        except OSError:
            pass
        try:
            self.proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.proc.kill()
        try:
            os.close(self.master)
        except OSError:
            pass
        shutil.rmtree(self.dir, ignore_errors=True)


def scenario_startup(image: str) -> dict:
    session = Session(image)
    boot = strip_ansi(session.wait_ready())
    session.close()
    return {'errors': errors_in(boot), 'tail': boot.strip().splitlines()[-6:]}


def scenario_highlight(image: str) -> dict:
    session = Session(image)
    session.wait_ready()
    session.type_text('echo hi')
    state = session.dump()
    session.close()
    rh = state.get('RH', '')
    return {'has_fsh_paint': 'memo=F-Sy-H' in rh, 'region_highlight': rh[:200]}


def scenario_history_up(image: str) -> dict:
    session = Session(image)
    session.wait_ready()
    session.send(b'echo HISTMARK_9137\n', 1.2)
    session.send(b'\x1b[A', 1.5)  # Up arrow
    state = session.dump()
    session.close()
    buffer = state.get('BUFFER', '')
    return {'buffer': buffer, 'recalled': 'HISTMARK_9137' in buffer}


def scenario_tab_complete(image: str) -> dict:
    session = Session(image)
    session.wait_ready()
    session.type_text('git checko')
    session.send(b'\t', 1.5)
    state = session.dump()
    session.close()
    buffer = state.get('BUFFER', '').strip()
    return {'buffer': buffer, 'completed': buffer.endswith('checkout')}


def scenario_typing(image: str) -> dict:
    typed = 'echo abcdefghij_klmno'
    session = Session(image)
    session.wait_ready()
    out = session.type_text(typed)
    state = session.dump()
    session.close()
    buffer = state.get('BUFFER', '').strip()
    return {
        'buffer': buffer,
        'intact': buffer == typed,
        'errors': errors_in(strip_ansi(out)),
    }


def scenario_autosuggest(image: str) -> dict:
    """POSTDISPLAY holds only the *untyped* remainder, so compare the whole line."""
    typed, command = 'echo SUGM', 'echo SUGMARK_4242'
    session = Session(image)
    session.wait_ready()
    session.send(b'echo SUGMARK_4242\n', 1.2)
    session.type_text(typed)
    state = session.dump()
    session.close()
    post = state.get('POST', '')
    return {
        'postdisplay': post,
        'completed': (typed + post).strip(),
        'suggested': bool(post) and (typed + post).strip() == command,
    }


def scenario_typeahead(image: str) -> dict:
    """Only meaningful when zsh-autocomplete is installed: it must actually render.

    HISTFILE=/dev/null so zsh-autosuggestions cannot replay history and fake a result.
    """
    session = Session(image, histfile='/dev/null')
    session.wait_ready()
    out = session.type_text('git ch', per_char=0.3)
    out += session.drain(4.0)
    state = session.dump()
    session.close()
    text = strip_ansi(out)
    zasync = state.get('ZASYNC', 'MISSING')
    return {
        'candidates': sorted({w for w in TYPEAHEAD_WORDS if w in text}),
        'zasync': zasync[:80],
        'zasync_stub': zasync == 'MISSING' or zasync.startswith('builtin autoload'),
    }


SCENARIOS = {
    'startup': scenario_startup,
    'highlight': scenario_highlight,
    'history_up': scenario_history_up,
    'tab_complete': scenario_tab_complete,
    'typing': scenario_typing,
    'autosuggest': scenario_autosuggest,
    'typeahead': scenario_typeahead,
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--image', required=True)
    parser.add_argument('--scenarios', default=','.join(SCENARIOS))
    args = parser.parse_args()

    wanted = [s.strip() for s in args.scenarios.split(',') if s.strip()]
    zshrc = image_zshrc(args.image)
    has_autocomplete = 'zsh-autocomplete' in zshrc

    report = {
        'image': args.image,
        'plugins': re.search(r'^plugins=\((.*)\)', zshrc, re.M).group(1).strip()
        if re.search(r'^plugins=\((.*)\)', zshrc, re.M) else None,
        'has_autocomplete': has_autocomplete,
        'scenarios': {},
    }

    for name in wanted:
        if name == 'typeahead' and not has_autocomplete:
            report['scenarios']['typeahead'] = {'skipped': 'zsh-autocomplete not installed'}
            continue
        report['scenarios'][name] = SCENARIOS[name](args.image)

    json.dump(report, sys.stdout, indent=2)
    sys.stdout.write('\n')
    return 0


if __name__ == '__main__':
    sys.exit(main())
