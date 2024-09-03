#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

# Uncomment a feed source
# Add a feed helloword
sed -i "/helloworld/d" "feeds.conf.default"
echo "src-git helloworld https://github.com/fw876/helloworld.git" >> "feeds.conf.default"

# Add a feed source

mkdir -p files/usr/share
mkdir -p files/etc/
touch files/etc/lenyu_version
mkdir wget
touch wget/DISTRIB_REVISION1
touch wget/DISTRIB_REVISION3
touch files/usr/share/Check_Update.sh
touch files/usr/share/Lenyu-auto.sh
touch files/usr/share/Lenyu-pw.sh

# backup config
cat>> package/base-files/files/lib/upgrade/keep.d/base-files-essential<<-EOF
/etc/config/dhcp
/etc/config/sing-box
/etc/config/romupdate
/etc/config/passwall_show
/etc/config/passwall_server
/etc/config/passwall
/usr/share/v2ray/geosite.dat
/usr/share/v2ray/geoip.dat
/usr/share/passwall/rules/
/usr/share/singbox/
/usr/share/v2ray/
/etc/openclash/core/
/usr/bin/chinadns-ng
/usr/bin/sing-box
/usr/bin/hysteria
EOF


cat>rename.sh<<-\EOF
#!/bin/bash
rm -rf  bin/targets/x86/64/config.buildinfo
rm -rf  bin/targets/x86/64/feeds.buildinfo
rm -rf  bin/targets/x86/64/immortalwrt-x86-64-generic-kernel.bin
rm -rf  bin/targets/x86/64/immortalwrt-x86-64-generic-squashfs-rootfs.img.gz
rm -rf  bin/targets/x86/64/immortalwrt-x86-64-generic-rootfs.tar.gz
rm -rf  bin/targets/x86/64/immortalwrt-x86-64-generic.manifest
rm -rf bin/targets/x86/64/sha256sums
rm -rf  bin/targets/x86/64/version.buildinfo
rm -rf bin/targets/x86/64/immortalwrt-x86-64-generic-ext4-rootfs.img.gz
rm -rf bin/targets/x86/64/immortalwrt-x86-64-generic-ext4-combined-efi.img.gz
rm -rf bin/targets/x86/64/immortalwrt-x86-64-generic-ext4-combined.img.gz
sleep 2
rename_version=`cat files/etc/lenyu_version`
str1=`grep "KERNEL_PATCHVER:="  target/linux/x86/Makefile | cut -d = -f 2` #判断当前默认内核版本号如5.10
ver54=`grep "LINUX_VERSION-5.4 ="  include/kernel-5.4 | cut -d . -f 3`
ver515=`grep "LINUX_VERSION-5.15 ="  include/kernel-5.15 | cut -d . -f 3`
sleep 2
if [ "$str1" = "5.4" ];then
  mv  bin/targets/x86/64/immortalwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/immortalwrt_x86-64-${rename_version}_${str1}.${ver54}_sta_Lenyu.img.gz
  mv  bin/targets/x86/64/immortalwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/immortalwrt_x86-64-${rename_version}_${str1}.${ver54}_uefi-gpt_sta_Lenyu.img.gz
elif [ "$str1" = "5.15" ];then
  mv  bin/targets/x86/64/immortalwrt-x86-64-generic-squashfs-combined.img.gz       bin/targets/x86/64/immortalwrt_x86-64-${rename_version}_${str1}.${ver515}_sta_Lenyu.img.gz
  mv  bin/targets/x86/64/immortalwrt-x86-64-generic-squashfs-combined-efi.img.gz   bin/targets/x86/64/immortalwrt_x86-64-${rename_version}_${str1}.${ver515}_uefi-gpt_sta_Lenyu.img.gz
fi
ls bin/targets/x86/64 | grep "gpt_sta_Lenyu.img" | cut -d - -f 3 | cut -d _ -f 1-2 > wget/op_version1
#md5
ls -l  "bin/targets/x86/64" | awk -F " " '{print $9}' > wget/open_sta_md5
sta_version=`grep "_uefi-gpt_sta_Lenyu.img.gz" wget/open_sta_md5 | cut -d - -f 3 | cut -d _ -f 1-2`
immortalwrt_sta=immortalwrt_x86-64-${sta_version}_sta_Lenyu.img.gz
immortalwrt_sta_uefi=immortalwrt_x86-64-${sta_version}_uefi-gpt_sta_Lenyu.img.gz
cd bin/targets/x86/64
md5sum $immortalwrt_sta > immortalwrt_sta.md5
md5sum $immortalwrt_sta_uefi > immortalwrt_sta_uefi.md5
exit 0
EOF

