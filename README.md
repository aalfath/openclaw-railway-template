[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/openclaw-9?utm_medium=integration&utm_source=button&utm_campaign=openclaw)

# OpenClaw on Railway

A Railway template for [OpenClaw](https://github.com/openclaw/openclaw), the self-hosted personal AI agent: one gateway with its web Control UI, reachable from your browser and from chat apps (Telegram, Discord, Slack, WhatsApp and more).

- **Version:** OpenClaw 2026.11.3, the official image `ghcr.io/openclaw/openclaw:2026.11.3`, pinned by digest in the [`Dockerfile`](Dockerfile).
- **Services:** one, built from this repo. **Volume:** `/data` (config, credentials, SQLite state, sessions, the agent workspace, installed plugins).
- **Security:** the gateway and the Control UI require the generated `OPENCLAW_GATEWAY_TOKEN`, and every new browser must also be paired from the service shell. The gateway runs as the image's unprivileged `node` user, not root.

## What this repo adds to the official image

- [`start.sh`](start.sh): prepares the volume, writes the few gateway settings Railway needs into `openclaw.json` (local mode, port, token auth, your Railway domain as the public origin, Railway's proxy range), then runs the official entrypoint as `node`. That entrypoint runs `openclaw doctor --fix` (state repair and migrations after an update) and then the gateway.
- [`openclaw-cli.sh`](openclaw-cli.sh): `openclaw` in a Railway shell runs as `node`, so it never leaves root-owned files on the volume.

## Variables

| Variable | Default | What it is |
|---|---|---|
| `OPENCLAW_GATEWAY_TOKEN` | generated (`${{secret(48)}}`) | Admin secret for the gateway and the Control UI. Paste it on the login screen. |
| `PORT` | `8080` | Port the gateway listens on and Railway routes the domain to. |

Optional, set them in the service's Variables tab when you need them:

- A provider key such as `ANTHROPIC_API_KEY`, `OPENAI_API_KEY` or `OPENROUTER_API_KEY`, if you prefer a variable to adding the provider in the Control UI (see the [providers docs](https://docs.openclaw.ai/providers)).
- Channel credentials such as `TELEGRAM_BOT_TOKEN` (see [channels](https://docs.openclaw.ai/channels)).
- `OPENCLAW_PUBLIC_ORIGIN`: the URL you open the Control UI from, when it isn't the Railway domain (a custom domain, e.g. `https://claw.example.com`).

## First login

1. Open the service's Railway domain, paste `OPENCLAW_GATEWAY_TOKEN` (service → Variables) into **Gateway secret** and click **Connect**.
2. The page says **Approve this browser** and shows a command such as `openclaw devices approve 6bfa8820-…`.
3. Open the service shell (`railway ssh`, or right-click the service → SSH) and run that command. The page connects by itself.

Then connect a model in **Settings → Models → Connect provider**, or run `openclaw onboard` in the shell. Chat channels (Telegram, Discord, Slack, WhatsApp …) are set up in **Settings → Channels**.

## Updates

This template builds from this repo, so Railway shows existing deployments an "update available" notice whenever a new version is merged into `main`. Each version is listed in [`CHANGELOG.md`](CHANGELOG.md). Back up first with `openclaw backup create` in the service shell. On boot after an update, the official entrypoint runs `openclaw doctor --fix` to migrate the state before the gateway starts.

## Notes

- Give the service at least 2 GB of memory. Upstream recommends 2 GB, and the doctor and the gateway together peak at about 1.3 GB.
- The agent's shell and file tools run inside this container, with `/data/workspace` as their workspace.
- Keep one replica: one gateway per volume.
