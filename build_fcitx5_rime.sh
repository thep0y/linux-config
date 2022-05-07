#!/bin/bash
# @Author: thepoy
# @Date:   2022-05-07 11:57:09
# @Last Modified by:   thepoy
# @Last Modified time: 2022-05-07 12:45:12

# 卸载 fcitx4
sudo apt autoremove fcitx-bin

git_is_exists=0
command -v git >/dev/null 2>&1 || { git_is_exists=1; }
if [ $git_is_exists -ne 0 ]; then
    sudo apt install git
fi
git config --global url."https://ghproxy.com/https://github.com".insteadOf "https://github.com"

# 克隆必需的仓库
cd /tmp
git clone https://github.com/fcitx/xcb-imdkit.git
git clone https://github.com/fcitx/fcitx5.git
git clone https://github.com/fcitx/fcitx5-rime.git

# 安装必需的依赖
sudo apt install cmake build-essential extra-cmake-modules libdbus-1-dev libevent-dev gettext libfmt-dev libxcb-util0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev libxcb-xkb-dev libcairo2-dev libxkbfile-dev libxkbcommon-dev libxkbcommon-x11-dev libjson-c-dev libsdl-pango-dev libgdk-pixbuf2.0-dev libwayland-dev wayland-protocols libenchant-dev libsystemd-dev libegl1-mesa-dev librime-dev appstream clang uthash-dev libxcb-randr0-dev libxcb-xfixes0-dev

# 编绎安装仓库
cd /tmp/xcb-imdkit
mkdir build && cd $_ && cmake -DCMAKE_INSTALL_PREFIX=/usr .. && make -j8 && sudo make install
cd /tmp/fcitx5
mkdir build && cd $_ && cmake .. && make -j8 && sudo make install
cd /tmp/fcitx5-rime
mkdir build && cd $_ && cmake .. && make -j8 && sudo make install

# 设置环境变量
echo "export INPUT_METHOD=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx" >> ~/.xinputrc

# 添加自启
cp /usr/share/applications/org.fcitx.Fcitx5.desktop ~/.config/autostart