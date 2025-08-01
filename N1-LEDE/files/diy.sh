#!/bin/bash
# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# Add packages
#添加科学上网源
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall-packages
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/openwrt-passwall
git clone -b 18.06 --single-branch --depth 1 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone -b 18.06 --single-branch --depth 1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth=1 https://github.com/ophub/luci-app-amlogic package/amlogic
git clone --depth=1 https://github.com/sirpdboy/luci-app-ddns-go package/ddnsgo
#git clone --depth=1 https://github.com/sirpdboy/NetSpeedTest package/NetSpeedTest

git clone -b v5-lua --single-branch --depth 1 https://github.com/sbwml/luci-app-mosdns package/mosdns
git clone -b lua --single-branch --depth 1 https://github.com/sbwml/luci-app-alist package/alist
git clone --depth=1 https://github.com/gdy666/luci-app-lucky.git package/lucky

# ============ 添加 luci-app-openlist2 ============
echo "正在添加 luci-app-openlist2 插件..."

# 删除可能已存在的旧版本
rm -rf package/luci-app-openlist2
rm -rf feeds/luci/applications/luci-app-openlist2

# 克隆插件
git clone https://github.com/sbwml/luci-app-openlist2.git package/luci-app-openlist2

# 进入目录并运行 install.sh（关键：自动下载 openlist 数据）
(
  cd package/luci-app-openlist2
  ./install.sh
)

# 将插件加入 feeds（确保编译系统识别）
echo "src-link openlist2 $PWD/package/luci-app-openlist2" >> feeds.conf.default

# ============ 以上是新增部分 ============

#添加自定义的软件包源
#git_sparse_clone main https://github.com/kiddin9/kwrt-packages ddns-go
#git_sparse_clone main https://github.com/kiddin9/kwrt-packages luci-app-ddns-go

# Remove packages
#删除lean库中的插件，使用自定义源中的包。
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/luci/applications/luci-app-mosdns
#rm -rf feeds/luci/themes/luci-theme-design
#rm -rf feeds/luci/applications/luci-app-design-config

# ============ 修改默认 IP 为 192.168.50.200 ============
# 你已设置，保留即可
sed -i 's/192.168.1.1/192.168.50.200/g' package/base-files/files/bin/config_generate

# ============ ⭐ 关键：禁用 DHCP 服务（旁路由必须）⭐ ============
echo "禁用 LAN 口 DHCP 服务，避免与主路由 192.168.50.1 冲突"
cat > package/base-files/files/etc/config/dhcp <<EOF
config dnsmasq
    option domainneeded '1'
    option boguspriv '1'
    option filterwin2k '1'
    option localise_queries '1'
    option rebind_protection '1'
    option rebind_localhost '1'
    option local '/lan/'
    option domain 'lan'
    option expandhosts '1'
    option nonegcache '0'
    option authoritative '1'
    option readethers '1'
    option leasefile '/tmp/dhcp.leases'
    option resolvfile '/tmp/resolv.conf.auto'
    option nonwildcard '1'
    option localservice '1'

config dhcp 'lan'
    option interface 'lan'
    option ignore '1'
EOF

# ============ 修改默认时间格式 ============
sed -i 's/os.date()/os.date("%Y-%m-%d %H:%M:%S %A")/g' $(find ./package/*/autocore/files/ -type f -name "index.htm")
