#!/bin/bash
# @Author: thepoy
# @Date:   2021-12-30 19:08:33
# @Last Modified by:   thepoy
# @Last Modified time: 2023-02-06 10:20:33

set -euo pipefail

install_cmd=''
remove_cmd=''
update_cmd=''
id=""

# 镜像站默认使用阿里云
mirrors_url=""
if [ $MIRRORS_URL ]; then
    mirrors_url=$MIRRORS_URL
else
    mirrors_url="mirrors.ustc.edu.cn"
fi

codename=""

source /etc/os-release
if [ "$ID" = "arch" ]; then
    id=$ID
    install_cmd="sudo pacman -S --noconfirm "
    remove_cmd="sudo pacman -R --noconfirm "

    archlinuxcn="$(tail -n 1 /etc/pacman.conf)"
    if [ "$archlinuxcn" != "Server = https://$mirrors_url/archlinuxcn/\$arch" ]; then
        echo "[archlinuxcn]
Server = https://$mirrors_url/archlinuxcn/\$arch" | sudo tee -a /etc/pacman.conf
        sudo pacman -Sy
        sudo pacman -S archlinuxcn-keyring
    fi

    update_cmd="sudo pacman -Syy"
    # 配置 pacman 源
    $update_cmd
    if [ ! -f '/usr/bin/yay' ]; then
        ${install_cmd}yay
    fi
elif [ "$ID" = "ubuntu" ]; then
    id=$ID
    install_cmd="sudo apt install -y "
    remove_cmd="sudo apt remove -y "
    update_cmd="sudo apt update"
    # 配置 ubuntu 源
    codename=$VERSION_CODENAME
    sudo sed -i "s/archive.ubuntu.com/$mirrors_url/g" /etc/apt/sources.list
    $update_cmd
elif [ "$ID" = "linuxmint" ]; then
    id="ubuntu"
    install_cmd="sudo apt install -y "
    remove_cmd="sudo apt remove -y "
    update_cmd="sudo apt update"
    # 配置 ubuntu 源
    sudo cp /etc/apt/sources.list.d/official-package-repositories.list /etc/apt/sources.list.d/official-package-repositories.list.bak
    sudo sed -i "s/archive.ubuntu.com/$mirrors_url/g" /etc/apt/sources.list.d/official-package-repositories.list
    codename=$UBUNTU_CODENAME
    $update_cmd
elif [ "$ID" = "debian" ]; then
    id=$ID
    install_cmd="sudo apt install -y "
    remove_cmd="sudo apt remove -y "
    update_cmd="sudo apt update"
    # 配置 debian 源
    codename=$VERSION_CODENAME
    $update_cmd
elif [ "$ID" = "Deepin" ]; then
    id=$ID
    install_cmd="sudo apt install -y "
    remove_cmd="sudo apt remove -y "
    update_cmd="sudo apt update"
    # 配置 debian 源
    if [ "$VERSION_CODENAME" != "apricot" ]; then
        echo "${VERSION_CODENAME} 为未知版本，deepin 可能已经更新了大版本，此脚本需要更新"
    fi
    codename="buster"
    $update_cmd
else
    echo '未知发行版'
    exit 1
fi

# 检测主目录英文，如果不是英文，则修改为英文
if [[ $(ls $HOME) =~ "桌面" ]]; then
    ${install_cmd}xdg-user-dirs
    LC_ALL=C xdg-user-dirs-update --force
    # 更改完如果还有中文目录，则需要删除这些中文目录
    rm -rf 下载 图片 桌面 视频 公共 文档 模板 音乐
fi

# 检测 git 是否存在，不存在则安装，存在则配置 git 代理
git_is_exists=0
command -v git >/dev/null 2>&1 || { git_is_exists=1; }
if [ $git_is_exists -ne 0 ]; then
    ${install_cmd}git
fi
git config --global url."https://ghproxy.com/https://github.com".insteadOf "https://github.com" 
# github.com.cnpmjs.org 的证书可能无法验证，更新证书
# sudo update-ca-certificates

