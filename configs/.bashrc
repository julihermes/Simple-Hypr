#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='lsd -A'
alias ll='lsd -lA'
alias lt='lsd --tree'
alias nv='nvim'
alias lg='lazygit'
alias sp='sudo pacman'
alias ..='cd ../'
alias grep='grep --color=auto'

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

eval "$(starship init bash)"
