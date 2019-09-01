#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function cargoinstall() {
    cargo install $1
}

function snapinstall() {
    if ! snap list | grep -q $1; then
        snap install $1 --classic
    fi
}

function aptinstall() {
    # Second parameter is optional for custom repos
    if [ $# -gt 1 ]
    then
        sudo add-apt-repository $2
    fi

    sudo apt install $1 -y
}

function link() {
    if [ -f "$HOME/$1" ]; then
        ln -sf $SCRIPT_DIR/$1 $HOME/$1
        echo "symlinked: $SCRIPT_DIR/$1 -> $HOME/$1"
    else
        echo "$HOME/$1 doesn't exists!"
    fi

}

function linkdir() {
    for file in $1/*
    do
        if [ -d "$file" ]
        then
            linkdir $file
        else
            link $file
        fi
    done
}

# Install dependencies
echo " === Installing dependencies === "
sudo apt update
aptinstall cmake
aptinstall curl
aptinstall golang-go
aptinstall zsh
aptinstall alacritty ppa:mmstick76/alacritty
# Install rust
curl https://sh.rustup.rs -sSf | sh -s -- -y
cargoinstall ripgrep
cargoinstall exa
cargoinstall bat

snapinstall code

# Setup symbolic links
echo " === Symlinking configurations === "
link .bashrc
link .zshrc
cp .tmux.conf $HOME/.tmux.conf
cp .tmux.conf.local $HOME/.tmux.conf.local
link .tmux.conf
link .tmux.conf.local
linkdir .config

sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)" "" --unattended

source $HOME/.bashrc
source $HOME/.zshrc

echo "Done!"