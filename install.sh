#!/bin/bash
# @Author: thepoy
# @Date:   2021-12-30 19:08:33
# @Last Modified by:   thepoy
# @Last Modified time: 2022-01-01 12:40:30

# set -eux

install_cmd=''
remove_cmd=''
update_cmd=''
id=""

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
    id=$ID
    install_cmd="sudo pacman -S --noconfirm "
    remove_cmd="sudo pacman -R --noconfirm "
    update_cmd="sudo pacman -Syy"
    # 配置 pacman 源
    $update_cmd
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
else
    echo '未知发行版'
    exit 1
fi

# 检测主目录英文，如果不是英文，则修改为英文
if [[ $(ls $HOME) =~ "桌面" ]]; then
    ${install_cmd}xdg-user-dirs
    LC_ALL=C xdg-user-dirs-update --force
    # 更改完如果还有中文目录，则需要删除这些中文目录
    # rm -rf 
fi

# 检测 git 是否存在，不存在则安装，存在则配置 git 代理
git_is_exists=0
command -v git >/dev/null 2>&1 || { git_is_exists=1; }
if [ $git_is_exists -ne 0 ]; then
    ${install_cmd}git
fi
git config --global url."https://github.com.cnpmjs.org".insteadOf "https://github.com"
# github.com.cnpmjs.org 的证书可能无法验证，更新证书
sudo update-ca-certificates

# 检测 vim 是否存在，不存在则安装，存在则配置
vim_is_exists=0
command -v vim >/dev/null 2>&1 || { vim_is_exists=1; }
if [ $vim_is_exists -ne 0 ]; then
    ${install_cmd}vim
    # TODO: 下面两行的目录和文件应该判断是否存在
    git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
    curl -o $HOME/.vimrc https://raw.fastgit.org/thep0y/vim/master/.vimrc
fi

# 安装 zsh
zsh_is_exists=0
command -v zsh >/dev/null 2>&1 || { zsh_is_exists=1; }
if [ $zsh_is_exists -ne 0 ]; then
    ${install_cmd}zsh
fi

# 解释器为 bash，无法获取 ZSH_CUSTOM 变量，需要折中
zsh_custom="$HOME/.oh-my-zsh/custom"
if [ ! -d $zsh_custom ]; then
    sh -c "$(curl -fsSL https://raw.fastgit.org/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git $zsh_custom/plugins/zsh-autosuggestions
fi
if [ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $zsh_custom/plugins/zsh-syntax-highlighting
fi
# 看看第 73 行是否是 plugins=(git)
zsh_plugins="$(sed -n '73p' $HOME/.zshrc)"
if [ $zsh_plugins = 'plugins=(git)' ]; then
    echo 'zsh没添加插件'
    sed -i '73c plugins=(\n  git\n  zsh-autosuggestions\n  zsh-syntax-highlighting\n)' $HOME/.zshrc
fi

# 安装 conda
conda_folder=$HOME/miniconda3
if [ ! -d $conda_folder ]; then
    curl -o /tmp/minicode.sh https://mirrors.bfsu.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh
    zsh /tmp/minicode.sh
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


# 修改 pip 源
if [ ! -f "$HOME/.config/pip/pip.conf" ]; then
    $HOME/miniconda3/bin/pip config set global.index-url https://mirrors.aliyun.com/pypi/simple/
fi

conda_cmd=$HOME/miniconda3/bin/conda
# 创建 work 环境
if [[ $($conda_cmd env list) =~ 'work' ]]; then
    $conda_cmd create -n work python=3.9

    # 激活 work 环境，并安装常用包
    $conda_cmd activate work
    pip install requests pymysql mongo
fi

# 下载并安装 go
if [ ! -d "/usr/local/go" ]; then
    curl -o /tmp/go.html https://golang.google.cn/dl/
    download_ele="$(grep -Eo "<a class=\"download downloadBox\" href=\"\/dl\/go.*\.linux-amd64\.tar\.gz" /tmp/go.html)"
    download_url="https://dl.google.com/go${download_ele:41}"
    curl -o /tmp/go.tar.gz $download_url
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    # 配置 go
    echo 'GOROOT=/usr/local/go
