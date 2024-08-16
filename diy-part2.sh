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

#!/bin/bash
# istor
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
# Docker 容器
rm -rf ./feeds/luci/applications/luci-app-dockerman
cp -rf ../dockerman/applications/luci-app-dockerman ./feeds/luci/applications/luci-app-dockerman
sed -i '/auto_start/d' feeds/luci/applications/luci-app-dockerman/root/etc/uci-defaults/luci-app-dockerman
pushd feeds/packages
wget -qO- https://github.com/openwrt/packages/commit/e2e5ee69.patch | patch -p1
wget -qO- https://github.com/openwrt/packages/pull/20054.patch | patch -p1
popd
sed -i '/sysctl.d/d' feeds/packages/utils/dockerd/Makefile
rm -rf ./feeds/luci/collections/luci-lib-docker
cp -rf ../docker_lib/collections/luci-lib-docker ./feeds/luci/collections/luci-lib-docker
# DiskMan
cp -rf ../diskman/applications/luci-app-diskman ./package/new/luci-app-diskman
mkdir -p package/new/parted && \
wget https://raw.githubusercontent.com/lisaac/luci-app-diskman/master/Parted.Makefile -O package/new/parted/Makefile
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
# Passwall
cp -rf ../passwall_luci/luci-app-passwall ./package/new/luci-app-passwall
wget -P package/new/luci-app-passwall/ https://github.com/QiuSimons/OpenWrt-Add/raw/master/move_2_services.sh
chmod -R 755 ./package/new/luci-app-passwall/move_2_services.sh
pushd package/new/luci-app-passwall
bash move_2_services.sh
popd
cp -rf ../passwall_pkg/tcping ./package/new/tcping
cp -rf ../passwall_pkg/trojan-go ./package/new/trojan-go
cp -rf ../passwall_pkg/brook ./package/new/brook
cp -rf ../passwall_pkg/ssocks ./package/new/ssocks
cp -rf ../passwall_pkg/microsocks ./package/new/microsocks
cp -rf ../passwall_pkg/dns2socks ./package/new/dns2socks
cp -rf ../passwall_pkg/ipt2socks ./package/new/ipt2socks
cp -rf ../passwall_pkg/pdnsd-alt ./package/new/pdnsd-alt
cp -rf ../OpenWrt-Add/trojan-plus ./package/new/trojan-plus
cp -rf ../passwall_pkg/xray-plugin ./package/new/xray-plugin
# Passwall 白名单
echo '
teamviewer.com
epicgames.com
dangdang.com
account.synology.com
ddns.synology.com
checkip.synology.com
checkip.dyndns.org
checkipv6.synology.com
ntp.aliyun.com
cn.ntp.org.cn
ntp.ntsc.ac.cn
' >>./package/new/luci-app-passwall/root/usr/share/passwall/rules/direct_host

