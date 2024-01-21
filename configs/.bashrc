#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='lsd -A'
alias ll='lsd -lA'
alias lt='lsd --tree'
alias nv='nvim'
alias vi='nvim'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

eval "$(starship init bash)"
