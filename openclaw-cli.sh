#!/bin/sh
# Wrapper for the OpenClaw CLI: run as the unprivileged `node` user, never as root,
# with HOME on the volume (a Railway shell sets HOME=/root, which `node` can't use).
export HOME=/data
if [ "$(id -u)" = "0" ]; then
  exec setpriv --reuid=node --regid=node --init-groups node /app/openclaw.mjs "$@"
fi
exec node /app/openclaw.mjs "$@"
