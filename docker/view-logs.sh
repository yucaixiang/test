#!/bin/bash

# 部署日志查看脚本
# 用于查看Jenkins部署的详细日志

LOG_DIR="/Users/bjsttlp324/Desktop/learn/software/jenkins-data/jars/docker/logs"

echo "========================================="
echo "部署日志查看工具"
echo "========================================="

# 检查日志目录是否存在
if [ ! -d "$LOG_DIR" ]; then
    echo "错误: 日志目录不存在: $LOG_DIR"
    exit 1
fi

# 列出所有日志文件
echo ""
echo "可用的日志文件："
ls -lht "$LOG_DIR"/*.log 2>/dev/null | head -10 || {
    echo "没有找到日志文件"
    exit 1
}

# 获取最新的日志文件
LATEST_LOG=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)

if [ -z "$LATEST_LOG" ]; then
    echo ""
    echo "没有找到日志文件"
    exit 1
fi

echo ""
echo "========================================="
echo "最新日志文件: $LATEST_LOG"
echo "创建时间: $(stat -f "%Sm" "$LATEST_LOG")"
echo "文件大小: $(du -h "$LATEST_LOG" | cut -f1)"
echo "========================================="

# 提供操作选项
echo ""
echo "选择操作："
echo "1) 查看完整日志"
echo "2) 查看最后50行"
echo "3) 查看最后100行"
echo "4) 实时跟踪日志（如果正在部署）"
echo "5) 搜索错误信息"
echo "6) 退出"
echo ""

read -p "请输入选项 (1-6): " choice

case $choice in
    1)
        echo ""
        echo "========== 完整日志 =========="
        cat "$LATEST_LOG"
        ;;
    2)
        echo ""
        echo "========== 最后50行 =========="
        tail -50 "$LATEST_LOG"
        ;;
    3)
        echo ""
        echo "========== 最后100行 =========="
        tail -100 "$LATEST_LOG"
        ;;
    4)
        echo ""
        echo "========== 实时跟踪（按Ctrl+C退出） =========="
        tail -f "$LATEST_LOG"
        ;;
    5)
        echo ""
        echo "========== 错误信息 =========="
        grep -i -E "error|failed|fatal|❌|失败" "$LATEST_LOG" || echo "未找到错误信息"
        ;;
    6)
        echo "退出"
        exit 0
        ;;
    *)
        echo "无效选项"
        exit 1
        ;;
esac

echo ""
echo "========================================="
echo "日志文件路径: $LATEST_LOG"
echo "========================================="
