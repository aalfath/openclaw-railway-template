#!/bin/sh
# Start script for OpenClaw on Railway. Runs as root only long enough to prepare the
# volume, then runs the official entrypoint (doctor --fix, then the gateway) as `node`.
set -eu

PORT="${PORT:-8080}"
export OPENCLAW_GATEWAY_PORT="$PORT"

if [ -z "${OPENCLAW_GATEWAY_TOKEN:-}" ]; then
  echo "OPENCLAW_GATEWAY_TOKEN is empty. Set it to a long random value, then redeploy." >&2
  exit 1
fi

# Railway mounts volumes owned by root. Hand everything under /data to `node`
# (also fixes files a root shell may have created).
mkdir -p "$OPENCLAW_STATE_DIR" "$OPENCLAW_WORKSPACE_DIR"
find /data -xdev ! -user node -exec chown -h node:node {} + 2>/dev/null || true

as_node() { setpriv --reuid=node --regid=node --init-groups "$@"; }

# The browser origin the Control UI is served from. Railway sets RAILWAY_PUBLIC_DOMAIN;
# OPENCLAW_PUBLIC_ORIGIN overrides it (for a custom domain, e.g. https://claw.example.com).
ORIGIN="${OPENCLAW_PUBLIC_ORIGIN:-}"
if [ -z "$ORIGIN" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  ORIGIN="https://${RAILWAY_PUBLIC_DOMAIN}"
fi

# Gateway settings this deployment depends on, re-applied on every boot:
# local mode, the port (so `openclaw` in a shell finds the gateway), token auth (the token itself stays in the environment), and Railway's
# edge proxy range so client addresses behind it are attributed correctly.
GATEWAY_JSON="{\"mode\":\"local\",\"port\":${PORT},\"auth\":{\"mode\":\"token\"},\"trustedProxies\":[\"100.64.0.0/10\"]"
if [ -n "$ORIGIN" ]; then
  GATEWAY_JSON="${GATEWAY_JSON},\"publicOrigin\":\"${ORIGIN}\""
fi
GATEWAY_JSON="${GATEWAY_JSON}}"
cd /app
# Skip the write when openclaw.json already has these values (the usual redeploy).
if ! GATEWAY_JSON="$GATEWAY_JSON" node -e '
  const want = JSON.parse(process.env.GATEWAY_JSON);
  let have = {};
  try { have = JSON.parse(require("fs").readFileSync(process.env.OPENCLAW_CONFIG_PATH, "utf8")).gateway || {}; } catch {}
  const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
  const ok = Object.keys(want).every((k) => k === "auth" ? (have.auth || {}).mode === want.auth.mode : same(have[k], want[k]));
  process.exit(ok ? 0 : 1);
'; then
  # After a redeploy the previous container's state lock stays fresh for up to 90 s,
  # and `config set` refuses to write until it expires. Retry, but never fail the boot:
  # the gateway still starts with the config saved on the volume.
  i=0
  until as_node node /app/openclaw.mjs config set gateway "$GATEWAY_JSON" --strict-json --merge >/dev/null 2>/tmp/config-set.err; do
    i=$((i + 1))
    if [ "$i" -ge 30 ]; then
      echo "Could not update gateway settings in openclaw.json; starting with the saved ones:" >&2
      cat /tmp/config-set.err >&2
      break
    fi
    sleep 5
  done
fi

# The official entrypoint runs `openclaw doctor --fix --non-interactive` (state repair and
# migrations after an image update) and then the gateway in the foreground.
exec setpriv --reuid=node --regid=node --init-groups \
  tini -s -- node /app/docker-entrypoint.mjs \
  node openclaw.mjs gateway --bind lan --port "$PORT"
