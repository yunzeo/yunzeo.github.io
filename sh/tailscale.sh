#!/bin/bash

# 检测是否安装了 Docker
if ! command -v docker &> /dev/null; then
    echo "未检测到 Docker，请先安装 Docker 后再运行此脚本。"
    exit 1
fi

# 检测是否使用 docker compose 还是 docker-compose
DOCKER_COMPOSE_CMD=""
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "未检测到 docker compose 或 docker-compose，请先安装后再运行此脚本。"
    exit 1
fi

# 创建 Tailscale 文件夹
mkdir -p /root/tailscale

# 提示用户输入 TS_HOSTNAME 和 TS_AUTHKEY
read -p "请输入 Tailscale 主机名 (TS_HOSTNAME): " TS_HOSTNAME
read -p "请输入 Tailscale 授权密钥 (TS_AUTHKEY): " TS_AUTHKEY

# 创建 docker-compose.yml 文件
cat <<EOF > /root/tailscale/docker-compose.yml
version: '3.8'

services:
  tailscale:
    container_name: tailscale
    restart: always
    network_mode: host
    volumes:
      - /var/lib:/var/lib
      - /dev/net/tun:/dev/net/tun
      - /var/run/tailscale:/var/run/tailscale
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      - TS_ACCEPT_DNS=false
      - TS_AUTH_ONCE=false
      - TS_AUTHKEY=$TS_AUTHKEY
      - TS_DEST_IP=
      - TS_KUBE_SECRET=tailscale
      - TS_HOSTNAME=$TS_HOSTNAME
      - TS_OUTBOUND_HTTP_PROXY_LISTEN=
      - TS_ROUTES=192.168.3.0/24
      - TS_SOCKET=/var/run/tailscale/tailscaled.sock
      - TS_SOCKS5_SERVER=
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_USERSPACE=true
      - TS_EXTRA_ARGS=--advertise-exit-node
    image: tailscale/tailscale:latest
EOF

# 启动 Docker 服务
$DOCKER_COMPOSE_CMD -f /root/tailscale/docker-compose.yml up -d
