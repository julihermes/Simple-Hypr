# Created by Zap installer
[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh" ] && source "${XDG_DATA_HOME:-$HOME/.local/share}/zap/zap.zsh"

plug "zap-zsh/supercharge"
plug "wintermi/zsh-starship"
plug "zap-zsh/completions"
plug "zsh-users/zsh-syntax-highlighting"
plug "zsh-users/zsh-autosuggestions"
plug "zsh-users/zsh-history-substring-search"

plug "$HOME/.config/zsh/configs.zsh"
plug "$HOME/.config/zsh/aliases.zsh"

# Load and initialise completion system
autoload -Uz compinit
compinit

