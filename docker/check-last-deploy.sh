#!/bin/bash

# 快速查看最后一次部署的日志

LOG_DIR="/Users/bjsttlp324/Desktop/learn/software/jenkins-data/jars/docker/logs"
LATEST_LOG=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo "❌ 没有找到部署日志"
    exit 1
fi

echo "========================================="
echo "最后一次部署日志"
echo "时间: $(basename "$LATEST_LOG" | sed 's/deploy-//;s/.log//')"
echo "文件: $LATEST_LOG"
echo "========================================="
echo ""

# 检查是否成功
if grep -q "✅ 部署成功完成" "$LATEST_LOG"; then
    echo "✅ 部署状态: 成功"
else
    echo "❌ 部署状态: 失败"
fi

echo ""
echo "========== 最后50行日志 =========="
tail -50 "$LATEST_LOG"

echo ""
echo "========================================="
echo "查看完整日志: cat $LATEST_LOG"
echo "查看错误信息: grep -i error $LATEST_LOG"
echo "========================================="
