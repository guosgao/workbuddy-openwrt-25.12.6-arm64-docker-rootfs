#!/bin/bash
# ============================================================
# diy-part2.sh —— 在 `./scripts/feeds install -a` 之后执行
# 作用：注入官方 25.12 源中缺失的中文插件（filetransfer / diskman / autoreboot）
# 工作目录：OpenWrt 源码根目录
# ============================================================
set -e

echo "[diy-part2] 注入文件传输插件 luci-app-filetransfer ..."
# 官方 25.12 与 kenzok8 feed 均不含 luci-app-filetransfer，
# 使用 PKGARCH:=all 的纯 Lua 实现（兼容 22.03+ / 25.12 ucode LuCI）
if [ ! -d "./package/luci-app-filetransfer" ]; then
  git clone --depth 1 https://github.com/selfcan/luci-app-filetransfer.git \
    ./package/luci-app-filetransfer
fi

echo "[diy-part2] 注入磁盘管理 luci-app-diskman ..."
# lisaac/luci-app-diskman 的 Makefile 依赖 luci.mk，需放入 luci feed 的 applications 目录
rm -rf /tmp/diskman-src
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/lisaac/luci-app-diskman.git /tmp/diskman-src
( cd /tmp/diskman-src && git sparse-checkout set applications/luci-app-diskman )
mkdir -p ./feeds/luci/applications
rm -rf ./feeds/luci/applications/luci-app-diskman
cp -a /tmp/diskman-src/applications/luci-app-diskman ./feeds/luci/applications/
./scripts/feeds install luci-app-diskman

echo "[diy-part2] 注入定时重启 luci-app-autoreboot ..."
rm -rf /tmp/autoreboot-src
git clone --depth 1 --filter=blob:none --sparse \
  https://github.com/immortalwrt/luci.git /tmp/autoreboot-src
( cd /tmp/autoreboot-src && git sparse-checkout set applications/luci-app-autoreboot )
rm -rf ./feeds/luci/applications/luci-app-autoreboot
cp -a /tmp/autoreboot-src/applications/luci-app-autoreboot ./feeds/luci/applications/
./scripts/feeds install luci-app-autoreboot

echo "[diy-part2] 完成。"
