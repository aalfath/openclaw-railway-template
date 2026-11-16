# OpenClaw gateway for Railway.
# Official image, pinned by version and digest. Bump both together and add a CHANGELOG entry.
FROM ghcr.io/openclaw/openclaw:2026.11.3@sha256:e73f689d663567f0fe3c5a85c54beb3e102dc21f0814bf375e9039ee2d2df51b

USER root

# Everything OpenClaw keeps (config, credentials, SQLite state, sessions, workspace,
# auth-profile secrets, installed plugins) lives under /data, which the template mounts
# as a Railway volume.
ENV HOME=/data \
    OPENCLAW_HOME=/data \
    OPENCLAW_STATE_DIR=/data/.openclaw \
    OPENCLAW_CONFIG_PATH=/data/.openclaw/openclaw.json \
    OPENCLAW_WORKSPACE_DIR=/data/workspace \
    TERM=xterm-256color

COPY --chmod=0755 start.sh /usr/local/bin/openclaw-railway-start
# `openclaw` in a Railway shell (which runs as root) runs the CLI as the `node` user,
# so it never leaves root-owned files on the volume. The image ships `openclaw` as a
# symlink to /app/openclaw.mjs, so copy the wrapper elsewhere and repoint the symlink
# (a COPY onto the symlink would overwrite the app itself).
COPY --chmod=0755 openclaw-cli.sh /usr/local/bin/openclaw-cli
RUN ln -sf /usr/local/bin/openclaw-cli /usr/local/bin/openclaw

EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/openclaw-railway-start"]
