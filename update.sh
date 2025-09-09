#!/bin/zsh


# Move current .zshrc to live.
cp --backup=numbered "zshrc" "$HOME/.zshrc"

rm -f $HOME/.zshrc.\~??\~  # Remove older backups, >10