cat>lenyu.sh<<-\EOOF
#!/bin/bash
lenyu_version="`date '+%y%m%d%H%M'`_sta_Len yu" 
echo $lenyu_version >  wget/DISTRIB_REVISION1 
echo $lenyu_version | cut -d _ -f 1 >  files/etc/lenyu_version  
new_DISTRIB_REVISION=`cat  wget/DISTRIB_REVISION1`
#
grep "Check_Update.sh"  package/emortal/default-settings/files/99-default-settings
if [ $? != 0 ]; then
	sed -i 's/exit 0/ /'  package/emortal/default-settings/files/99-default-settings
	cat>> package/emortal/default-settings/files/99-default-settings<<-EOF
	sed -i '$ a alias lenyu="sh /usr/share/Check_Update.sh"' /etc/profile
	sed -i '/DISTRIB_DESCRIPTION/d' /etc/openwrt_release
	echo "DISTRIB_DESCRIPTION='$new_DISTRIB_REVISION'" >> /etc/openwrt_release
	exit 0
	EOF
fi
grep "Lenyu-auto.sh"  package/emortal/default-settings/files/99-default-settings
if [ $? != 0 ]; then
	sed -i 's/exit 0/ /'  package/emortal/default-settings/files/99-default-settings
	cat>> package/emortal/default-settings/files/99-default-settings<<-EOF
	sed -i '$ a alias lenyu-auto="sh /usr/share/Lenyu-auto.sh"' /etc/profile
	exit 0
	EOF
fi

grep "Lenyu-pw.sh"  package/emortal/default-settings/files/99-default-settings
if [ $? != 0 ]; then
	sed -i 's/exit 0/ /'  package/emortal/default-settings/files/99-default-settings
	cat>> package/emortal/default-settings/files/99-default-settings<<-EOF
	sed -i '$ a alias lenyu-pw="sh /usr/share/Lenyu-pw.sh"' /etc/profile
	exit 0
	EOF
fi

grep "xray_backup"  package/emortal/default-settings/files/99-default-settings
if [ $? != 0 ]; then
	sed -i 's/exit 0/ /'  package/emortal/default-settings/files/99-default-settings
	cat<< 'EOF' >> package/emortal/default-settings/files/99-default-settings
		cat<< 'EOFF' > /etc/rc.local
		# Put your custom commands here that should be executed once
		# the system init finished. By default this file does nothing.
		if [ -f "/etc/xray_backup/xray_backup" ]; then
		cp -f /etc/xray_backup/xray_backup /usr/bin/xray
		# chmod +x /usr/bin/xray
		# Check if the copy operation was successful
		  if [ $? -eq 0 ]; then
		 touch /tmp/xray_succ.log
		  fi
		rm -rf  /etc/xray_backup/xray_backup
		fi
		exit 0 
		EOFF
	exit 0
	EOF
fi
EOOF
cat>files/usr/share/Check_Update.sh<<-\EOF
#!/bin/bash
# https://github.com/Blueplanet20120/Actions-OpenWrt-x86
# Actions-OpenWrt-x86 By Lenyu 20210505
#path=$(dirname $(readlink -f $0))
# cd ${path}
#检测准备
if [ ! -f  "/etc/lenyu_version" ]; then
	echo
	echo -e "\033[31m 该脚本在非Lenyu固件上运行，为避免不必要的麻烦，准备退出… \033[0m"
	echo
	exit 0
fi
rm -f /tmp/cloud_version
# 获取固件云端版本号、内核版本号信息
current_version=`cat /etc/lenyu_version`
curl -s https://api.github.com/repos/minyang3194/immortalwrt-86/releases/latest | grep 'tag_name' | cut -d\" -f4 > /tmp/cloud_ts_version
sleep 3
if [ -s  "/tmp/cloud_ts_version" ]; then
	cloud_version=`cat /tmp/cloud_ts_version | cut -d _ -f 1`
	cloud_kernel=`cat /tmp/cloud_ts_version | cut -d _ -f 2`
	#固件下载地址
	new_version=`cat /tmp/cloud_ts_version`
	DEV_URL=https://github.com/minyang3194/immortalwrt-86/releases/download/${new_version}/immortalwrt_x86-64-${new_version}_sta_Lenyu.img.gz
	DEV_UEFI_URL=https://github.com/minyang3194/immortalwrt-86/releases/download/${new_version}/immortalwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
	immortalwrt_sta=https://github.com/minyang3194/immortalwrt-86/releases/download/${new_version}/immortalwrt_sta.md5
	immortalwrt_sta_uefi=https://github.com/minyang3194/immortalwrt-86/releases/download/${new_version}/immortalwrt_sta_uefi.md5
else
	echo "请检测网络或重试！"
	exit 1
