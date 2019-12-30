#!/bin/bash
FONTS=0

while getopts ":f" opt; do
  case $opt in
    f)
      FONTS=1
      ;;
  esac
done

echo $FONTS;

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

function cargoinstall() {
    echo "-- Installing $1"
    cargo install $1
}

function snapinstall() {
    echo "-- Installing $1"
    snap install $1 --classic
}

function aptinstall() {
    # Second parameter is optional for custom repos
    if [ $# -gt 1 ]; then
        add-apt-repository $2 -y
    fi

    echo "-- Installing $1"
    apt install $1 -y
}

function link() {
    if ! [ -f "$HOME/$1" ]; then
        createmissingfile $HOME/$1
    fi
    
    ln -sf $SCRIPT_DIR/$1 $HOME/$1
    echo "-- symlinked: $SCRIPT_DIR/$1 -> $HOME/$1"
}

function linkdir() {
    for file in $1/*
    do
        if [ -d "$file" ]; then
            linkdir $file
        else
            link $file
        fi
    done
}

function createmissingfile() {
    if ! [ "ls $1" &>/dev/null ]; then
        touch $1
    fi
}

function exists_command() {
    command -v $1 &>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "-- $1 already installed, skipping.."
        true
    else
        false
    fi
}

function exists_dpkg() {
    dpkg -s $1 2>/dev/null | grep -q ^"Status: install ok installed"$
    if [ $? -eq 0 ]; then
        echo "-- $1 already installed, skipping.."
        true
    else
        false
    fi
}

# Install dependencies
echo "=== Installing dependencies === "
[ -z "$(find -H /var/lib/apt/lists -maxdepth 0 -mtime -7)" ] && apt update
exists_dpkg git         || aptinstall git
exists_dpkg cmake       || aptinstall cmake
exists_dpkg curl        || aptinstall curl
exists_dpkg golang-go   || aptinstall golang-go
exists_dpkg fish        || aptinstall fish ppa:fish-shell/release-3
exists_dpkg alacritty   || aptinstall alacritty ppa:mmstick76/alacritty
exists_dpkg tmux        || aptinstall tmux
exists_dpkg libssl-dev  || aptinstall libssl-dev

# Install fonts
if [ $FONTS -eq 1 ]; then
    echo "-- Installing fonts"

    pushd .. > /dev/null
    git clone https://github.com/powerline/fonts.git --depth=1
    pushd fonts > /dev/null
    ./install.sh
    popd > /dev/null
    rm -rf fonts
    popd > /dev/null
fi

# Install rust
if ! exists_command rustup; then
    curl https://sh.rustup.rs -sSf | sh -s -- -y
    source $HOME/.cargo/env
fi

exists_command exa      || cargoinstall exa
exists_command bat      || cargoinstall bat
exists_command starship || cargoinstall starship

exists_command rg   || snapinstall ripgrep
exists_command code || snapinstall code

# Setup symbolic links
echo "=== Symlinking configurations === "
link .tmux.conf
link .tmux.conf.local
link .config/starship.toml
link .config/fish/config.fish
linkdir .config/alacritty
linkdir .config/Code

echo "Done, please restart your terminal!"