# 检测 vim 是否存在，不存在则安装，存在则配置
# vim_is_exists=0
# command -v vim >/dev/null 2>&1 || { vim_is_exists=1; }
# if [ $vim_is_exists -ne 0 ]; then
#     ${install_cmd}vim
# fi
# if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
#     git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
# fi
# if [ ! -f "$HOME/.vimrc" ]; then
#     curl -o $HOME/.vimrc https://raw.fastgit.org/thep0y/vim/master/.vimrc
# fi

# 安装 fish
fish_is_exists=0
command -v fish >/dev/null 2>&1 || { fish_is_exists=1; }
if [ $fish_is_exists -ne 0 ]; then
    if [ "$ID" = "Deepin" ]; then
    fi
    ${install_cmd}fish
fi

# 安装 conda
conda_folder=$HOME/miniconda3
if [ ! -d $conda_folder ]; then
    curl -o /tmp/miniconda.sh https://mirrors.bfsu.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh
    zsh /tmp/miniconda.sh
    # 配置 conda
    echo 'channels:
  - defaults
show_channel_urls: true
default_channels:
  - https://mirrors.bfsu.edu.cn/anaconda/pkgs/main
  - https://mirrors.bfsu.edu.cn/anaconda/pkgs/r
  - https://mirrors.bfsu.edu.cn/anaconda/pkgs/msys2
custom_channels:
  conda-forge: https://mirrors.bfsu.edu.cn/anaconda/cloud
  msys2: https://mirrors.bfsu.edu.cn/anaconda/cloud
  bioconda: https://mirrors.bfsu.edu.cn/anaconda/cloud
  menpo: https://mirrors.bfsu.edu.cn/anaconda/cloud
  pytorch: https://mirrors.bfsu.edu.cn/anaconda/cloud
  pytorch-lts: https://mirrors.bfsu.edu.cn/anaconda/cloud
  simpleitk: https://mirrors.bfsu.edu.cn/anaconda/cloud' > $HOME/.condarc
fi

conda_cmd=$HOME/miniconda3/bin/conda

# 修改 pip 源
if [ ! -f "$HOME/.config/pip/pip.conf" ]; then
    $HOME/miniconda3/bin/pip config set global.index-url https://mirror.sjtu.edu.cn/pypi/web/simple
fi

# 创建 work 环境
if [[ ! $($conda_cmd env list) =~ 'work' ]]; then
    $conda_cmd create -n work python=3.10

    # 激活 work 环境，并安装常用包
    # zsh 安装的 conda，在 bash 会话里无法正常运行 activate，所以只创建，之后手动安装依赖
    # $conda_cmd activate work
    # pip install requests pymysql mongo
fi

# 下载并安装 go
if [ ! -d "/usr/local/go" ]; then
    curl -o /tmp/go.html https://golang.google.cn/dl/
    download_ele="$(grep -Eo "<a class=\"download downloadBox\" href=\"\/dl\/go.*\.linux-amd64\.tar\.gz" /tmp/go.html)"
    download_url="https://dl.google.com/go${download_ele:41}"
    curl -o /tmp/go.tar.gz $download_url
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz

    GOROOT=/usr/local/go
    GOPATH='$HOME/go'
    LOCAL_BIN='$HOME/.local/bin'
    NPM_BIN='$HOME/.npm/bin'

    if [ "$SHELL" = 'zsh' ]; then
        # 配置 go
        echo -e "export GOROOT=$GOROOT\nexport GOPATH=$GOPATH\nexport PATH=$LOCAL_BIN:$NPM_BIN:\$GOROOT/bin:\$GOPATH/bin:\$PATH" | sudo tee -a /etc/zsh/zshenv
    elif [ "$SHELL" = 'fish' ]; then
        echo -e "set -x GOROOT $GOROOT\nset -x GOPATH $GOPATH\nset -x PATH $LOCAL_BIN $NPM_BIN \$GOPATH/bin \$GOROOT/bin \$PATH\n" >> $HOME/.config/fish/config.fish
    fi

    $GOROOT/bin/go env -w GO111MODULE=on
    $GOROOT/bin/go env -w GOPROXY=https://goproxy.cn,direct
fi

