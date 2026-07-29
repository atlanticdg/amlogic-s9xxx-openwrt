#!/bin/bash
#========================================================================================================================
# https://github.com/ophub/amlogic-s9xxx-openwrt
# Description: Automatically Build OpenWrt
# Function: Diy script (Before Update feeds, Modify the default IP, hostname, theme, add/remove software packages, etc.)
# Source code repository: https://github.com/coolsnowwolf/lede / Branch: master
#========================================================================================================================

# Add a feed source
# sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default
sed -i '1i src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
# sed -i '2i src-git small https://github.com/kenzok8/small-package' feeds.conf.default 

# 添加 ImmortalWrt 官方 feeds 源
# 注：具体分支名（如 openwrt-24.10）可能需要根据你的情况调整[reference:2]
# sed -i '$a src-git immortal_packages https://github.com/immortalwrt/packages.git;openwrt-25.12' feeds.conf.default
# sed -i '$a src-git immortal_luci https://github.com/immortalwrt/luci.git;openwrt-25.12' feeds.conf.default

# other
# rm -rf package/lean/{samba4,luci-app-samba4,luci-app-ttyd}

