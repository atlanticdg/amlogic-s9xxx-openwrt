#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt
# Function: DIY script (After updating feeds — modify the default IP, hostname, theme, add/remove packages, etc.)
# Source code repository: https://github.com/immortalwrt/immortalwrt / Branch: master
#========================================================================================================================

# ------------------------------- Main source configuration -------------------------------
#
# Set the default LAN IP address
default_ip="192.168.1.1"
ip_regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
# Override default IP if a valid custom IP is provided as the first argument
[[ -n "${1}" && "${1}" != "${default_ip}" && "${1}" =~ ${ip_regex} ]] && {
    echo "Modify default IP address to: ${1}"
    sed -i "/lan) ipad=\${ipaddr:-/s/\${ipaddr:-\"[^\"]*\"}/\${ipaddr:-\"${1}\"}/" package/base-files/*/bin/config_generate
}

# Set the default password for the 'root' user (change empty password to 'password')
sed -i 's/root:::0:99999:7:::/root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.::0:99999:7:::/g' package/base-files/files/etc/shadow

# Append source repository information to etc/openwrt_release
sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION='R$(date +%Y.%m.%d)'|g" package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCEREPO='github.com/immortalwrt/immortalwrt'" >>package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCECODE='immortalwrt'" >>package/base-files/files/etc/openwrt_release
echo "DISTRIB_SOURCEBRANCH='master'" >>package/base-files/files/etc/openwrt_release

# Configure ccache for build acceleration
# Remove existing ccache settings
sed -i '/CONFIG_DEVEL/d' .config
sed -i '/CONFIG_CCACHE/d' .config
# Apply new ccache configuration
if [[ "${2}" == "true" ]]; then
    echo "CONFIG_DEVEL=y" >>.config
    echo "CONFIG_CCACHE=y" >>.config
    echo 'CONFIG_CCACHE_DIR="$(TOPDIR)/.ccache"' >>.config
else
    echo '# CONFIG_DEVEL is not set' >>.config
    echo "# CONFIG_CCACHE is not set" >>.config
    echo 'CONFIG_CCACHE_DIR=""' >>.config
fi
#
# ------------------------------- Main source configuration ends -------------------------------

# ------------------------------- Other started -------------------------------
#
# Add luci-app-amlogic
rm -rf package/luci-app-amlogic
git clone -b main https://github.com/ophub/luci-app-amlogic.git package/luci-app-amlogic
#
# Apply patch
# git apply ../config/patches/{0001*,0002*}.patch --directory=feeds/luci
#
# ------------------------------- Other ends -------------------------------

# ===== 启用 OpenClash 和 PassWall（ImmortalWrt 25.12 官方源自带） =====
echo "Enabling OpenClash and PassWall..."
echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config
echo "CONFIG_PACKAGE_luci-app-passwall=y" >> .config
echo "CONFIG_PACKAGE_luci-i18n-openclash-zh-cn=y" >> .config
echo "CONFIG_PACKAGE_luci-i18n-passwall-zh-cn=y" >> .config

# ===== 启用 RTL8822BE WiFi 驱动 =====
echo "Enabling RTL8822BE driver..."
echo "CONFIG_PACKAGE_kmod-rtw88-8822be=y" >> .config

# ===== 安全防护：禁用 Rust（如官方源不触发则无影响） =====
# 仅当 Rust 包存在时才 stub，避免不必要修改
if [ -d "feeds/packages/lang/rust" ]; then
    echo "Stubbing Rust Makefile to prevent CI artifact download failure..."
    cat > feeds/packages/lang/rust/Makefile << 'RUSTSTUB'
include $(TOPDIR)/rules.mk
PKG_NAME:=rust
PKG_VERSION:=0.0.0
PKG_RELEASE:=1
PKG_BUILD_DEPENDS:=
include $(INCLUDE_DIR)/package.mk
RUSTSTUB

    # 同步处理依赖 rust 的包
    for pkg in maturin uv; do
        found=$(find feeds/packages -name "$pkg" -type d 2>/dev/null | head -1)
        if [ -n "$found" ]; then
            cat > "$found/Makefile" << 'DEPSTUB'
include $(TOPDIR)/rules.mk
PKG_NAME:=stub
PKG_VERSION:=0.0.0
PKG_RELEASE:=1
PKG_BUILD_DEPENDS:=
include $(INCLUDE_DIR)/package.mk
DEPSTUB
        fi
    done

    sed -i '/CONFIG_PACKAGE_rust/d' .config
    sed -i '/CONFIG_PACKAGE_rustc/d' .config
    sed -i '/CONFIG_PACKAGE_cargo/d' .config
    sed -i '/CONFIG_PACKAGE_maturin/d' .config
    sed -i '/CONFIG_PACKAGE_uv/d' .config
    echo '# CONFIG_PACKAGE_rust is not set' >> .config
    echo '# CONFIG_PACKAGE_rustc is not set' >> .config
    echo '# CONFIG_PACKAGE_cargo is not set' >> .config
fi
