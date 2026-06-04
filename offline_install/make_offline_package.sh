#!/bin/bash
# Author: 火星小刘 / 中国青岛
# Cache Zabbix 7 installation files on CentOS, Rocky Linux, Debian, or Ubuntu

echo -e "\e[32mAuthor: \e[0m\e[33m火星小刘 / 中国青岛\e[0m"
echo -e "\e[32m加入QQ群一起开车一起学习: \e[0m\e[33m523870446\e[0m"
echo -e "\e[32m作者github: \e[0m\e[33mhttps://github.com/X-Mars/\e[0m"
echo -e "\e[32m跟作者学运维开发: \e[0m\e[33mhttps://space.bilibili.com/439068477\e[0m"
echo -e "\e[32m本项目地址: \e[0m\e[33mhttps://github.com/X-Mars/Quick-Installation-ZABBIX\e[0m"
echo -e "\e[32m当前脚本介绍: \e[0m\e[33mZabbix 7 离线安装包制作脚本\e[0m"
echo -e "\e[32m支持的操作系统: \e[0m\e[33mcentos 9 / rocky linux 8 / rocky linux 9 / rocky linux 10 / ubuntu 22.04 / ubuntu 24.04\e[0m"

# 检查当前用户是否是root用户
if [ "$(id -u)" -eq 0 ]; then
  echo "当前用户是root用户..."
else
  echo "请使用root用户运行本脚本..."
  exit 1
fi

# 创建缓存文件夹
CACHE_DIR=`pwd`/zabbix_offline
mkdir -p "$CACHE_DIR/rpm"
mkdir -p "$CACHE_DIR/deb"

install_zabbix_release_on_centos_or_rocky() {
  echo '为CentOS或Rocky Linux安装zabbix源...'
  if( [ "$VERSION_ID" == "8" ] || [ "$VERSION_ID" == "9" ] || [ "$VERSION_ID" == "10" ]); then
    curl -O https://mirrors.tuna.tsinghua.edu.cn/zabbix/zabbix/7.0/${ID}/${VERSION_ID}/x86_64/zabbix-release-latest.el${VERSION_ID}.noarch.rpm
    rpm -ivh zabbix-release-latest.el${VERSION_ID}.noarch.rpm
    if [ "$VERSION_ID" == "8" ]; then
      dnf module switch-to php:8.0 -y
    fi
  fi
  dnf module reset mariadb -y
  sed -i 's/repo\.zabbix\.com/mirrors\.aliyun\.com\/zabbix/' /etc/yum.repos.d/zabbix.repo
  sed -i 's/repo\.zabbix\.com/mirrors\.aliyun\.com\/zabbix/' /etc/yum.repos.d/zabbix-agent2-plugins.repo
  mv /etc/yum.repos.d/zabbix-agent2-plugins.repo /etc/yum.repos.d/zabbix-agent2-plugins.repo-bak
}

config_epel(){
  dnf install epel-release -y
  sed -i '/^\[epel\]/a excludepkgs=zabbix*' /etc/yum.repos.d/epel.repo
  sed -i 's|^#baseurl=https://download.example/pub|baseurl=https://mirrors.aliyun.com|' /etc/yum.repos.d/epel*
  sed -i 's|^metalink|#metalink|' /etc/yum.repos.d/epel* 
}

config_rocky(){
  echo '为Rocky Linux配置阿里云源...'
  if ( [ "$VERSION_ID" == "9" ] || [ "$VERSION_ID" == "10" ]); then
    sed -e 's|^mirrorlist=|#mirrorlist=|g' \
      -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=http://mirrors.aliyun.com/rockylinux|g' \
      -i.bak \
      /etc/yum.repos.d/rocky*.repo
    
  elif [ "$VERSION_ID" == "8" ]; then
    sed -e 's|^mirrorlist=|#mirrorlist=|g' \
      -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
      -i.bak \
      /etc/yum.repos.d/Rocky-*.repo
  fi
  dnf makecache
  dnf module reset mariadb -y
}

install_zabbix_release_on_ubuntu_or_debian() {
  echo '为Ubuntu或Debian安装zabbix源...'
  apt install curl -y
  curl -o "$CACHE_DIR/deb/zabbix-release_7.0-1+${ID}${VERSION_ID}_all.deb" https://mirrors.tuna.tsinghua.edu.cn/zabbix/zabbix/7.0/${ID}/pool/main/z/zabbix-release/zabbix-release_7.0-1+${ID}${VERSION_ID}_all.deb
  dpkg -i "$CACHE_DIR/deb/zabbix-release_7.0-1+${ID}${VERSION_ID}_all.deb"

  sed -i 's/repo\.zabbix\.com/mirrors\.aliyun\.com\/zabbix/' /etc/apt/sources.list.d/zabbix.list
  sed -i 's/repo\.zabbix\.com/mirrors\.aliyun\.com\/zabbix/' /etc/apt/sources.list.d/zabbix-agent2-plugins.list
  mv /etc/apt/sources.list.d/zabbix-agent2-plugins.list /etc/apt/sources.list.d/zabbix-agent2-plugins.list-bak
}

