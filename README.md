# Hermes Agent on an always-on OVHcloud instance

> Companion repo for the blog post **« Votre agent IA ne devrait pas s'endormir quand vous fermez votre laptop »**
> (*EN: "Your AI agent shouldn't sleep when you close your laptop"*).
> Bootstrap [Hermes Agent](https://github.com/NousResearch/hermes-agent) (open source, MIT, by [Nous Research](https://nousresearch.com)) on OVHcloud in about 10 minutes —
> either on a **disposable Public Cloud instance** (billed by the hour) or on an always-on [VPS](https://www.ovhcloud.com/en/vps/vps-hermes-agent/).

```text
   you — Telegram / Signal / Slack / Matrix / …30+ platforms
        │   (one config line per channel)
        ▼
┌──────────────── OVHcloud instance — VPS or Public Cloud ────────┐
│  hermes gateway ──► hermes agent                                 │
│  persistent memory · self-improving skills · cron · sub-agents   │
│  model-agnostic: OpenRouter / OpenAI / Nous Portal / custom      │
└───────────────────────────────────────────────────────────────────┘
        │
        ▼
   your tools, APIs, MCP servers, stack
```

## What you end up with

- An agent that stays online when your laptop doesn't.
- Chat with it from **Telegram** in ~5 minutes — or **Signal** ([SIGNAL.md](SIGNAL.md)), Slack, Discord, Mattermost, Matrix, Teams… all from the same gateway.
- Scheduled automations in natural language, persistent memory, skills that improve with use.

## Prerequisites

- **OVHcloud API credentials** — create at <https://www.ovh.com/auth/api/createToken>:
  - Path A: `GET/POST/PUT/DELETE /v2/publicCloud/project/*` — the provider uses OVHcloud **API v2** for Public Cloud (`/cloud/*` v1 rights are not enough)
  - Path B: `GET/POST/PUT/DELETE` on `/vps/*`, `/order/*` and `/me/*` — ordering goes through a cart and pays with your default payment method; `destroy` reads the termination token from your account notification emails.
- **Terraform** ≥ 1.6, **SSH key pair** (`~/.ssh/id_ed25519.pub`).
- Path A only: a **Public Cloud project** — its id is the `service_name`.
- Path B only: a **default payment method** — ordering a VPS via the API requires one.

## Path A — prototype it (Public Cloud, hourly billing)

Create it, test it, shelve it, destroy it. A one-hour test session costs cents.

```bash
export OVH_ENDPOINT="ovh-eu" OVH_APPLICATION_KEY="…" OVH_APPLICATION_SECRET="…" OVH_CONSUMER_KEY="…"
export TF_VAR_service_name="<public cloud project id>"
export TF_VAR_public_ssh_key="$(cat ~/.ssh/id_ed25519.pub)"

terraform -chdir=public-cloud init
terraform -chdir=public-cloud apply
./deploy.sh debian@$(terraform -chdir=public-cloud output -raw instance_ip)
```

Done for the day? Three options:

```bash
terraform -chdir=public-cloud apply -var="power_state=SHELVED"   # pause — released from the hypervisor,
                                                                # storage billed only; ACTIVE resumes in place
terraform -chdir=public-cloud apply -var="power_state=SHUTOFF"  # stop, flavor still billed
terraform -chdir=public-cloud destroy                           # really done — gone
```

## Path B — keep it (VPS, monthly — the article's path)

```bash
export OVH_ENDPOINT="ovh-eu" OVH_APPLICATION_KEY="…" OVH_APPLICATION_SECRET="…" OVH_CONSUMER_KEY="…"
export TF_VAR_public_ssh_key="$(cat ~/.ssh/id_ed25519.pub)"

terraform -chdir=vps init
terraform -chdir=vps apply
./deploy.sh debian@$(terraform -chdir=vps output -raw vps_ip)
```

## `deploy.sh` — shared by both paths, five steps over SSH

1. prerequisites (`git`, `curl`, `xz-utils`, `libatomic1`) — waits for first-boot cloud-init/apt jobs to finish
2. the [official Hermes installer](https://hermes-agent.nousresearch.com/docs/getting-started/installation), non-interactive — fetches its own pinned Python, Node.js, ripgrep, ffmpeg and a headless Chromium (~2 min)
3. `hermes model` — pick your provider/model *(interactive)*
4. `hermes gateway setup` — connect Telegram *(interactive)*. Two choices to make:
   - **Bot creation: pick `[2] Manual BotFather token`.** The preselected `[1] Automatic` creates the bot through a Nous-hosted onboarding service (`@HermesSetupBot`), so your bot token transits a third party — not what you want on a sovereign setup. Manual takes one extra minute: in Telegram, message [@BotFather](https://t.me/BotFather), send `/newbot`, pick a name, and paste the token it returns.
   - **Service: pick `Skip service install for now`.** The preselected *User service* would stop when you log out — step 5 installs a boot-time system service instead.
5. `hermes gateway install --system` — boot-time systemd service, running as your user: the agent comes back by itself after a reboot

Open Telegram, say hi to your bot: your agent is live, 24/7. Diagnose anytime with `hermes doctor`.

> Default user on current OVHcloud Debian images is `debian` (passwordless sudo) — on VPS and Public Cloud alike. On older VPS images, use `root@`.

## Variables — `public-cloud/`

| Name | Default | Notes |
|---|---|---|
| `service_name` | — | **required** — Public Cloud project id |
| `region` | `GRA11` | SBG5, DE1, UK1… |
| `flavor_name` | `b3-8` | resolved by commercial name from the project catalog |
| `image_name` | `Debian 13` | try `Debian 12` if your catalog lags |
| `instance_name` | `hermes-agent` | |
| `power_state` | `ACTIVE` | `SHUTOFF`, or `SHELVED` to pause (storage-only billing) |
| `public_ssh_key` | — | **required** |

> `ovh_cloud_instance` also supports cloud-init via `user_data` — we keep the bootstrap in `deploy.sh` so both paths share one flow. Note that changing `user_data` **reinstalls the instance** (root disk wiped): see the [provider docs](https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/cloud_instance).

## Variables — `vps/`

| Name | Default | Notes |
|---|---|---|
| `ovh_endpoint` | `ovh-eu` | |
| `vps_display_name` | `hermes-agent` | |
| `vps_plan_code` | `vps-2027-model1` | VPS-1 from the 2027 range sold by the [Hermes Agent offering](https://www.ovhcloud.com/en/vps/vps-hermes-agent/) (2 vCores, 4 GB RAM, 40 GB NVMe). Other plan codes come from the [VPS catalog](https://eu.api.ovh.com/console/#/order%2Fcatalog%2Fpublic%2Fvps~GET). |
| `vps_datacenter` | `WAW` | GRA, SBG, DE, WAW… pick your EU datacenter |
| `vps_os` | `Debian 13` | |
| `vps_image_id` | see `variables.tf` | Required when `public_ssh_key` is set: after the order, the provider rebuilds the VPS with this image + your key. Must match `vps_os`. If `apply` fails at that rebuild step, the VPS is already ordered and in state — look up the Debian 13 id in the [available images](https://eu.api.ovh.com/console/?section=%2Fvps&branch=v1#get-/vps/-serviceName-/images/available), set it, re-apply. |
| `public_ssh_key` | — | **required** |

## Telegram is a no-go in your org?

**The channel carries the encryption, the VPS carries the sovereignty.**

- **Signal** — end-to-end encrypted by default; the agent registers as a linked device: see [SIGNAL.md](SIGNAL.md) (~20 min).
- **Full channel sovereignty** — self-host **Matrix** (or use SimpleX) on this very instance: both are supported by the gateway.
- **Enterprise-blessed channels** — Slack, Microsoft Teams, Mattermost, Google Chat work too.

Each channel is a config line, not a commitment — you can run several at once.

## Security checklist

- [ ] Set the per-platform allowlists (`*_ALLOWED_USERS` in `~/.hermes/.env`) — **your agent has shell access**, don't let strangers DM it.
- [ ] Firewall: keep only SSH exposed. The gateway makes *outbound* connections only.
- [ ] Give the agent **scoped tokens** to your stack — never blanket production credentials.
- [ ] Back up `~/.hermes` (and signal-cli state if you use Signal).
- [ ] Check what your model provider logs — runtime sovereignty is the whole point of this setup.

## Layout

```text
├── deploy.sh            SSH bootstrap — 5 steps, shared by both paths
├── SIGNAL.md            Signal variant (signal-cli, linked device)
├── signal-cli.service   systemd unit for the signal-cli daemon
├── vps/                 Path B — ovh_vps (monthly)
└── public-cloud/        Path A — ovh_cloud_instance (hourly, shelvable)
```

## Versions & costs

- Versions: `ovh/ovh` Terraform provider 2.x (≥ 2.20), Hermes Agent v0.22+, Debian 13. Run `terraform plan` before `apply` to review what will be created.
- Timings: a Public Cloud instance is up in ~2 min, the Hermes install takes ~2 min, and a `SHELVED` → `ACTIVE` cycle ~2 min each way (same IP, install intact).
- Costs: Path A is billed by the hour (a full test session ≈ cents); Path B starts at €4.49/month excl. VAT as of October 2026 (VPS-1: 2 vCores, 4 GB RAM, 40 GB NVMe, daily backup, unlimited traffic). Plus your model usage. If you'd rather skip the VPS part entirely, OVHcloud also sells managed hosting for Hermes Agent with AI credits included — see the product page.