fi
####
Firmware_Type="$(grep 'DISTRIB_ARCH=' /etc/immortalwrt_release | cut -d \' -f 2)"
echo $Firmware_Type > /etc/lenyu_firmware_type
echo
if [[ "$cloud_kernel" =~ "4.19" ]]; then
	echo
	echo -e "\033[31m 该脚本在Lenyu固件Sta版本上运行，目前只建议在Dev版本上运行，准备退出… \033[0m"
	echo
	exit 0
fi
#md5值验证，固件类型判断
if [ ! -d /sys/firmware/efi ];then
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_URL" -O /tmp/immortalwrt_x86-64-${new_version}_sta_Lenyu.img.gz
		wget -P /tmp "$immortalwrt_sta" -O /tmp/immortalwrt_sta.md5
		cd /tmp && md5sum -c immortalwrt_sta.md5
		if [ $? != 0 ]; then
      echo "您下载文件失败，请检查网络重试…"
      sleep 4
      exit
		fi
		Boot_type=logic
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
else
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_UEFI_URL" -O /tmp/immortalwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
		wget -P /tmp "$immortalwrt_sta_uefi" -O /tmp/immortalwrt_sta_uefi.md5
		cd /tmp && md5sum -c immortalwrt_sta_uefi.md5
		if [ $? != 0 ]; then
      echo "您下载文件失败，请检查网络重试…"
      sleep 4
      exit
		fi
		Boot_type=efi
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
fi

open_up()
{
echo
clear
read -n 1 -p  " 您是否要保留配置升级，保留选择Y,否则选N:" num1
echo
case $num1 in
	Y|y)
	echo
  echo -e "\033[32m >>>正在准备保留配置升级，请稍后，等待系统重启…-> \033[0m"
	echo
	sleep 3
	if [ ! -d /sys/firmware/efi ];then
		gzip -d immortalwrt_x86-64-${new_version}_sta_Lenyu.img.gz
		sysupgrade /tmp/immortalwrt_x86-64-${new_version}_sta_Lenyu.img
	else
		gzip -d immortalwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
		sysupgrade /tmp/immortalwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img
	fi
    ;;
    n|N)
    echo
    echo -e "\033[32m >>>正在准备不保留配置升级，请稍后，等待系统重启…-> \033[0m"
    echo
    sleep 3
	if [ ! -d /sys/firmware/efi ];then
		gzip -d immortalwrt_x86-64-${new_version}_sta_Lenyu.img.gz
		sysupgrade -n  /tmp/immortalwrt_x86-64-${new_version}_sta_Lenyu.img
	else
		gzip -d immortalwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
		sysupgrade -n  /tmp/immortalwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img
	fi
    ;;
    *)
	  echo
    echo -e "\033[31m err：只能选择Y/N\033[0m"
	  echo
    read -n 1 -p  "请回车继续…"
	  echo
	  open_up
esac
}

open_op()
{
echo
read -n 1 -p  " 您确定要升级吗，升级选择Y,否则选N:" num1
echo
case $num1 in
	Y|y)
	  open_up
    ;;
  n|N)
    echo
    echo -e "\033[31m >>>您已选择退出固件升级，已经终止脚本…-> \033[0m"
    echo
    exit 1
    ;;
  *)
    echo
    echo -e "\033[31m err：只能选择Y/N\033[0m"
    echo
    read -n 1 -p  "请回车继续…"
    echo
    open_op
esac
}
open_op
exit 0
EOF

cat>files/usr/share/Lenyu-auto.sh<<-\EOF
#!/bin/bash
# https://github.com/Blueplanet20120/immortalwrt-86
# Actions-OpenWrt-x86 By Lenyu 20210505
#path=$(dirname $(readlink -f $0))
# cd ${path}
#检测准备
if [ ! -f  "/etc/lenyu_version" ]; then
echo
echo -e "\033[31m 该脚本在非Lenyu固件上运行，为避免不必要的麻烦，准备退出… \033[0m"
echo
exit 0
fi
rm -f /tmp/cloud_version

# 备份backup-passwall中的xray文件
if [ ! -d "/etc/xray_backup" ]; then
    mkdir /etc/xray_backup
fi
cp -f /usr/bin/xray /etc/xray_backup/xray_backup