# 安装 docker 、添加当前用户到 docker 组，并配置镜像仓库
if [ ! -f '/usr/bin/docker' ]; then
    if [ "$ID" = "debian" ] || [ "$ID" = "Deepin" ]; then
        ${install_cmd}apt-transport-https ca-certificates curl gnupg2 software-properties-common
        curl -fsSL https://repo.huaweicloud.com/docker-ce/linux/debian/gpg | sudo apt-key add -
        echo "deb [arch=amd64] https://mirrors.bfsu.edu.cn/docker-ce/linux/debian \
       $codename \
       stable" | sudo tee -a /etc/apt/sources.list.d/docker.list
        $update_cmd
        ${install_cmd}docker-ce
    elif [ "$ID" = "ubuntu" ]; then
        ${install_cmd}apt-transport-https ca-certificates curl gnupg2 software-properties-common
        curl -fsSL https://repo.huaweicloud.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://repo.huaweicloud.com/docker-ce/linux/ubuntu $codename stable"
        $update_cmd
        ${install_cmd}docker-ce
    elif [ "$ID" = "arch" ]; then
        echo 'arch不需额外配置'
        ${install_cmd}docker
    else
        echo "此系统${id}尚未配置"
        exit 1
    fi
    sudo usermod -aG docker $USER
    if [ ! -d "/etc/docker" ]; then
        sudo mkdir -p /etc/docker
    fi
    if [ ! -f '/etc/docker/daemon.json' ]; then
        echo '{
    "registry-mirrors": ["https://dockerproxy.com"]
}' | sudo tee -a /etc/docker/daemon.json
    fi
    sudo systemctl daemon-reload
    sudo systemctl restart docker
fi

# 安装浏览器，edge 和 firefox
if [ ! -f "/usr/bin/firefox" ]; then
    if [ "$ID" = "ubuntu" ] || [ "$ID" = "Deepin" ]; then
        # 对于没有默认安装 firefox 的发行版安装最新的 firefox-esr
        if [ ! -d "$HOME/Applications" ]; then
            mkdir -p $HOME/Applications
        fi
        curl -L -o /tmp/firefox.tar.bz2 "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=zh-CN"
        tar -xf /tmp/firefox.tar.bz2 -C $HOME/Applications
    elif [ "$ID" = "debian" ]; then
        # 只支持 debian 11 以上，我本人不会使用 11 以下的 debian
        ${install_cmd}firefox firefox-l10n-zh-cn
    fi
fi

if [ ! -f "/usr/bin/microsoft-edge-stable" ]; then
    if [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ] || [ "$ID" = "Deepin" ]; then
        # 用 python 定位最新版的 edge
        edge_html="'''$(curl https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/)'''"
        egde_latest_deb=$(python3 -c "import re;latest=$edge_html.split('\n')[-4];result=re.search(r'href=\"(.*?)\"', latest); print(result.group(1))")
        edge_download_url="https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/$egde_latest_deb"
        curl -o /tmp/edge.deb $edge_download_url
        sudo sudo apt-get --fix-broken install /tmp/edge.deb
    elif [ "$ID" = "arch" ]; then
        yay -S microsoft-edge-stable-bin
    else
        echo 'unkown platform'
        exit 1
    fi
fi

# 配置 aria2、trojan和坚果云
if [ ! -f "/usr/bin/aria2c" ]; then
    ${install_cmd}aria2
fi
if [ ! -d "$HOME/.config/autostart" ]; then
    mkdir "$HOME/.config/autostart"
fi
if [ ! -d "$HOME/Applications" ]; then
    mkdir -p "$HOME/Applications/aria2"
    ln -s "$HOME/Applications/aria2" $HOME/.aria2
    git clone https://github.com/P3TERX/aria2.conf.git $HOME/Applications/aria2
    sed -i "s#/root/#$HOME/#g" $HOME/Applications/aria2/aria2.conf
    sed -i "s#/root/#$HOME/#g" $HOME/Applications/aria2/script.conf
    echo '#!/bin/sh

nohup aria2c --conf-path=$HOME/.aria2/aria2.conf > /dev/null 2>&1 &' > $HOME/Applications/aria2/aria2.sh
    chmod +x $HOME/Applications/aria2/aria2.sh

    if [ ! -f "$HOME/.aria2/aria2.session" ]; then
        touch "$HOME/.aria2/aria2.session"
    fi

    echo "[Desktop Entry]
