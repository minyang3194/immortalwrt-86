#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.2.99/g' package/base-files/files/bin/config_generate
#sed -i 's/KERNEL_PATCHVER:=5.15/KERNEL_PATCHVER:=5.10/g' target/linux/x86/Makefile
#sed -i "s/.*PKG_VERSION:=.*/PKG_VERSION:=4.3.9_v1.2.14/" package/lean/qBittorrent-static/Makefile
# welcome test 

#添加istore
git clone --depth=1 https://github.com/linkease/istore-ui.git
cp -rf istore-ui/app-store-ui package/app-store-ui
git clone --depth=1 https://github.com/linkease/istore.git
cp -rf istore/luci/luci-app-store package/luci-app-store
sed -i 's/luci-lib-ipkg/luci-base/g' package/luci-app-store/Makefile
#rm -rf istore-ui istore

/bin/bash
# istore
echo >> feeds.conf.default
echo 'src-git istore https://github.com/linkease/istore;main' >> feeds.conf.default
./scripts/feeds update istore
./scripts/feeds install -d y -p istore luci-app-store
# nas-luci feeds源
echo >> feeds.conf.default
echo 'src-git nas https://github.com/linkease/nas-packages.git;master' >> feeds.conf.default
echo 'src-git nas_luci https://github.com/linkease/nas-packages-luci.git;main' >> feeds.conf.default
./scripts/feeds update nas nas_luci
./scripts/feeds install -a -p nas
./scripts/feeds install -a -p nas_luci


# 隔空投送Airconnect
git clone https://github.com/sbwml/luci-app-airconnect package/new/airconnect
sed -i 's,respawn,respawn 3600 5 0,g' package/new/airconnect/airconnect/files/airconnect.init
#cp -rf ../OpenWrt-Add/airconnect ./package/new/airconnect
#cp -rf ../OpenWrt-Add/luci-app-airconnect ./package/new/luci-app-airconnect

# sirpdboy源码
git clone https://github.com/siropboy/sirpdboy-package package/sirpdboy-package
make menuconfig

# 动态DNS
sed -i '/boot()/,+2d' feeds/packages/net/ddns-scripts/files/etc/init.d/ddns
cp -rf ../openwrt-third/ddns-scripts_aliyun ./feeds/packages/net/ddns-scripts_aliyun
ln -sf ../../../feeds/packages/net/ddns-scripts_aliyun ./package/feeds/packages/ddns-scripts_aliyun

# Dnsfilter
git clone --depth 1 https://github.com/kiddin9/luci-app-dnsfilter.git package/new/luci-app-dnsfilter
# Dnsproxy
cp -rf ../OpenWrt-Add/luci-app-dnsproxy ./package/new/luci-app-dnsproxy

# OpenClash
git clone --single-branch --depth 1 -b master https://github.com/vernesong/OpenClash.git package/new/luci-app-openclash
# 加入OpenClash核心
#chmod -R a+x $GITHUB_WORKSPACE/preset-clash-core.sh
#$GITHUB_WORKSPACE/preset-clash-core.sh
# 预置Clash内核
echo -e "预置Clash内核"
mkdir -p package/luci-app-openclash/root/etc/openclash/core
core_path="package/luci-app-openclash/root/etc/openclash/core"
goe_path="package/luci-app-openclash/root/etc/openclash"

CLASH_DEV_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/dev/clash-linux-amd64.tar.gz"
CLASH_TUN_URL=$(curl -fsSL https://api.github.com/repos/vernesong/OpenClash/contents/master/premium\?ref\=core | grep download_url | grep "amd64" | awk -F '"' '{print $4}' | grep "v3" )
CLASH_META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz"
GEOIP_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
GEOSITE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"

wget -qO- $CLASH_DEV_URL | tar xOvz > $core_path/clash
wget -qO- $CLASH_TUN_URL | gunzip -c > $core_path/clash_tun
wget -qO- $CLASH_META_URL | tar xOvz > $core_path/clash_meta
wget -qO- $GEOIP_URL > $goe_path/GeoIP.dat
wget -qO- $GEOSITE_URL > $goe_path/GeoSite.dat

chmod +x $core_path/clash*

# socat
cp -rf ../Lienol_pkg/luci-app-socat ./package/new/luci-app-socat
pushd package/new
wget -qO - https://github.com/Lienol/openwrt-package/pull/39.patch | patch -p1
popd
sed -i '/socat\.config/d' feeds/packages/net/socat/Makefile

# sirpdboy
mkdir -p package/sirpdboy
cp -rf ../sirpdboy/luci-app-autotimeset ./package/sirpdboy/luci-app-autotimeset
sed -i 's,"control","system",g' package/sirpdboy/luci-app-autotimeset/luasrc/controller/autotimeset.lua
sed -i '/firstchild/d' package/sirpdboy/luci-app-autotimeset/luasrc/controller/autotimeset.lua
sed -i 's,control,system,g' package/sirpdboy/luci-app-autotimeset/luasrc/view/autotimeset/log.htm
sed -i '/start()/a \    echo "Service autotimesetrun started!" >/dev/null' package/sirpdboy/luci-app-autotimeset/root/etc/init.d/autotimesetrun
rm -rf ./package/sirpdboy/luci-app-autotimeset/po/zh_Hans
cp -rf ../sirpdboy/luci-app-partexp ./package/sirpdboy/luci-app-partexp
rm -rf ./package/sirpdboy/luci-app-partexp/po/zh_Hans
sed -i 's, - !, -o !,g' package/sirpdboy/luci-app-partexp/root/etc/init.d/partexp
sed -i 's,expquit 1 ,#expquit 1 ,g' package/sirpdboy/luci-app-partexp/root/etc/init.d/partexp