config_mariadb_release_on_centos_or_rocky() {
  echo '为CentOS或Rocky Linux配置mariadb 阿里云源...'
  cat > /etc/yum.repos.d/mariadb.repo <<EOF
[mariadb-main]
name = MariaDB Server
baseurl = https://mirrors.aliyun.com/mariadb/yum/11.4/rhel/$VERSION_ID/x86_64
gpgkey = file:///etc/pki/rpm-gpg/MariaDB-Server-GPG-KEY
gpgcheck = 1
enabled = 1
module_hotfixes = 1


[mariadb-maxscale]
# To use the latest stable release of MaxScale, use "latest" as the version
# To use the latest beta (or stable if no current beta) release of MaxScale, use "beta" as the version
name = MariaDB MaxScale
baseurl = https://mirrors.aliyun.com/mariadb/yum/11.4/rhel/$VERSION_ID/x86_64
gpgkey = file:///etc/pki/rpm-gpg/MariaDB-MaxScale-GPG-KEY
gpgcheck = 1
enabled = 1
EOF
}

install_mariadb_release() {
  echo '安装mariadb源...'
  # 判断当前文件夹，是否存在mariadb_repo_setup，如果存在直接运行
  if [ -f "./mariadb_repo_setup" ]; then
    echo "mariadb_repo_setup 已存在，直接运行..."
    bash ./mariadb_repo_setup --mariadb-server-version=11.4
    return
  else
    echo "mariadb_repo_setup 不存在，下载安装..."
    curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | sudo bash -s -- --mariadb-server-version=11.4
  fi
}

# 获取系统信息
source /etc/os-release

# 复制离线安装脚本到zabbix_offline
cp offline_install.sh "$CACHE_DIR"

# 根据操作系统类型和版本选择安装和配置步骤
if [ "$ID" == "centos" ] || [ "$ID" == "rocky" ]; then
  VERSION_ID=$(echo "$VERSION_ID" | cut -d'.' -f1)
  config_epel
  config_rocky
  # install_mariadb_release
  config_mariadb_release_on_centos_or_rocky
  install_zabbix_release_on_centos_or_rocky
  dnf install tar -y
  dnf install --downloadonly --downloaddir="$CACHE_DIR/rpm" zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent MariaDB-server MariaDB-client MariaDB-backup MariaDB-devel langpacks-zh_CN git -y
  dnf install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent
  # 打包
  tar -czvf "$ID-$VERSION_ID-zabbix7-offline-install.tar.gz" -C "$(pwd)" zabbix_offline
elif [ "$ID" == "ubuntu" ] || [ "$ID" == "debian" ]; then
  install_zabbix_release_on_ubuntu_or_debian
  if [ "$ID" == "ubuntu" ]; then
    apt install --download-only language-pack-zh-hans -y
  fi
  install_mariadb_release
  apt install tar -y
  apt install --download-only zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mariadb-server mariadb-client git -y
  cp /var/cache/apt/archives/*.deb "$CACHE_DIR/deb"
  # 打包
  tar -czvf "$ID-$VERSION_ID-zabbix7-offline-install.tar.gz" -C "$(pwd)" zabbix_offline
fi

echo -e "\n\e[31m拉取企业微信、钉钉、飞书告警脚本,具体查看: https://gitee.com/xtlyk/Zabbix-Alert-WeChat\e[0m"
echo -e "\e[31m此操作不影响zabbix使用\e[0m"
echo -e "\e[31m运行命令: ls -la /usr/lib/zabbix/alertscripts 查看脚本\e[0m"
git clone https://gitee.com/xtlyk/Zabbix-Alert-WeChat.git "$CACHE_DIR/alertscripts"
ls -la "$CACHE_DIR/alertscripts"

echo -e "\n\e[31m拉取Zabbix cmdb、报表、图表树、机柜管理等模块，具体查看：https://gitee.com/xtlyk/zabbix_modules\e[0m"
echo -e "\e[31m此操作不影响zabbix使用\e[0m"
echo -e "\e[31m你可以在zabbix 安装完成后，在“管理”-“常规”-“模块”中点击“扫描目录”后，在列表中查找并启用这些模块\e[0m"
git clone https://gitee.com/xtlyk/zabbix_modules.git "$CACHE_DIR/modules"
ls -la "$CACHE_DIR/modules"

echo '离线安装包制作完成。'
echo '请将生成的离线安装包拷贝到没有网络的服务器上执行安装脚本。'
echo "安装命令: tar -xzvf $ID-$VERSION_ID-zabbix7-offline-install.tar.gz && cd zabbix_offline && bash offline_install.sh"
echo '安装过程中可能需要手动安装中文语言包,请按照提示执行。'