Type=Application
Exec=sh -c \"sleep 5 && $HOME/Applications/aria2/aria2.sh\"
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name[zh_CN]=aria2
Comment[zh_CN]=No description
X-GNOME-Autostart-Delay=15" >  $HOME/.config/autostart/aria2.desktop
fi
if [ ! -d "$HOME/Applications/trojan" ]; then
    curl -L -o /tmp/trojan.tar.xz https://ghproxy.com/https://github.com/trojan-gfw/trojan/releases/download/v1.16.0/trojan-1.16.0-linux-amd64.tar.xz
    tar -xf /tmp/trojan.tar.xz -C "$HOME/Applications"
    echo '#!/bin/sh

TROJAN_PATH=$HOME/Applications/trojan
nohup $TROJAN_PATH/trojan -c $TROJAN_PATH/config.json > $TROJAN_PATH/trojan.log 2>&1 &
' > $HOME/Applications/trojan/trojan.sh
    chmod +x $HOME/Applications/trojan/trojan.sh
    echo '别忘了配置 trojan 的地址、端口和密码！'
    echo "[Desktop Entry]
Type=Application
Exec=sh -c \"sleep 3 && $HOME/Applications/trojan/trojan.sh\"
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name[zh_CN]=trojan
Comment[zh_CN]=No description
X-GNOME-Autostart-Delay=5" >  $HOME/.config/autostart/trojan.desktop
fi
if [ ! -f '/usr/bin/nutstore' ] && [ ! -d "$HOME/Applications/nutstore" ]; then
    if [ "$ID" = "arch" ]; then
        yay -S nutstore-experimental
    else
        nutstore_dir=$HOME/Applications/nutstore
        curl -L -o /tmp/nutstore.tar.gz https://www.jianguoyun.com/static/exe/installer/nutstore_linux_dist_x64.tar.gz
        mkdir -p $nutstore_dir && tar zxf /tmp/nutstore.tar.gz -C $nutstore_dir
        bash $nutstore_dir/bin/install_core.sh

        if [ ! -d "$HOME/.nutstore" ]; then
            mkdir $HOME/.nutstore
        fi

        ln -s $nutstore_dir $HOME/.nutstore/dist
    fi
fi

# 安装 node lts 18
if [ "$ID" == "debian" ] || [ "$ID" == "ubuntu" ] || [ "$ID" == "Deepin" ]; then
    keyring='/usr/share/keyrings'
    node_key_url="https://deb.nodesource.com/gpgkey/nodesource.gpg.key"
    local_node_key="$keyring/nodesource.gpg"
    if [ -x /usr/bin/curl ]; then
        curl -s $node_key_url | gpg --dearmor | tee $local_node_key >/dev/null
    else
        wget -q -O - $node_key_url | gpg --dearmor | tee $local_node_key >/dev/null
    fi
    echo "deb [signed-by=$local_node_key] https://deb.nodesource.com/node_18.x ${codename} main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list
    echo "deb-src [signed-by=$local_node_key] https://deb.nodesource.com/node_18.x ${codename} main" | sudo tee -a /etc/apt/sources.list.d/nodesource.list
    ${install_cmd}nodejs
elif [ "$ID" == "arch" ]; then
    ${install_cmd}nodejs-lts-hydrogen npm
fi
npm config set registry "https://registry.npmmirror.com"
npm config set cache "$HOME/.npm/.cache"
npm config set prefix "$HOME/.npm"
npm i -g pnpm

# 安装 bun
if [ ! -d "$HOME/.bun" ]; then
    curl -fsSL https://gitee.com/thepoy/linux-configuration-shell/raw/master/bun.sh | bash
fi

# 下载、安装、破解 datagrip
if [ ! -f '/usr/bin/datagrip' ] && [ ! -d "$HOME/Applications/datagrip" ]; then
    if [ "$ID" = "arch" ]; then
        yay -S datagrip
    else
        curl -o /tmp/datagrip 'https://data.services.jetbrains.com/products/releases?code=DG&latest=true&type=release&build=&_=1641367114698'
        echo "$(grep -Eo 'https://.*?\.tar\.gz","size":' /tmp/datagrip)" > /tmp/datagrip
        latest_url="$(grep -Eo 'https://.*?\.tar\.gz' /tmp/datagrip)"
        curl -o /tmp/datagrip.tar.gz $latest_url
        tar -zxf /tmp/datagrip.tar.gz -C $HOME/Applications
        mv $HOME/Applications/DataGrip* $HOME/Applications/datagrip
    fi
