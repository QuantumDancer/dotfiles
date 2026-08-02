#!/usr/bin/env bash
# Bootstrap the portable dev environment on a fresh machine.
# Installs prerequisites, mise, chezmoi and oh-my-zsh, then applies the dotfiles.
# Idempotent: safe to re-run.
#
# Any extra arguments are forwarded to `chezmoi init`, which is how you drive it
# non-interactively, e.g. for a smoke test:
#   ./bootstrap.sh --no-tty --promptString "Git email=you@example.com" \
#                  --promptBool "Sign git commits...=true" \
#                  --promptChoice "Default multiplexer (Ctrl-f sessionizer)=herdr"
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# mise drops its binary here and generates tool shims here. Both must be on PATH
# before chezmoi (itself a mise-managed tool) can be invoked below.
MISE_BIN="$HOME/.local/bin"
MISE_SHIMS="$HOME/.local/share/mise/shims"

# git is not listed: you already needed it to clone the repo containing this
# script. zsh is required by the oh-my-zsh installer, curl by mise's.
PREREQS=(curl zsh)

pkg_install() {
  local sudo=""
  if [[ $EUID -ne 0 ]]; then
    command -v sudo >/dev/null || return 1
    sudo=sudo
  fi

  if command -v dnf >/dev/null; then $sudo dnf install -y "$@"
  elif command -v apt-get >/dev/null; then $sudo apt-get update -qq && $sudo apt-get install -y "$@"
  elif command -v pacman >/dev/null; then $sudo pacman -Sy --noconfirm "$@"
  elif command -v apk >/dev/null; then $sudo apk add "$@"
  elif command -v zypper >/dev/null; then $sudo zypper -n install "$@"
  elif command -v brew >/dev/null; then brew install "$@"
  else return 1
  fi
}

ensure_prereqs() {
  local missing=()
  local cmd
  for cmd in "${PREREQS[@]}"; do
    command -v "$cmd" >/dev/null || missing+=("$cmd")
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0

  echo "Installing missing prerequisites: ${missing[*]}"
  if ! pkg_install "${missing[@]}"; then
    echo "error: could not install ${missing[*]} automatically." >&2
    echo "Install them with your package manager, then re-run this script." >&2
    exit 1
  fi
}

install_mise() {
  command -v mise >/dev/null && return 0
  curl -fsSL https://mise.run | sh
}

install_chezmoi() {
  command -v chezmoi >/dev/null && return 0
  mise use -g chezmoi
}

install_omz() {
  [[ -d "$HOME/.oh-my-zsh" ]] && return 0
  # Keep our managed .zshrc; don't switch the login shell or start zsh here.
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

main() {
  ensure_prereqs
  install_mise
  export PATH="$MISE_BIN:$MISE_SHIMS:$PATH"
  install_chezmoi
  install_omz
  # Applies dotfiles and clones the externals (nvim config, tpm, zsh plugins).
  # The nvim external is an SSH remote, so a GitHub-authorised key must exist.
  chezmoi init --apply --source "$REPO_DIR" "$@"
  # Install everything declared in the now-applied ~/.config/mise/config.toml.
  mise install
  echo
  echo "Bootstrap complete. Restart your shell (or 'exec zsh')."
}

main "$@"
