#!/bin/bash

# Jenkins Docker 部署脚本
# 解决SSH非交互式会话中的Docker keychain问题

# 修复Jenkins SSH会话的PATH问题
# Jenkins SSH会话的PATH通常只有 /usr/bin:/bin:/usr/sbin:/sbin
# 需要添加Docker命令所在的路径
export PATH="/usr/local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# 日志文件配置
LOG_DIR="/Users/bjsttlp324/Desktop/learn/software/jenkins-data/jars/docker/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/deploy-$(date '+%Y%m%d-%H%M%S').log"

# 将所有输出同时写入日志文件和控制台
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================="
echo "开始 Docker 部署流程"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "日志文件: $LOG_FILE"
echo "========================================="

# 记录环境信息
echo ""
echo "【环境信息】"
echo "用户: $(whoami)"
echo "主机: $(hostname)"
echo "Shell: $SHELL"
echo "PATH: $PATH"
echo "DOCKER_CONFIG: ${DOCKER_CONFIG:-未设置}"
echo ""

# 错误处理函数
error_exit() {
    echo ""
    echo "========================================="
    echo "❌ 部署失败！"
    echo "错误发生在: $1"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "详细日志: $LOG_FILE"
    echo "========================================="
    echo ""
    echo "查看完整日志: cat $LOG_FILE"
    echo "查看最后50行: tail -50 $LOG_FILE"
    echo ""
    exit 1
}

# 设置错误时调用error_exit
trap 'error_exit "第$LINENO行"' ERR

echo "========================================="
echo "部署步骤开始"
echo "========================================="

# 1. 确保Docker配置不使用keychain
echo ""
echo "步骤 1/6: 检查Docker配置..."
DOCKER_CONFIG="$HOME/.docker/config.json"

echo "Docker配置文件路径: $DOCKER_CONFIG"
if [ -f "$DOCKER_CONFIG" ]; then
    echo "配置文件存在，内容："
    cat "$DOCKER_CONFIG" | head -20

    # 检查是否使用了desktop凭证存储
    if grep -q '"credsStore".*"desktop"' "$DOCKER_CONFIG"; then
        echo "⚠️  检测到使用desktop凭证存储，正在修改配置..."
        sed -i.bak 's/"credsStore".*"desktop"/"credsStore": ""/' "$DOCKER_CONFIG"
        echo "✓ 已修改Docker配置，禁用keychain存储"
        echo "修改后的配置："
        cat "$DOCKER_CONFIG"
    else
        echo "✓ Docker配置正常"
    fi
else
    echo "⚠️  Docker配置文件不存在，创建默认配置..."
    mkdir -p "$HOME/.docker"
    echo '{"auths":{},"credsStore":""}' > "$DOCKER_CONFIG"
    echo "✓ 已创建配置文件"
fi

# 2. 检查Docker服务
echo ""
echo "步骤 2/6: 检查Docker服务..."
if docker info > /dev/null 2>&1; then
    echo "✓ Docker服务运行正常"
    docker version | grep -E "Version|API version" || true
else
    echo "❌ Docker服务未运行！"
    echo "请启动Docker Desktop"
    error_exit "Docker服务检查"
fi

# 3. 检查工作目录
echo ""
echo "步骤 3/6: 检查工作目录..."
WORK_DIR="/Users/bjsttlp324/Desktop/learn/software/jenkins-data/jars/docker"
echo "目标目录: $WORK_DIR"

if cd "$WORK_DIR"; then
    echo "✓ 切换到工作目录成功"
    echo "当前目录: $(pwd)"
    echo "目录内容："
    ls -lh

    if [ -f "demo-app.jar" ]; then
        echo "✓ demo-app.jar 存在 ($(ls -lh demo-app.jar | awk '{print $5}'))"
    else
        echo "❌ demo-app.jar 不存在！"
        error_exit "JAR文件检查"
    fi
else
    echo "❌ 无法切换到目录: $WORK_DIR"
    error_exit "工作目录检查"
fi

# 4. 预先拉取基础镜像（避免构建时keychain问题）
echo ""
echo "步骤 4/6: 拉取基础镜像..."
BASE_IMAGE="openjdk:26-ea-17-trixie"
echo "基础镜像: $BASE_IMAGE"

# 检查镜像是否已存在
if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^$BASE_IMAGE$"; then
    echo "✓ 基础镜像已存在: $BASE_IMAGE"
else
    echo "正在拉取基础镜像: $BASE_IMAGE"
    if docker pull "$BASE_IMAGE"; then
        echo "✓ 镜像拉取成功"
    else
        echo "❌ 拉取镜像失败"
        error_exit "镜像拉取"
    fi
fi

# 5. 停止旧容器
echo ""
echo "步骤 5/6: 停止旧容器..."
if docker compose down; then
    echo "✓ 旧容器已停止"
else
    echo "⚠️  停止容器时出现警告（可能没有运行中的容器）"
fi

# 6. 构建并启动新容器
echo ""
echo "步骤 6/6: 构建并启动容器..."
echo "执行命令: docker compose up -d --build"

if docker compose up -d --build; then
    echo "✓ 构建和启动命令执行成功"
else
    echo "❌ 构建和启动失败"
    error_exit "Docker Compose构建"
fi

# 7. 验证部署
echo ""
echo "========================================="
echo "验证部署结果"
echo "========================================="

echo "等待容器启动（3秒）..."
sleep 3

echo ""
echo "当前运行的容器："
docker ps -a | grep -E "CONTAINER|demo-app" || echo "未找到demo-app容器"

echo ""
if docker ps | grep -q "demo-app"; then
    echo "✅ 容器启动成功"
    echo ""
    echo "容器详细信息："
    docker ps --filter "name=demo-app" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

    echo ""
    echo "应用日志（最后20行）："
    docker logs demo-app 2>&1 | tail -20

    echo ""
    echo "========================================="
    echo "✅ 部署成功完成！"
    echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "访问地址: http://localhost:8090"
    echo "健康检查: curl http://localhost:8090/actuator/health"
    echo "完整日志: $LOG_FILE"
    echo "========================================="
    exit 0
else
    echo "❌ 容器启动失败"
    echo ""
    echo "容器状态："
    docker ps -a | grep demo-app || echo "容器不存在"

    echo ""
    echo "错误日志（最后50行）："
    docker logs demo-app 2>&1 | tail -50 || echo "无法获取日志"

    echo ""
    echo "Docker Compose状态："
    docker compose ps || true

    echo ""
    echo "========================================="
    echo "❌ 部署失败"
    echo "完整日志: $LOG_FILE"
    echo "========================================="
    error_exit "容器验证"
fi
