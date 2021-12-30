#!/bin/bash
# @Author: thepoy
# @Date:   2021-12-30 19:08:33
# @Last Modified by:   thepoy
# @Last Modified time: 2021-12-30 21:03:45

set -eux

install_cmd=''

# 镜像站默认使用阿里云
mirrors_url=""
if [ $MIRRORS_URL ]; then
    mirrors_url=$MIRRORS_URL
else
    mirrors_url="mirrors.aliyun.com"
fi
codename=""

source /etc/os-release
if [ "$ID" = "arch" ]; then
    install_cmd="sudo pacman -S --noconfirm "
    # 配置 pacman 源
    sudo pacman -Syy
elif [ "$ID" = "ubuntu" ]; then
    install_cmd="sudo apt install -y "
    # 配置 ubuntu 源
    codename=$VERSION_CODENAME
    sudo sed -i "s/archive.ubuntu.com/$mirrors_url/g" /etc/apt/sources.list
    sudo apt update
elif [ "$ID" = "linuxmint" ]; then
    install_cmd="sudo apt install -y "
    # 配置 ubuntu 源
    sudo cp /etc/apt/sources.list.d/official-package-repositories.list /etc/apt/sources.list.d/official-package-repositories.list.bak
    sudo sed -i "s/archive.ubuntu.com/$mirrors_url/g" /etc/apt/sources.list.d/official-package-repositories.list
    codename=$UBUNTU_CODENAME
    sudo apt update
elif [ "$ID" = "debian" ]; then
    install_cmd="sudo apt install -y "
    # 配置 debian 源
    codename=$VERSION_CODENAME
    sudo apt update
else
    echo '未知发行版'
    exit 1
fi

# 检测主目录英文，如果不是英文，则修改为英文
if [[ $(ls $HOME) =~ "桌面" ]]; then
    is_exists=0
    command -v xdg-user-dirs-gtk-update >/dev/null 2>&1 || { is_exists=1; }
    if [ $is_exists -ne 0 ]; then
        ${install_cmd}xdg-user-dirs-gtk
    fi

    export LANG=en_US
    xdg-user-dirs-gtk-update --force
    epxort LANG=zh_CN
fi


# 检测 git 是否存在，不存在则安装，存在则配置 git 代理

# 配置 aria2、trojan和坚果云

# 安装 zsh

# 安装 oh-my-zsh

# 配置 oh-my-zsh

# 安装 conda

# 配置 conda

# 修改 pip 源

# 创建 work 环境

# 激活 work 环境，并安装常用包

# 下载并安装 go

# 配置 go

# 设置 goproxy

# 安装 docker 、添加当前用户到 docker 组，并配置镜像仓库

# 安装 sublime text，并添加插件（如果无法下载插件则创建插件配置文件）

# 安装 vscode

# 安装 fcitx5-rime，并下载 98 五笔码表和皮肤

# 安装浏览器，edge 和 firefox

# 安装 libreoffice 套件，指定 gtk3 依赖

# 安装 mpv