fi

# 安装 sublime text，并添加插件（如果无法下载插件则创建插件配置文件）
# 因为破解脚本跟随开发版本更新，所以无法一键破解
if [ ! -f '/usr/bin/subl' ]; then
    if [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ] || [ "$ID" = "Deepin" ]; then
        wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
        sudo apt-get install apt-transport-https
        echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
        sudo apt-get update
        sudo apt-get install sublime-text sublime-merge
    elif [ "$ID" = "arch" ]; then
        yay -S sublime-text-4 sublime-merge
    else
        echo 'unkown platform'
        exit 1
    fi

    work_dir=${pwd}

    ln -s $work_dir/sublime/User $HOME/.config/sublime-text/Packages/User
fi

# 安装 vscode。vscode 的 go 提示比 st 丰富，能帮助写出更完美的代码风格
if [ ! -f '/usr/bin/code' ]; then
    if [ "$ID" = "arch" ]; then
        ${install_cmd}code
    elif [ "$ID" = "Deepin" ] || [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ]; then
        curl -L 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64' -o /tmp/code.deb
        sudo apt-get --fix-broken install /tmp/code.deb
    else
        echo "此发行版 [$ID] 待完善"
    fi
fi

# 安装 fcitx5-rime，并下载 98 五笔码表和皮肤
if [ ! -f "/usr/bin/fcitx5" ]; then
    if [ "$ID" = "debian" ] || [ "$ID" = "ubuntu" ]; then
        ${install_cmd}fcitx5-rime fcitx5-configtool fcitx5-gtk fcitx5-qt
    elif [ "$ID" = "arch" ]; then
        ${install_cmd}fcitx5-rime fcitx5-configtool fcitx5-gtk fcitx5-qt
    else
        echo 'unkown platform'
        exit 1
    fi
    cp /usr/share/applications/org.fcitx.Fcitx5.desktop $HOME/.config/autostart
    echo 'GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
    ' | sudo tee -a /etc/environment
fi

if [ ! -d "$HOME/.config/environment.d" ]; then
    mkdir -p $HOME/.config/environment.d
fi

# 安装 libreoffice 套件，指定 gtk3 依赖
if [ ! -f '/usr/bin/libreoffice' ]; then
    if [ "$ID" = "arch" ]; then
        ${install_cmd}libreoffice-still-zh-cn
    else
        echo "此发行版 [$ID] 待完善"
    fi
fi

# 安装 mpv
if [ ! -f '/usr/bin/mpv' ]; then
    if [ "$ID" = "arch" ]; then
        ${install_cmd}mpv
    else
        echo "此发行版 [$ID] 待完善"
    fi
fi
if [ ! -d "$HOME/.config/mpv" ]; then
    mkdir $HOME/.config/mpv
fi
curl -o $HOME/.config/mpv/input.conf https://raw.fastgit.org/thep0y/mpv-config/master/input.conf
curl -o $HOME/.config/mpv/mpv.conf https://raw.fastgit.org/thep0y/mpv-config/master/mpv.conf

# 安装 typora
if [ ! -f '/usr/bin/typora' ] && [ "$ID" = "arch" ]; then
    yay -S typora
else
    echo "此发行版 [$ID] 待完善"
fi
if [ ! -d "$HOME/.config/Typora" ]; then
    mkdir -p $HOME/.config/Typora/themes
fi
curl -o $HOME/.config/Typora/themes/drake-ayu.css https://gitee.com/thepoy/linux-configuration-shell/raw/master/typora/drake-ayu.css
curl -o $HOME/.config/Typora/themes/drake-vue.css https://gitee.com/thepoy/linux-configuration-shell/raw/master/typora/drake-vue.css
curl -o $HOME/.config/Typora/themes/base.user.css https://gitee.com/thepoy/linux-configuration-shell/raw/master/typora/base.user.css

chsh -s /usr/bin/fish
# 初始化 conda
$conda_cmd init fish

echo -e '==> 脚本运行结束'
echo -e '  sublime text 需要先安装 Package Control，\n再安装所需插件后才能使用 sublime 目录中除 \nUser 目录以外的插件的配置，如 FileHeader。'