# 获取固件云端版本号、内核版本号信息
current_version=`cat /etc/lenyu_version`
# wget -qO- -T2 "https://api.github.com/repos/Blueplanet20120/immortalwrt-86/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g'  > /tmp/cloud_ts_version
# 因immortalwrt不支持上述格式.
curl -s https://api.github.com/repos/minyang3194/immortalwrt-86/releases/latest | grep 'tag_name' | cut -d\" -f4 > /tmp/cloud_ts_version
sleep 3
if [ -s  "/tmp/cloud_ts_version" ]; then
cloud_version=`cat /tmp/cloud_ts_version | cut -d _ -f 1`
cloud_kernel=`cat /tmp/cloud_ts_version | cut -d _ -f 2`
#固件下载地址
new_version=`cat /tmp/cloud_ts_version` # 2208052057_5.4.203
DEV_URL=https://github.com/minyang3194/immortalwrt-86/releases/download/${new_version}/immortalwrt_x86-64-${new_version}_sta_Lenyu.img.gz
DEV_UEFI_URL=https://github.com/minyang3194/immortalwrt-86/releases/download/${new_version}/immortalwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
immortalwrt_sta=https://github.com/minyang3194/immortalwrt-86/releases/download/${new_version}/immortalwrt_sta.md5
immortalwrt_sta_uefi=https://github.com/minyang3194/immortalwrt-86/releases/download/${new_version}/immortalwrt_sta_uefi.md5
else
echo "请检测网络或重试！"
exit 1
fi
####
Firmware_Type="$(grep 'DISTRIB_ARCH=' /etc/lenyu_version | cut -d \' -f 2)"
echo $Firmware_Type > /etc/lenyu_firmware_type
echo
if [[ "$cloud_kernel" =~ "4.19" ]]; then
echo
echo -e "\033[31m 该脚本在Lenyu固件Sta版本上运行，目前只建议在Dev版本上运行，准备退出… \033[0m"
echo
exit 0
fi
#md5值验证，固件类型判断
if [ ! -d /sys/firmware/efi ];then
if [ "$current_version" != "$cloud_version" ];then
wget -P /tmp "$DEV_URL" -O /tmp/immortalwrt_x86-64-${new_version}_sta_Lenyu.img.gz
wget -P /tmp "$immortalwrt_sta" -O /tmp/immortalwrt_sta.md5
cd /tmp && md5sum -c immortalwrt_sta.md5
if [ $? != 0 ]; then
  echo "您下载文件失败，请检查网络重试…"
  sleep 4
  exit
fi
gzip -d /tmp/immortalwrt_x86-64-${new_version}_sta_Lenyu.img.gz
sysupgrade /tmp/immortalwrt_x86-64-${new_version}_sta_Lenyu.img
else
echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
echo
exit
fi
else
if [ "$current_version" != "$cloud_version" ];then
wget -P /tmp "$DEV_UEFI_URL" -O /tmp/immortalwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
wget -P /tmp "$immortalwrt_sta_uefi" -O /tmp/immortalwrt_sta_uefi.md5
cd /tmp && md5sum -c immortalwrt_sta_uefi.md5
if [ $? != 0 ]; then
echo "您下载文件失败，请检查网络重试…"
sleep 1
exit
fi
gzip -d /tmp/immortalwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img.gz
sysupgrade /tmp/immortalwrt_x86-64-${new_version}_uefi-gpt_sta_Lenyu.img
else
echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
echo
exit
fi
fi

exit 0
EOF

cat>files/usr/share/Lenyu-pw.sh<<-\EOF
#!/bin/sh
# Ensure unzip is installed
opkg update
opkg install unzip

# Define variables
TEMP_DIR="/tmp/test"

# Create temporary directory
mkdir -p "$TEMP_DIR"

# Get the latest release information
latest_release=$(curl -s https://api.github.com/repos/xiaorouji/openwrt-passwall/releases/latest)

# Extract version number
version=$(echo "$latest_release" | grep '"tag_name":' | sed -E 's/.*"tag_name": "([^"]+)".*/\1/')

# Extract download URLs
luci_app_passwall_url=$(echo "$latest_release" | grep -o '"browser_download_url": "[^"]*luci-23.05_luci-app-passwall_[^"]*"' | sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/')
luci_i18n_passwall_url=$(echo "$latest_release" | grep -o '"browser_download_url": "[^"]*luci-23.05_luci-i18n-passwall-zh-cn_[^"]*"' | sed -E 's/.*"browser_download_url": "([^"]+)".*/\1/')

# Download files to temporary directory
wget -O "$TEMP_DIR/luci-23.05_luci-app-passwall_${version}_all.ipk" "$luci_app_passwall_url"
wget -O "$TEMP_DIR/luci-23.05_luci-i18n-passwall-zh-cn_${version}_all.ipk" "$luci_i18n_passwall_url"
sleep 5
echo "Download completed:"
echo "$TEMP_DIR/luci-23.05_luci-app-passwall_${version}_all.ipk"
echo "$TEMP_DIR/luci-23.05_luci-i18n-passwall-zh-cn_${version}_all.ipk"

# Install downloaded IPK files
opkg install "$TEMP_DIR/luci-23.05_luci-app-passwall_${version}_all.ipk"
opkg install "$TEMP_DIR/luci-23.05_luci-i18n-passwall-zh-cn_${version}_all.ipk"

# Restart passwall service
/etc/init.d/passwall restart

echo "Plugins installed and passwall service restarted."

rm -rf $TEMP_DIR
 
exit 0
EOF
