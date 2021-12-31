#!/bin/bash
# @Author: thepoy
# @Date:   2021-12-30 19:08:33
# @Last Modified by:   thepoy
# @Last Modified time: 2021-12-31 11:22:18

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
    LC_ALL=C xdg-user-dirs-update --force
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
if [ ! -d "$HOME/.config/pip/pip.conf" ]; then
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
curl -o /tmp/go.html https://golang.google.cn/dl/
download_ele="$(grep -Eo "<a class=\"download downloadBox\" href=\"\/dl\/go.*\.linux-amd64\.tar\.gz" /tmp/go.html)"
download_url="https://dl.google.com/go${download_ele:41}"
curl -o /tmp/go.tar.gz $download_url
if [ -d "/usr/local/go" ]; then
    sudo rm -rf /usr/local/go
fi
sudo tar -C /usr/local -xzf /tmp/go.tar.gz

# 配置 go
echo 'GOROOT=/usr/local/go
GOPATH=$HOME/go
PATH=$GOROOT/bin:$GOPATH/bin:$PATH' >> .zshenv
source .zshenv
go env -w GO111MODULE=on
go env -w GOPROXY=https://goproxy.cn,direct

# 设置 goproxy

# 安装 docker 、添加当前用户到 docker 组，并配置镜像仓库

# 配置 aria2、trojan和坚果云

# 安装 sublime text，并添加插件（如果无法下载插件则创建插件配置文件）

# 安装 vscode

# 安装 fcitx5-rime，并下载 98 五笔码表和皮肤

# 安装浏览器，edge 和 firefox

# 安装 libreoffice 套件，指定 gtk3 依赖

# 安装 mpv