# ShadowsocksR Plus+ 依赖
rm -rf ./feeds/packages/net/shadowsocks-libev
cp -rf ../lede_pkg/net/shadowsocks-libev ./package/new/shadowsocks-libev
cp -rf ../sbwfw876/shadow-tls ./package/new/shadow-tls
cp -rf ../sbwfw876/v2dat ./package/new/v2dat
cp -rf ../sbwfw876/tuic-client ./package/new/tuic-client
cp -rf ../sbwfw876/redsocks2 ./package/new/redsocks2
cp -rf ../sbwfw876/trojan ./package/new/trojan
cp -rf ../sbwfw876/tcping ./package/new/tcping
cp -rf ../sbwfw876/dns2tcp ./package/new/dns2tcp
cp -rf ../sbwfw876/gn ./package/new/gn
cp -rf ../sbwfw876/shadowsocksr-libev ./package/new/shadowsocksr-libev
cp -rf ../sbwfw876/simple-obfs ./package/new/simple-obfs
cp -rf ../sbwfw876/naiveproxy ./package/new/naiveproxy
cp -rf ../sbwfw876/v2ray-core ./package/new/v2ray-core
cp -rf ../passwall_pkg/hysteria ./package/new/hysteria
cp -rf ../sbwfw876/sagernet-core ./package/new/sagernet-core
rm -rf ./feeds/packages/net/xray-core
cp -rf ../immortalwrt_pkg/net/xray-core ./feeds/packages/net/xray-core
sed -i '/CURDIR/d' feeds/packages/net/xray-core/Makefile
cp -rf ../sbwfw876/v2ray-plugin ./package/new/v2ray-plugin
cp -rf ../sbwfw876/shadowsocks-rust ./package/new/shadowsocks-rust
cp -rf ../sbwfw876/lua-neturl ./package/new/lua-neturl
rm -rf ./feeds/packages/net/kcptun
cp -rf ../immortalwrt_pkg/net/kcptun ./feeds/packages/net/kcptun
ln -sf ../../../feeds/packages/net/kcptun ./package/feeds/packages/kcptun
# ShadowsocksR Plus+
cp -rf ../sbwfw876/luci-app-ssr-plus ./package/new/luci-app-ssr-plus
#rm -rf ./package/new/luci-app-ssr-plus/po/zh_Hans
pushd package/new
wget -qO - https://github.com/fw876/helloworld/commit/5bbf6e7.patch | patch -p1
popd
pushd package/new/luci-app-ssr-plus
sed -i '/Clang.CN.CIDR/a\o:value("https://fastly.jsdelivr.net/gh/QiuSimons/Chnroute@master/dist/chnroute/chnroute.txt", translate("QiuSimons/Chnroute"))' luasrc/model/cbi/shadowsocksr/advanced.lua
popd
# v2raya
git clone --depth 1 https://github.com/zxlhhyccc/luci-app-v2raya.git package/new/luci-app-v2raya
rm -rf ./feeds/packages/net/v2raya
cp -rf ../openwrt_pkg_ma/net/v2raya ./feeds/packages/net/v2raya
ln -sf ../../../feeds/packages/net/v2raya ./package/feeds/packages/v2raya
# socat
cp -rf ../Lienol_pkg/luci-app-socat ./package/new/luci-app-socat
pushd package/new
wget -qO - https://github.com/Lienol/openwrt-package/pull/39.patch | patch -p1
popd
sed -i '/socat\.config/d' feeds/packages/net/socat/Makefile
# natmap
git clone --depth 1 --branch master --single-branch --no-checkout https://github.com/muink/luci-app-natmapt.git package/luci-app-natmapt
pushd package/luci-app-natmapt
umask 022
git checkout
popd
git clone --depth 1 --branch master --single-branch --no-checkout https://github.com/muink/openwrt-natmapt.git package/natmapt
pushd package/natmapt
umask 022
git checkout
popd
git clone --depth 1 --branch master --single-branch --no-checkout https://github.com/muink/openwrt-stuntman.git package/stuntman
pushd package/stuntman
umask 022
git checkout
popd
# 订阅转换
cp -rf ../immortalwrt_pkg/net/subconverter ./feeds/packages/net/subconverter
ln -sf ../../../feeds/packages/net/subconverter ./package/feeds/packages/subconverter
cp -rf ../immortalwrt_pkg/libs/jpcre2 ./feeds/packages/libs/jpcre2
ln -sf ../../../feeds/packages/libs/jpcre2 ./package/feeds/packages/jpcre2
cp -rf ../immortalwrt_pkg/libs/rapidjson ./feeds/packages/libs/rapidjson
ln -sf ../../../feeds/packages/libs/rapidjson ./package/feeds/packages/rapidjson
cp -rf ../immortalwrt_pkg/libs/libcron ./feeds/packages/libs/libcron
ln -sf ../../../feeds/packages/libs/libcron ./package/feeds/packages/libcron
cp -rf ../immortalwrt_pkg/libs/quickjspp ./feeds/packages/libs/quickjspp
ln -sf ../../../feeds/packages/libs/quickjspp ./package/feeds/packages/quickjspp
cp -rf ../immortalwrt_pkg/libs/toml11 ./feeds/packages/libs/toml11
ln -sf ../../../feeds/packages/libs/toml11 ./package/feeds/packages/toml11
# 网易云音乐解锁
#git clone -b js --depth 1 https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic.git package/new/UnblockNeteaseMusic
# uwsgi
sed -i 's,procd_set_param stderr 1,procd_set_param stderr 0,g' feeds/packages/net/uwsgi/files/uwsgi.init
sed -i 's,buffer-size = 10000,buffer-size = 131072,g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's,logger = luci,#logger = luci,g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i '$a cgi-timeout = 600' feeds/packages/net/uwsgi/files-luci-support/luci-*.ini
sed -i 's/threads = 1/threads = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/processes = 3/processes = 4/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/cheaper = 1/cheaper = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
# rpcd
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js
# USB 打印机
#cp -rf ../lede_luci/applications/luci-app-usb-printer ./package/new/luci-app-usb-printer
# UU加速器
#cp -rf ../lede_luci/applications/luci-app-uugamebooster ./package/new/luci-app-uugamebooster
#cp -rf ../lede_pkg/net/uugamebooster ./package/new/uugamebooster
# KMS 激活助手
cp -rf ../lede_luci/applications/luci-app-vlmcsd ./package/new/luci-app-vlmcsd
cp -rf ../lede_pkg/net/vlmcsd ./package/new/vlmcsd
# VSSR
git clone -b master --depth 1 https://github.com/jerrykuku/luci-app-vssr.git package/new/luci-app-vssr
git clone -b master --depth 1 https://github.com/jerrykuku/lua-maxminddb.git package/new/lua-maxminddb
# 网络唤醒
cp -rf ../zxlhhyccc/zxlhhyccc/luci-app-wolplus ./package/new/luci-app-wolplus
# 流量监视
#git clone -b master --depth 1 https://github.com/brvphoenix/wrtbwmon.git package/new/wrtbwmon
#git clone -b master --depth 1 https://github.com/brvphoenix/luci-app-wrtbwmon.git package/new/luci-app-wrtbwmon
# 迅雷快鸟宽带加速
#git clone --depth 1 https://github.com/kiddin9/luci-app-xlnetacc.git package/lean/luci-app-xlnetacc
# Zerotier
#cp -rf ../immortalwrt_luci/applications/luci-app-zerotier ./feeds/luci/applications/luci-app-zerotier
#cp -rf ../OpenWrt-Add/move_2_services.sh ./feeds/luci/applications/luci-app-zerotier/move_2_services.sh
#chmod -R 755 ./feeds/luci/applications/luci-app-zerotier/move_2_services.sh
#pushd feeds/luci/applications/luci-app-zerotier
#bash move_2_services.sh
#popd
#ln -sf ../../../feeds/luci/applications/luci-app-zerotier ./package/feeds/luci/luci-app-zerotier
#rm -rf ./feeds/packages/net/zerotier
#cp -rf ../immortalwrt_pkg/net/zerotier ./feeds/packages/net/zerotier
# watchcat
#echo > ./feeds/packages/utils/watchcat/files/watchcat.config
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
# 翻译及部分功能优化
cp -rf ../OpenWrt-Add/addition-trans-zh ./package/new/addition-trans-zh
sed -i 's,iptables-mod-fullconenat,iptables-nft +kmod-nft-fullcone,g' package/new/addition-trans-zh/Makefile

