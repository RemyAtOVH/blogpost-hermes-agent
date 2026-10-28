# Telegram is a no-go? Talk to your agent over Signal.

Signal gives you end-to-end encryption **by default** — the plaintext of your
conversations with the agent exists only on your phone and on this VPS. That
fixes **content confidentiality**. It does **not** change where the transport
lives (Signal servers run on US infrastructure): for channel-jurisdiction
sovereignty, self-host **Matrix** — or use **SimpleX** — on this very VPS; the
Hermes gateway supports both.

> **The channel carries the encryption, the VPS carries the sovereignty.**

Hermes talks to Signal through
[`signal-cli`](https://github.com/AsamK/signal-cli) running as a local HTTP
daemon (native mode). Your agent registers as a **linked device** — like
WhatsApp Web — so there is no extra phone number and no SMS dance.

> ⚠️ **Two things to know before you start**
>
> 1. Do everything as the **same Linux user** (below: your SSH user, e.g.
>    `debian`). The link state lives in `~/.local/share/signal-cli`.
> 2. The popular `bbernhard/signal-cli-rest-api` Docker image exposes a
>    **different REST API**, not the native daemon mode Hermes expects — don't
>    substitute it. There is no official signal-cli image; native install +
>    systemd is the cleanest path.

## 1 — Install signal-cli (native build, no Java needed)

The Java build of signal-cli now requires Java 25, newer than Debian's default
JRE. The **native** build is a single self-contained binary — no JRE at all.

```bash
sudo apt-get update && sudo apt-get install -y qrencode
VERSION=$(curl -Ls -o /dev/null -w '%{url_effective}' \
  https://github.com/AsamK/signal-cli/releases/latest | sed 's/^.*\/v//')
curl -L -O "https://github.com/AsamK/signal-cli/releases/download/v${VERSION}/signal-cli-${VERSION}-Linux-native.tar.gz"
sudo tar xf "signal-cli-${VERSION}-Linux-native.tar.gz" -C /usr/local/bin signal-cli
signal-cli --version
```

## 2 — Link your Signal account (one-time, interactive)

```bash
signal-cli link -n "HermesAgent" | tee >(xargs -L 1 qrencode -t utf8)   # prints a QR in your terminal
```

(`tee` + `xargs -L 1` renders the QR as soon as the link URI is printed —
piping straight into `qrencode` would wait for `signal-cli` to exit, which only
happens *after* you've scanned.)

Scan it from your phone: **Signal → Settings → Linked devices → Link new
device**. (Over SSH, `qrencode` renders the QR right in the terminal; drop it
and keep the raw `tsdevice://` URI if you prefer.)

## 3 — Run the daemon at boot

```bash
# edit signal-cli.service: your number + your username, then:
sudo cp signal-cli.service /etc/systemd/system/
sudo systemctl daemon-reload && sudo systemctl enable --now signal-cli
curl -s http://127.0.0.1:8080/api/v1/check   # sanity check → {"versions":…}
```

## 4 — Point Hermes at it

Easiest: `hermes gateway setup` → pick **Signal** — the wizard probes the
daemon and asks for your number and allowlist. Or configure manually in
`~/.hermes/.env`:

```bash
SIGNAL_HTTP_URL=http://127.0.0.1:8080
SIGNAL_ACCOUNT=+33612345678
SIGNAL_ALLOWED_USERS=+33612345678        # who may talk to the agent
SIGNAL_HOME_CHANNEL=+33612345678         # default target for cron jobs
```

Then finish with step 5 of `deploy.sh`:

```bash
sudo env HERMES_HOME="$HOME/.hermes" "$HOME/.local/bin/hermes" gateway install --system &&
  sudo chown -R "$(id -u):$(id -g)" "$HOME/.hermes"
```

(If `hermes gateway setup` offers to install a user service, pick **Skip** —
this command installs the boot-time system service instead.)

## Differences vs Telegram

| | Telegram | Signal |
|---|---|---|
| setup time | ~5 min | ~20 min |
| E2E by default | ❌ (secret chats only) | ✅ |
| streaming replies | ✅ | ❌ (typing indicator; replies chunked every 8 000 chars) |
| threads | ✅ | ❌ |
| attachments | ✅ | ✅ (≤ 100 MB, server-side rate limits) |
| agent identity | bot token | linked device |

## Ops notes

- **Back up `~/.local/share/signal-cli`** — it holds the identity keys. Losing
  it means re-linking the device, and your phone will warn that the "contact"
  changed (safety number).
- signal-cli is a *community* client, not an official Signal product: pin the
  version, update deliberately, expect occasional breakage after Signal-side
  changes.
- Group chats are ignored by default; opt in with `SIGNAL_GROUP_ALLOWED_USERS`.
