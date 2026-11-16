# Changelog

Each entry is one update of this template. Breaking changes are listed first.
Railway offers every update to existing deployments; read the entry before you apply it,
and back up first (`openclaw backup create` in the service shell).

## 2026.11.3-1 (2026-11-16)

- README: Deploy on Railway button for the published template `openclaw-9`. No change to the image or the start script.

## 2026.11.3 (2026-11-16)

- First release: OpenClaw 2026.11.3, official image
  `ghcr.io/openclaw/openclaw:2026.11.3@sha256:e73f689d663567f0fe3c5a85c54beb3e102dc21f0814bf375e9039ee2d2df51b`.
- One service, one volume at `/data`, gateway token generated at deploy.
