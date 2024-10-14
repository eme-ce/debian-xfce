#!/bin/bash

# debug mode on
set -x

# create default directories
mkdir -p ~/.vim ~/.vim/autoload ~/.vim/backup ~/.vim/colors ~/.vim/plugged

# create config file if not exists
if [[ ! -f ~/.vimrc ]]; then
	touch ~/.vimrc
fi

# write config

if awk '/set nocompatible/ {exit 1} END {exit 0}' ~/.vimrc; then
	cat << EOF > ~/.vimrc
set nocompatible
filetype on
filetype plugin on
filetype indent on
syntax on
set number
set cursorline
set shiftwidth=4
set tabstop=4
set expandtab
set nobackup
set scrolloff=10
set nowrap
set incsearch
set ignorecase
set smartcase
set showcmd
set showmode
set showmatch
set hlsearch
set history=1000
set wildmenu
set wildmode=list:longest
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx
EOF
fi

# download plug.vim if not exists
if [[ ! -f ~/.vim/autoload/plug.vim ]]; then
	plugin_url=https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	curl -fLo ~/.vim/autoload/plug.vim --create-dirs "$plugin_url"
fi

# add plugin section in .vimrc
if awk '/call plug/ {exit 1} END {exit 0}' ~/.vimrc; then
    cat << EOF >> ~/.vimrc
call plug#begin('~/.vim/plugged')
call plug#end()
EOF
fi


