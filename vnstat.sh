#!/bin/bash

BOT_TOKEN="XXXX"
CHAT_ID="-XXXX"
HOSTNAME=$(hostname)

# 自动识别网卡接口（排除 lo）
INTERFACE=$(ip -o -4 addr show | awk '!/ lo / {print $2}' | head -n1)
if [[ -z "$INTERFACE" ]]; then
  echo "❌ 无法识别网卡接口"
  exit 1
fi

# 如果 vnstat 未安装，则尝试安装
if ! command -v vnstat &>/dev/null; then
  echo "🔧 安装 vnstat 中..."
  apt update -y && apt install -y vnstat
fi

# 确保 vnstat 数据库已存在
vnstat --add -i "$INTERFACE" 2>/dev/null || true
systemctl restart vnstat || echo "⚠️ 重启 vnstat 服务失败，请手动重启"
sleep 3

# 获取当前年月
CUR_MONTH=$(date +%Y-%m)

# 获取当前月份流量数据
LINE=$(vnstat -m -i "$INTERFACE" | grep "$CUR_MONTH")
if [[ -z "$LINE" ]]; then
  echo "❌ 未找到当前月份流量数据"
  exit 1
fi

# 解析 RX、TX 和 TOTAL（原始版本保留为注释）
# RX=$(echo "$LINE" | awk '{print $2}')
# RX_UNIT=$(echo "$LINE" | awk '{print $3}')
TX=$(echo "$LINE" | awk '{print $5}')
TX_UNIT=$(echo "$LINE" | awk '{print $6}')
# TOTAL=$(echo "$LINE" | awk '{print $8}')
# TOTAL_UNIT=$(echo "$LINE" | awk '{print $9}')

TEXT="AWS010
当前月份: $CUR_MONTH
#接收流量 (RX): $RX $RX_UNIT
发送流量 (TX): $TX $TX_UNIT
总计流量: $TX $TX_UNIT"

# 发送 Telegram 消息
curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
  -d chat_id="$CHAT_ID" \
  -d text="$TEXT"
