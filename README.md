# PortableDevSetup

A portable, cross-machine development environment that works the same on macOS
(arm64), Fedora (x86_64), and a remote Linux VM.

## Architecture

A **hybrid** of two decoupled layers:

- **Host layer** — shell, editor and terminal tooling run natively on every
  machine: Neovim, herdr (tmux kept as the alternative), zsh, starship, fzf,
  ripgrep, fd, bat. Managed by
  [**chezmoi**](https://www.chezmoi.io) (dotfiles) + [**mise**](https://mise.jdx.dev)
  (tools & runtimes).
- **Project layer** _(later phase)_ — per-project `mise.toml` pins toolchains,
  optionally wrapped in a dev container (via DevPod) when isolation or
  sandboxing is needed.

The editor stays on the host because a containerized Neovim brings arch-specific
Mason/treesitter artifacts plus clipboard/font/ssh-agent friction.

## Layout

```
.chezmoiroot                 # → home  (chezmoi source lives under home/)
home/                        # chezmoi source
  .chezmoi.toml.tmpl         # init-time prompts (email, commit signing, multiplexer)
  .chezmoiexternal.toml      # clones nvim config, tpm, zsh plugins on apply
  .chezmoiignore             # e.g. skip ghostty off macOS
  dot_zshrc.tmpl             # one OS-branched zshrc
  dot_zprofile.tmpl          # login bootstrap (brew shellenv per OS)
  dot_tmux.conf.tmpl         # clipboard branches pbcopy/wl-copy
  dot_gitconfig.tmpl         # commit signing toggled per machine
  dot_config/
    mise/config.toml.tmpl    # the portable toolchain manifest
    starship.toml            # shared verbatim (identical on all hosts)
    ghostty/config           # macOS terminal
    herdr/config.toml        # the ~/.tmux.conf keymap, ported onto herdr
    tmux-sessionizer/paths   # created once with ~/Code; edit per host, never clobbered
                             #   shared by both sessionizers, prefix notwithstanding
  dot_local/scripts/         # tmux-sessionizer, herdr-sessionizer
bootstrap.sh                 # one-shot installer for a fresh machine
devcontainers/               # (Phase 3) dev container base image + templates
```

## Key decisions

- **Neovim**: the standalone repo
  [`QuantumDancer/astronvim_config`](https://github.com/QuantumDancer/astronvim_config)
  (AstroNvim v6) is referenced via `.chezmoiexternal.toml`, not vendored here.
- **mise owns dev CLIs & runtimes** — replaces `bob`, `nvm` and ad-hoc
  cargo/go/bun PATH shims. Homebrew/dnf keep only GUI apps, fonts and system
  services.
- **This repo is the chezmoi source dir**, pinned via `sourceDir` in the
  generated config so bare `chezmoi apply`/`diff` never fall back to the default
  `~/.local/share/chezmoi`.
- **Commit signing uses SSH keys** (`gpg.format = ssh`, `~/.ssh/id_ed25519.pub`),
  not GPG — it reuses the forwarded ssh-agent and works inside containers.
- **herdr is the default multiplexer, tmux is not retired.** Both are installed
  and configured on every machine; the `multiplexer` prompt only decides which
  sessionizer `Ctrl-f` launches, and `~/.config/herdr/config.toml` mirrors the
  tmux keymap so the choice costs no muscle memory. Switching a machine is an
  edit to `multiplexer` in `~/.config/chezmoi/chezmoi.toml` plus `chezmoi apply`.

## Usage

Fresh machine. `git` is the one prerequisite you must install yourself — you
need it to clone the repo that contains `bootstrap.sh`. The script installs the
rest (`curl`, `zsh`, mise, chezmoi, oh-my-zsh) via the detected package manager.

An SSH key authorised with GitHub must already exist, since the nvim external is
cloned over SSH (and this repo may be private). Agent forwarding works too.

```sh
sudo dnf install -y git          # or apt/pacman/apk/brew
git clone git@github.com:QuantumDancer/dotfiles.git ~/Code/PortableDevSetup
~/Code/PortableDevSetup/bootstrap.sh
```

`bootstrap.sh` prompts for your git email, whether to sign commits, and which
multiplexer `Ctrl-f` should drive (`herdr` or `tmux`; both get installed either
way). Extra arguments are forwarded to `chezmoi init`, which is how to drive it
unattended:

```sh
./bootstrap.sh --no-tty --promptString "Git email=you@example.com" \
               --promptBool "Sign git commits...=true" \
               --promptChoice "Default multiplexer (Ctrl-f sessionizer)=herdr"
```

Existing machine, preview before applying:

```sh
chezmoi init --source ~/Code/PortableDevSetup        # generates the config, no apply
chezmoi diff                                          # review every change
chezmoi apply -v                                      # apply when happy
```

A machine provisioned before a prompt existed keeps working — the templates fall
back to the default — but it is only asked for the new answer by re-running
`chezmoi init`, since that is what regenerates `~/.config/chezmoi/chezmoi.toml`.

After editing a template, render it without touching disk:

```sh
chezmoi execute-template < home/dot_zshrc.tmpl
```

## Roadmap

- **Phase 0** — capture & converge existing configs into chezmoi templates. ✅
- **Phase 1** — mise host baseline: install mise, migrate tools off brew/bob/nvm.
  ✅ *(applied & validated on macOS; Framework/VM pending)*
- **Phase 2** — VM bring-up from a clean box via `bootstrap.sh`.
- **Phase 3** — dev container base image (mise baked in) + DevPod templates.

### Known follow-ups

- Decide which Kubernetes/IaC tools move from brew/dnf into mise. Candidates
  currently living in `~/.zshrc.local` on some hosts: rust/cargo, bun,
  kubebuilder, kubescape.
- Retire the superseded old chezmoi source at `~/.local/share/chezmoi`.

Deliberately *not* doing: `gpg.ssh.allowedSignersFile`. It only enables local
verification (`git log --show-signature`, `git verify-commit`, `%G?`), which we
never use — GitHub/GitLab verify against the uploaded key, not that file.
