if status --is-interactive
and not set -q TMUX
    tmux new -s default
end
clear

set -x PATH $PATH $HOME/go/bin/
set -x PATH $PATH $HOME/.cargo/bin

alias ls='exa -lh'

eval (starship init fish)
