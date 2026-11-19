#!/bin/bash
# ============================================================
# diy-part1.sh —— 在 `./scripts/feeds update -a` 之前执行
# 作用：注入 Turbo ACC 网络加速（适配官方 OpenWrt 25.12 / fw4 / 内核 6.12）
# 工作目录：OpenWrt 源码根目录
# ============================================================
set -e

echo "[diy-part1] 注入 Turbo ACC 网络加速插件 ..."

# mufeng05/turboacc 明确支持官方 24.10 / 25.12 / snapshot，fw4 + 内核 6.12/6.6/6.18
# 注意：add_turboacc.sh 不接受任何命令行参数，脚本会自动检测内核版本并套用匹配补丁
# 它会 clone luci-app-turboacc / fullconenat / shortcut-fe，并为 firewall4、nftables、
# libnftnl 打上全锥 NAT1 与 TCP 拥塞控制所需补丁
curl -fsSL https://raw.githubusercontent.com/mufeng05/turboacc/main/add_turboacc.sh \
  -o add_turboacc.sh
chmod +x add_turboacc.sh
bash add_turboacc.sh

echo "[diy-part1] 完成。"
