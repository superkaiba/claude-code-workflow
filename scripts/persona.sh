#!/usr/bin/env bash
# persona.sh — open a persistent Happy session on the VM for the /issue workflow.
#
# Design: spawn the session through the local Happy DAEMON (not tmux, not a
# foreground SSH process). The daemon runs the Claude/Happy session as its own
# background child on the VM and registers it with the Happy relay, so:
#   - it shows up in the Happy app on your phone,
#   - it is independent of this SSH connection — close your laptop (SIGHUP just
#     drops the SSH client) and the session keeps running on the VM,
#   - any work it kicks off (worktrees, experiment runs, pods) keeps going too.
# You then open the session on your phone and type `/issue <N>` to drive it.
#
# This is the same daemon-spawn path the PM session uses (scripts/spawn_session.py)
# — we reuse that module's tested daemon-RPC helpers rather than re-implementing
# the control-server contract here.
#
# Usage (typically via the `persona` alias):
#   gcloud compute ssh cia-benchmark-vm ... --command "bash .../scripts/persona.sh"
set -euo pipefail

# uv / happy on PATH even in non-login shells.
export PATH="$HOME/.local/bin:$PATH"
cd "$HOME/your-project"

command -v happy   >/dev/null 2>&1 || { echo "persona.sh: happy not found on PATH"   >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "persona.sh: python3 not found on PATH" >&2; exit 1; }

# Make sure the daemon that hosts background sessions is up (idempotent: status
# returns 0 when already running, so we only start it when it's actually down).
if ! happy daemon status >/dev/null 2>&1; then
  echo "persona.sh: Happy daemon not running — starting it (detached)."
  happy daemon start
fi

# Spawn a fresh background session at the repo root via the daemon RPC, reusing
# spawn_session.py's helpers (daemon-port discovery + POST). Manual session: it
# opens empty so you invoke /issue <N> yourself from the phone.
python3 - <<'PY'
import sys
sys.path.insert(0, "scripts")
import spawn_session as ss

resp = ss.post("/spawn-session", {"directory": str(ss.PROJECT_ROOT), "agent": "claude"})
if not resp.get("success"):
    sys.exit(f"persona.sh: spawn failed: {resp}")

sid = resp["sessionId"]
print(f"persona.sh: Happy session spawned: {sid}")
print(f"persona.sh:   cwd: {ss.PROJECT_ROOT}")
print("persona.sh: open it in the Happy app on your phone and type `/issue <N>`.")
print("persona.sh: it runs on the VM under the Happy daemon — close your laptop, "
      "it keeps running and any work it starts continues in the background.")
PY
