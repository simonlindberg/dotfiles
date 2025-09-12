#!/bin/zsh


# Move current files to live.
cp --backup=numbered "zshrc" "$HOME/.zshrc"
cp --backup=numbered "nanorc" "$HOME/.nanorc"

# Remove older backups, >10
rm -f $HOME/.zshrc.~??~ || true
rm -f $HOME/.nanorc.~??~ || true