GOPATH=$HOME/go
PATH=$GOROOT/bin:$GOPATH/bin:$PATH' >> .zshenv
    # 设置 goproxy
    source .zshenv
    go env -w GO111MODULE=on
    go env -w GOPROXY=https://goproxy.cn,direct
fi

# 安装 docker 、添加当前用户到 docker 组，并配置镜像仓库
# ${remove_cmd}docker docker-engine docker.io
if [ "$id" = "debian" ]; then
    ${install_cmd}apt-transport-https ca-certificates curl gnupg2 software-properties-common
    curl -fsSL https://repo.huaweicloud.com/docker-ce/linux/debian/gpg | sudo apt-key add -
    echo "deb [arch=amd64] https://mirrors.bfsu.edu.cn/docker-ce/linux/debian \
   $codename \
   stable" | sudo tee -a /etc/apt/sources.list.d/docker.list
    $update_cmd
    ${install_cmd}docker-ce
elif [ "$id" = "ubuntu" ]; then
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
    "registry-mirrors": ["https://mci3f39b.mirror.aliyuncs.com"]
}' | sudo tee -a /etc/docker/daemon.json
fi
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo usermod -aG docker $USER

# 安装浏览器，edge 和 firefox
if [ ! -f "/usr/bin/firefox" ]; then
    if [ "$id" = "ubuntu" ]; then
        # 对于没有默认安装 firefox 的发行版安装最新的 firefox-esr
        if [ ! -d "$HOME/Applications" ]; then
            mkdir -p $HOME/Applications
        fi
        curl -L -o /tmp/firefox-esr.tar.bz2 "https://download.mozilla.org/?product=firefox-esr-latest&os=linux&lang=zh-CN"
        tar -xf /tmp/firefox-esr.tar.bz2 -C $HOME/Applicationswhre
    elif [ "$id" = "debian" ]; then
        # 只支持 debian 11 以上，我本人不会使用 11 以下的 debian，包括 deepin
        ${install_cmd}firefox-esr firefox-esr-l10n-zh-cn
    fi
fi

if [ ! -f "/usr/bin/microsoft-edge-stable" ]; then
    if [ "$id" = "debian" ] || [ "$id" = "ubuntu" ]; then
        # 用 python 定位最新版的 edge
        edge_html="'''$(curl https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/)'''"
        egde_latest_deb=$(python3 -c "import re;latest=$edge_html.split('\n')[-4];result=re.search(r'href=\"(.*?)\"', latest); print(result.group(1))")
        edge_download_url="https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/$egde_latest_deb"
        curl -o /tmp/edge.deb $edge_download_url
        sudo dpkg -i /tmp/edge.deb
    elif [ "$ID" = "arch" ]; then
        yay -S microsoft-edge-stable-bin
    else
        echo 'unkown platform'
        exit 1
    fi
fi

# 配置 aria2、trojan和坚果云

# 下载、安装、破解 datagrip

# 安装 sublime text，并添加插件（如果无法下载插件则创建插件配置文件）

if [ ! -f "$HOME/.config/sublime-text/Packages/User/Default.sublime-keymap" ]; then
    curl -o $HOME/.config/sublime-text/Packages/User/Default.sublime-keymap https://gitee.com/thepoy/sublime-text-4-settings/raw/master/key_bindings.json
fi

# 安装 vscode

# 安装 fcitx5-rime，并下载 98 五笔码表和皮肤
if [ ! -f "/usr/bin/fcitx5" ]; then
    if [ "$id" = "debian" ] || [ "$id" = "ubuntu" ]; then
        echo 'not support'
    elif [ "$ID" = "arch" ]; then
        sudo pacman -S fcitx5-rime fcitx5-configtool fcitx5-gtk fcitx5-qt

    else
        echo 'unkown platform'
        exit 1
    fi
    cp /usr/share/applications/org.fcitx.Fcitx5.desktop $HOME/.config/autostart
fi

if [ ! -d "$HOME/.config/environment.d" ]; then
    mkdir -p $HOME/.config/environment.d
fi


# 安装 libreoffice 套件，指定 gtk3 依赖

# 安装 mpv