### 最后的收尾工作 ###
# Lets Fuck
mkdir -p package/base-files/files/usr/bin
cp -rf ../OpenWrt-Add/fuck ./package/base-files/files/usr/bin/fuck
# 生成默认配置及缓存
rm -rf .config
sed -i 's,CONFIG_WERROR=y,# CONFIG_WERROR is not set,g' target/linux/generic/config-5.15

### Shortcut-FE 部分 ###
# Patch Kernel 以支持 Shortcut-FE
cp -rf ../lede/target/linux/generic/hack-5.15/953-net-patch-linux-kernel-to-support-shortcut-fe.patch ./target/linux/generic/hack-5.15/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
cp -f ../PATCH/backport/sfe/601-netfilter-export-udp_get_timeouts-function.patch ./target/linux/generic/hack-5.15/
cp -rf ../lede/target/linux/generic/pending-5.15/613-netfilter_optional_tcp_window_check.patch ./target/linux/generic/pending-5.15/613-netfilter_optional_tcp_window_check.patch
# Patch LuCI 以增添 Shortcut-FE 开关
patch -p1 < ../PATCH/firewall/luci-app-firewall_add_sfe_switch.patch
# Shortcut-FE 相关组件
mkdir ./package/lean
mkdir ./package/lean/shortcut-fe
cp -rf ../lede/package/qca/shortcut-fe/fast-classifier ./package/lean/shortcut-fe/fast-classifier
wget -qO - https://github.com/coolsnowwolf/lede/commit/331f04f.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/232b8b4.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/ec795c9.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/789f805.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/6398168.patch | patch -p1
cp -rf ../lede/package/qca/shortcut-fe/shortcut-fe ./package/lean/shortcut-fe/shortcut-fe
wget -qO - https://github.com/coolsnowwolf/lede/commit/0e29809.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/eb70dad.patch | patch -p1
wget -qO - https://github.com/coolsnowwolf/lede/commit/7ba3ec0.patch | patch -p1
cp -rf ../lede/package/qca/shortcut-fe/simulated-driver ./package/lean/shortcut-fe/simulated-driver

# NAT6
git clone --depth 1 https://github.com/sbwml/packages_new_nat6 package/new/packages_new_nat6
pushd feeds/luci
# Patch LuCI 以增添 NAT6 开关
patch -p1 <../../../PATCH/firewall/03-luci-app-firewall_add_ipv6-nat.patch
# Patch LuCI 以支持自定义 nft 规则
patch -p1 <../../../PATCH/firewall/04-luci-add-firewall4-nft-rules-file.patch
popd

#LTO/GC
# Grub 2
sed -i 's,no-lto,no-lto no-gc-sections,g' package/boot/grub2/Makefile
# openssl disable LTO
sed -i 's,no-mips16 gc-sections,no-mips16 gc-sections no-lto,g' package/libs/openssl/Makefile
# nginx
sed -i 's,gc-sections,gc-sections no-lto,g' feeds/packages/net/nginx/Makefile
# libsodium
sed -i 's,no-mips16,no-mips16 no-lto,g' feeds/packages/libs/libsodium/Makefile
#exit 0
