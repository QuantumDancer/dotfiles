#!/usr/bin/env bash
# Bootstrap the portable dev environment on a fresh machine.
# Installs mise, chezmoi and oh-my-zsh, then applies the dotfiles from this repo.
# Idempotent: safe to re-run.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_mise() {
  command -v mise >/dev/null && return
  curl -fsSL https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
}

install_chezmoi() {
  command -v chezmoi >/dev/null && return
  mise use -g chezmoi
}

install_omz() {
  [[ -d "$HOME/.oh-my-zsh" ]] && return
  # Keep our managed .zshrc; don't switch the login shell or start zsh here.
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

main() {
  install_mise
  install_chezmoi
  install_omz
  # Applies dotfiles and clones the externals (nvim config, tpm, zsh plugins).
  chezmoi init --apply --source "$REPO_DIR"
  # Install everything declared in ~/.config/mise/config.toml.
  mise install
  echo
  echo "Bootstrap complete. Restart your shell (or 'exec zsh')."
}

main "$@"
