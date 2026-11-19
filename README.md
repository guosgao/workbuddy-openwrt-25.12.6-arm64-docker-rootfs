# OpenWrt 25.12.6 ARM64（Docker rootfs.tar.gz）定制构建

基于官方 **OpenWrt 25.12.6**，目标平台 `armsr/armv8`（ARM64），产出 **rootfs.tar.gz**（可直接 `docker import`）。默认 IP `192.168.1.2`、网关 `192.168.1.1`、账号 `root`、密码 `password`，已按需求集成指定插件与 LuCI 菜单。

> ⚠️ **重要说明**：本仓库是「一键云编译配置」，不是编译好的固件本体。编译在有 Linux 环境的 **GitHub Actions** 上完成（本机为 Windows，无 WSL/Docker/GCC，无法本地交叉编译）。你只需把本仓库文件放到自己的 GitHub 仓库并触发 Actions，即可下载编译好的 `rootfs.tar.gz`。首次完整编译约需 1–3 小时。

---

## 一、菜单与插件对应关系

固件采用 LuCI 默认菜单组织，所需菜单项由下列官方/第三方插件提供：

### 状态
| 菜单项 | 来源 |
|---|---|
| 概况 | `luci-mod-status`（内置） |
| 路由 | `luci-mod-status`（内置 Routes） |
| 防火墙（IPv4/IPv6 流量表 "fw4"） | `luci-mod-status` 的 `nftables.js`（fw4 计数器页，内置） |
| 系统日志 | `luci-mod-status`（内置） |
| 系统进程 | `luci-mod-status`（内置） |
| 信道分析 | `luci-mod-status` 的 `channel_analysis.js`（内置） |
| 实时信息 | `luci-mod-status`（内置） |
| 负载均衡 | `luci-app-mwan3` |
| WireGuard | `luci-proto-wireguard` |

### 系统
系统、管理器（管理权）、启动项、计划任务、挂载点、备份升级、重启 → LuCI 内置；
软件包 → `luci-app-package-manager`；磁盘管理 → `luci-app-diskman`；定时重启 → `luci-app-autoreboot`；文件传输 → `luci-app-filetransfer`（独立注入）；TTYD 终端 → `luci-app-ttyd`；Argon 主题设置 → `luci-app-argon-config` + `luci-theme-argon`。

### 服务
| 菜单项 | 来源 |
|---|---|
| AdGuard Home | `luci-app-adguardhome` + `adguardhome`（核心运行时自动下载最新版） |
| OpenClash | `luci-app-openclash`（核心运行时自动下载最新版） |
| UPnP | `luci-app-upnp` + `miniupnpd` |

### 网络
接口、路由、DHCP/DNS、网络诊断、防火墙 → LuCI 内置 / `luci-app-firewall`（fw4）；Turbo ACC 网络加速 → `luci-app-turboacc`（`mufeng05/turboacc`，适配 25.12 + fw4 + 内核 6.12）。

> 「退出」为 LuCI 内置的 Logout 菜单项，随主题自带。

---

## 二、云编译步骤（GitHub Actions）

### 1. 准备仓库
1. 登录 GitHub，新建一个**公开**仓库（例如 `openwrt-25.12-arm64-docker`）。
2. 把本目录的所有文件（含隐藏的 `.github/` 目录）上传到该仓库，保持目录结构不变。
   - 也可用命令：`git init && git add -A && git commit -m init && git remote add origin <你的仓库地址> && git push -u origin main`

### 2. 启用并触发编译
1. 打开仓库网页 → **Actions** 标签 → 若提示禁用，点击绿色按钮 **"I understand my workflows, go ahead and enable them"** 启用。
2. 左侧选择工作流 **"Build OpenWrt 25.12 ARM64 (Docker rootfs.tar.gz)"** → 右侧 **Run workflow** → 是否上传 Release 选 `true` → 点击 **Run workflow**。
3. 等待编译完成（约 1–3 小时）。绿色 ✔ 表示成功；红色 ✘ 点进去看日志。

### 3. 下载固件
任选其一：
- **Releases** 页面：下载 `OpenWrt-25.12.6-arm64-Docker-rootfs.tar.gz` 与 `sha256sum.txt`；
- Actions 运行页面底部的 **Artifacts**：下载 `OpenWrt-25.12.6-arm64-Docker-rootfs`。

