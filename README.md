# PortableDevSetup

A portable, cross-machine development environment that works the same on macOS
(arm64), Fedora (x86_64), and a remote Linux VM.

## Architecture

A **hybrid** of two decoupled layers:

- **Host layer** — shell, editor and terminal tooling run natively on every
  machine: Neovim, tmux, zsh, starship, fzf, ripgrep, fd, bat. Managed by
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
  .chezmoi.toml.tmpl         # init-time prompts (email, commit signing)
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
    tmux-sessionizer/paths   # created once with ~/Code; edit per host, never clobbered
  dot_local/scripts/         # tmux-sessionizer
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
- **This repo is the chezmoi source dir.**

## Usage

Fresh machine:

```sh
git clone <this-repo> ~/Code/PortableDevSetup
~/Code/PortableDevSetup/bootstrap.sh
```

Existing machine, preview before applying:

```sh
chezmoi init --source ~/Code/PortableDevSetup        # generates the config, no apply
chezmoi diff                                          # review every change
chezmoi apply -v                                      # apply when happy
```

After editing a template, render it without touching disk:

```sh
chezmoi execute-template < home/dot_zshrc.tmpl
```

## Roadmap

- **Phase 0** — capture & converge existing configs into chezmoi templates. ✅
- **Phase 1** — mise host baseline: install mise, migrate tools off brew/bob/nvm.
- **Phase 2** — VM bring-up from a clean box via `bootstrap.sh`.
- **Phase 3** — dev container base image (mise baked in) + DevPod templates.

### Known follow-ups

- Migrate git commit signing from GPG to SSH signing (`gpg.format = ssh`) so it
  reuses the forwarded ssh-agent and works inside containers.
- Decide which Kubernetes/IaC tools move from brew/dnf into mise.
