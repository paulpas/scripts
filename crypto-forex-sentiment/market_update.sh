#!/usr/bin/env bash

# Define the webhook URL
WEBHOOK_URL='https://discord.com/api/webhooks/0000000000000000000/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'

# Define the directory containing charts
CHART_DIR="/data/sentiment-data"

CRYPTO_DATE=$(date --utc)

# Get Bitcoin analysis
BTC_ANALYSIS=$(head -n 60 /data/git/ft_userdata/user_data/data/kucoin/BTC_USDT-4h.json | mods --no-cache --quiet "You are a crypto currency master social influencer.  In 1800 letters or less, this is non-negotiable, based on this candlestick data (open, high, low, close, volume) for Bitcoin, what are your thoughts on if it is going to do up or down for the past 24 hours, and 5 days, keep in mind the current price is $(curl -s "https://data-api.coindesk.com/index/cc/v1/historical/days?market=cadli&instrument=BTC-USD&limit=1&aggregate=1&fill=true&apply_mapping=true&response_format=JSON" | jq '.Data[0].CLOSE') to extrapolate current activity and a few hours into the future.  Make the output format good for a discord post, including sensational emojis and bold text for effect" | grep -v '```')

# Step 1: Send crypto sentiment message with Bitcoin analysis - using jq to properly escape
CRYPTO_MSG=$(jq -n \
  --arg date "$CRYPTO_DATE" \
  --arg analysis "$BTC_ANALYSIS" \
  '{content: "**Crypto Market Analysis** (Updated: \($date))\n Analysis:**\n\($analysis)"}')

curl -H "Content-Type: application/json" \
     -d "$CRYPTO_MSG" \
     -X POST "$WEBHOOK_URL"
