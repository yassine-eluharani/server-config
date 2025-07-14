#!/bin/bash

set -e

# Update system
apt update && apt upgrade -y

# Install ZSH, git, curl, and Neovim
apt install -y zsh git curl neovim wget fonts-powerline

# Change default shell to zsh (only if not already)
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s $(which zsh)
  echo "Shell changed to zsh (you need to logout & back in for it to apply)"
fi

# Install Oh My Zsh (non-interactive)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "Installing Oh My Zsh..."
  export RUNZSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install Powerlevel10k theme
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  echo "Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
fi

# Set theme in .zshrc
sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# Enable some plugins
sed -i 's/plugins=(git)/plugins=(git docker docker-compose)/' ~/.zshrc

# Add color LS aliases if not present
grep -qxF 'alias ll="ls -alF --color=auto"' ~/.zshrc || echo 'alias ll="ls -alF --color=auto"' >> ~/.zshrc
grep -qxF 'alias l="ls -CF --color=auto"' ~/.zshrc || echo 'alias l="ls -CF --color=auto"' >> ~/.zshrc

# Setup Neovim config
mkdir -p ~/.config/nvim
cat <<EOF > ~/.config/nvim/init.vim
set number
syntax on
set mouse=a
EOF

echo "✅ ZSH, Neovim, and theme setup complete. Reboot or logout to see changes."
