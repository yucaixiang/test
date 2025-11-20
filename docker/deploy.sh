#!/bin/bash

# Jenkins Docker 部署脚本
# 解决SSH非交互式会话中的Docker keychain问题

set -e  # 遇到错误立即退出

echo "========================================="
echo "开始 Docker 部署流程"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="

# 1. 确保Docker配置不使用keychain
echo "步骤 1/5: 检查Docker配置..."
DOCKER_CONFIG="$HOME/.docker/config.json"

if [ -f "$DOCKER_CONFIG" ]; then
    # 检查是否使用了desktop凭证存储
    if grep -q '"credsStore".*"desktop"' "$DOCKER_CONFIG"; then
        echo "警告: 检测到使用desktop凭证存储，正在修改配置..."
        sed -i.bak 's/"credsStore".*"desktop"/"credsStore": ""/' "$DOCKER_CONFIG"
        echo "已修改Docker配置，禁用keychain存储"
    else
        echo "Docker配置正常"
    fi
else
    echo "警告: Docker配置文件不存在，创建默认配置..."
    mkdir -p "$HOME/.docker"
    echo '{"auths":{},"credsStore":""}' > "$DOCKER_CONFIG"
fi

# 2. 检查工作目录
echo "步骤 2/5: 检查工作目录..."
WORK_DIR="/Users/bjsttlp324/Desktop/learn/software/jenkins-data/jars/docker"
cd "$WORK_DIR" || exit 1
echo "当前目录: $(pwd)"
ls -lh demo-app.jar 2>/dev/null || echo "警告: demo-app.jar 不存在"

# 3. 预先拉取基础镜像（避免构建时keychain问题）
echo "步骤 3/5: 拉取基础镜像..."
BASE_IMAGE="openjdk:26-ea-17-trixie"

# 检查镜像是否已存在
if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$BASE_IMAGE$"; then
    echo "基础镜像已存在: $BASE_IMAGE"
else
    echo "正在拉取基础镜像: $BASE_IMAGE"
    docker pull "$BASE_IMAGE" || {
        echo "错误: 拉取镜像失败"
        exit 1
    }
fi

# 4. 停止旧容器
echo "步骤 4/5: 停止旧容器..."
docker compose down || echo "没有运行中的容器"

# 5. 构建并启动新容器
echo "步骤 5/5: 构建并启动容器..."
docker compose up -d --build

# 6. 验证部署
echo ""
echo "========================================="
echo "部署完成，验证容器状态..."
echo "========================================="
sleep 3  # 等待容器启动

if docker ps | grep -q "demo-app"; then
    echo "✓ 容器启动成功"
    docker ps | grep demo-app
    echo ""
    echo "查看应用日志（最后10行）："
    docker logs demo-app 2>&1 | tail -10
    echo ""
    echo "========================================="
    echo "部署成功完成！"
    echo "访问地址: http://localhost:8090"
    echo "========================================="
    exit 0
else
    echo "✗ 容器启动失败"
    echo "查看错误日志："
    docker logs demo-app 2>&1 | tail -20
    exit 1
fi