校验（Linux/macOS）：
```bash
sha256sum -c sha256sum.txt
```

> 💡 GitHub Actions 免费额度：私有仓库每月 2000 分钟、**公开仓库免费且不限时长**。上面建议建公开仓库。单次编译约 1–3 小时，请留意额度。

---

## 三、Docker 部署（在 ARM64 设备上运行）

### 1. 导入镜像
把 `rootfs.tar.gz` 传到你的 ARM64 设备（arm64/aarch64），执行：
```bash
docker import OpenWrt-25.12.6-arm64-Docker-rootfs.tar.gz openwrt-25.12-arm64:latest
```

### 2. 创建 macvlan 网络（旁路由模式，推荐）
```bash
docker network create -d macvlan \
  --subnet=192.168.1.0/24 \
  --gateway=192.168.1.1 \
  -o parent=eth0 \
  macnet
```
> `parent=eth0` 改成你的物理网卡名（`ip link` 查看）。OpenWrt 将获得 IP `192.168.1.2`。

### 3. 启动容器
```bash
docker run -d --name openwrt --restart unless-stopped \
  --privileged \
  --network macnet \
  --ip 192.168.1.2 \
  openwrt-25.12-arm64:latest /sbin/init
```
（也可用 `docker/docker-compose.yml`：`cd docker && docker compose up -d`）

### 4. 访问管理界面
浏览器打开 **http://192.168.1.2**，账号 `root`，密码 `password`。

---

## 四、默认配置说明

| 项目 | 值 |
|---|---|
| 平台 | armsr/armv8（ARM64） |
| 版本 | OpenWrt 25.12.6（内核 6.12） |
| IPv4 地址 | 192.168.1.2 / 255.255.255.0 |
| IPv4 网关 | 192.168.1.1 |
| DNS | 192.168.1.1、223.5.5.5、119.29.29.29 |
| 账号 / 密码 | root / password |
| 主题 / 语言 | Argon / 简体中文 |
| 时区 | Asia/Shanghai (CST-8) |

相关文件：
- `files/etc/config/network` —— IP / 网关 / DNS
- `files/etc/shadow` —— root 密码（SHA-512 哈希，salt=`openwrt`）
- `files/etc/config/luci` + `files/etc/uci-defaults/99-custom-defaults` —— 主题 / 语言 / 时区
- `config/config.seed` —— 编译包选择
- `config/feeds.conf.default` —— 软件源

如需修改默认密码，用 `openssl passwd -6 -salt <自定义salt> <新密码>` 生成哈希替换 `shadow` 中 root 行。

---

## 五、目录结构

```
.
├── .github/workflows/build.yml      # 云编译工作流（核心）
├── config/
│   ├── config.seed                  # 编译配置（插件选择）
│   └── feeds.conf.default           # 软件源
├── scripts/
│   ├── diy-part1.sh                 # feeds 更新前：注入 Turbo ACC
│   └── diy-part2.sh                 # feeds 安装后：注入 filetransfer / diskman / autoreboot
├── files/etc/                       # 默认配置覆盖层
│   ├── shadow                       # root 密码
│   ├── config/network               # IP / 网关 / DNS
│   ├── config/luci                  # 主题 / 语言
│   └── uci-defaults/99-custom-defaults
├── docker/docker-compose.yml        # Docker 部署示例
└── README.md
```

---

## 六、常见问题

- **编译失败**：多半是第三方源临时不可达。到 Actions 日志看具体报错，重新 Run 一次通常可解决；或在 `config/config.seed` 中临时注释掉最近新增的插件再编译。
- **AdGuard Home / OpenClash 控制面板打不开**：这类插件的核心程序体积大，通常在**首次启动后由插件自动下载最新版核心**，需要设备能联网，请耐心等待并在插件页面手动点「更新核心」。
- **信道分析为空**：armsr/armv8 是无无线卡的通用平台，信道分析依赖无线环境；页面存在但无数据时属正常现象。
- **宿主机无法访问容器 IP**：macvlan 下宿主机与容器默认隔离，可给宿主机也建一个 macvlan 接口，或改用 host 网络模式（此时忽略容器 IP 配置）。
- **版本/插件微调**：想换 OpenWrt 版本改 `build.yml` 里的 `v25.12.6`；增删插件改 `config/config.seed` 后重新编译。
