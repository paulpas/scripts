#!/usr/bin/env bash

# Define the webhook URL
WEBHOOK_URL=''

# Define the directory containing charts
CHART_DIR="/data/sentiment-data"

# Upload crypto chart
CRYPTO_FILE="${CHART_DIR}/crypto_sentiment_chart.png"
CRYPTO_DATE=$(date -r "$CRYPTO_FILE" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")
curl -s -F "payload_json={\"content\":\"Crypto Market Sentiment (Updated: $CRYPTO_DATE)\\nScale: 0-100 (Below 50 = Bearish, Above 50 = Bullish)\"}" \
     -F "file=@$CRYPTO_FILE" \
     -H "Content-Type: multipart/form-data" \
     -X POST "$WEBHOOK_URL"

# Wait to avoid rate limiting
#sleep 2
#
## Upload forex chart
#FOREX_FILE="${CHART_DIR}/forex_sentiment_chart.png"
#FOREX_DATE=$(date -r "$FOREX_FILE" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")
#curl -s -F "payload_json={\"content\":\"Forex Market Sentiment (Updated: $FOREX_DATE)\\nScale: 0-100 (Below 50 = Bearish, Above 50 = Bullish)\"}" \
#     -F "file=@$FOREX_FILE" \
#     -H "Content-Type: multipart/form-data" \
#     -X POST "$WEBHOOK_URL"
#
## Wait to avoid rate limiting
#sleep 2
#
## Upload combined chart
##COMBINED_FILE="${CHART_DIR}/combined_sentiment_chart.png"
#COMBINED_DATE=$(date -r "$COMBINED_FILE" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")
#curl -s -F "payload_json={\"content\":\"Combined Market Sentiment (Updated: $COMBINED_DATE)\\nScale: 0-100 (Below 50 = Bearish, Above 50 = Bullish)\"}" \
#     -F "file=@$COMBINED_FILE" \
#     -H "Content-Type: multipart/form-data" \
#     -X POST "$WEBHOOK_URL"
