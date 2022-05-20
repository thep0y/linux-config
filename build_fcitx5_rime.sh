#!/bin/bash
# @Author: thepoy
# @Date:   2022-05-07 11:57:09
# @Last Modified by:   thepoy
# @Last Modified time: 2022-05-20 12:10:05

# 卸载 fcitx4
echo '卸载 fcitx 程序及相关依赖 ...'
sudo apt autoremove 'fcitx*'
echo 'fcitx 程序及相关依赖已卸载'

git_is_exists=0
command -v git >/dev/null 2>&1 || { git_is_exists=1; }
if [ $git_is_exists -ne 0 ]; then
    echo '安装 git ...'
    sudo apt install -y git
    echo 'git 安装完成'
fi

echo '设置 github 代理 ...'
git config --global url."https://ghproxy.com/https://github.com".insteadOf "https://github.com"
echo 'github 已设置代理'

# 克隆必需的仓库
cd /tmp
echo '克隆 fcitx5-rime 相关依赖仓库 ...'
git clone https://github.com/fcitx/xcb-imdkit.git
git clone https://github.com/fcitx/fcitx5.git
git clone https://github.com/fcitx/fcitx5-rime.git
echo 'fcitx5-rime 相关依赖仓库已克隆到 /tmp'

# 安装必需的依赖
echo '安装 fcitx5 依赖 ...'
sudo apt install -y cmake build-essential extra-cmake-modules libdbus-1-dev libevent-dev gettext libfmt-dev libxcb-util0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-keysyms1-dev libxcb-xinerama0-dev libxcb-xkb-dev libcairo2-dev libxkbfile-dev libxkbcommon-dev libxkbcommon-x11-dev libjson-c-dev libsdl-pango-dev libgdk-pixbuf2.0-dev libwayland-dev wayland-protocols libenchant-dev libsystemd-dev libegl1-mesa-dev librime-dev appstream clang uthash-dev libxcb-randr0-dev libxcb-xfixes0-dev
echo 'fcitx5 依赖安装完成'

# 编绎安装仓库
echo '编绎 xcb-imdkit'
cd /tmp/xcb-imdkit
mkdir build && cd $_ && cmake -DCMAKE_INSTALL_PREFIX=/usr .. && make -j8 && sudo make install
echo 'xcb-imdkit 已编绎并安装'
echo '编绎 fcitx5'
cd /tmp/fcitx5
mkdir build && cd $_ && cmake .. && make -j8 && sudo make install
echo 'fcitx5 已编绎并安装'
echo '编绎 fcitx5-rime'
cd /tmp/fcitx5-rime
mkdir build && cd $_ && cmake .. && make -j8 && sudo make install
echo 'fcitx5-rime 已编绎并安装'

# 设置环境变量
echo '设置输入法环境变量为 fcitx5'
echo "export INPUT_METHOD=fcitx
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx" >> ~/.xinputrc
echo '输入法环境变量已设置'

# 添加自启
echo 'fcitx5 添加自启'
echo "[Desktop Entry]
Name=Fcitx 5
GenericName[zh_CN]=输入法
GenericName=Input Method
Comment[zh_CN]=启动输入法
Comment=Start Input Method
Exec=/usr/bin/fcitx5
Icon=org.fcitx.Fcitx5
Terminal=false
Type=Application
Categories=System;Utility;
StartupNotify=false
X-GNOME-AutoRestart=false
X-GNOME-Autostart-Notify=false
X-KDE-autostart-after=panel
X-KDE-StartupNotify=false
X-Deepin-CreatedBy=com.deepin.SessionManager
X-Deepin-AppID=org.fcitx.Fcitx5
Hidden=false
" > $HOME/.config/autostart/org.fcitx.Fcitx5.desktop
echo 'fcitx5 已设置开机或登录启动'

echo '安装 fcitx5 图形配置软件'
sudo apt install fcitx5-config-qt
echo 'fcitx5 图形配置软件已安装'

echo 'fcitx5-rime 安装完成，注销或重启即可使用'