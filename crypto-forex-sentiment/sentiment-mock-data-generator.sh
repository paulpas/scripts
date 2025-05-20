#!/usr/bin/env bash

# Script to generate 3 months of simulated sentiment data at 4-hour intervals

# Create data directory if it doesn't exist
mkdir -p data
DATA_DIR="data"
CRYPTO_DATA="$DATA_DIR/crypto_sentiment_data.txt"
FOREX_DATA="$DATA_DIR/forex_sentiment_data.txt"
COMBINED_DATA="$DATA_DIR/combined_sentiment_data.txt"

# Clear any existing data
rm -f "$CRYPTO_DATA" "$FOREX_DATA" "$COMBINED_DATA"

# Function to generate a random sentiment value within bounds
# Args: $1 = base value, $2 = max delta
get_random_sentiment() {
  local base=$1
  local max_delta=$2
  local delta=$(( (RANDOM % (2 * max_delta + 1)) - max_delta ))
  local value=$((base + delta))
  
  # Ensure the value stays within 0-100 range
  if [ $value -lt 0 ]; then
    value=0
  elif [ $value -gt 100 ]; then
    value=100
  fi
  
  echo $value
}

# Function to generate a new set of sentiment values based on previous values
# Args: $1 = previous sentiment JSON, $2 = type, $3 = timestamp
generate_new_sentiment() {
  local prev_json=$1
  local type=$2
  local timestamp=$3
  local max_delta=5  # Maximum change between readings
  
  # Extract previous values
  local price_forecasts=$(echo "$prev_json" | jq -r '."Price Forecasts"')
  local bull_sentiment=$(echo "$prev_json" | jq -r '."Bull Sentiment"')
  local bear_sentiment=$(echo "$prev_json" | jq -r '."Bear Sentiment"')
  local regulation_sentiment=$(echo "$prev_json" | jq -r '."Regulation Sentiment"')
  local etf_sentiment=$(echo "$prev_json" | jq -r '."ETF Sentiment"')
  local whale_sentiment=$(echo "$prev_json" | jq -r '."Whale Sentiment"')
  local retail_sentiment=$(echo "$prev_json" | jq -r '."Retail Sentiment"')
  local adoption=$(echo "$prev_json" | jq -r '."Adoption"')
  local summary=$(echo "$prev_json" | jq -r '."Summary of Entire Market"')
  
  # Generate new values
  local new_price_forecasts=$(get_random_sentiment $price_forecasts $max_delta)
  local new_bull_sentiment=$(get_random_sentiment $bull_sentiment $max_delta)
  local new_bear_sentiment=$(get_random_sentiment $bear_sentiment $max_delta)
  local new_regulation_sentiment=$(get_random_sentiment $regulation_sentiment $max_delta)
  local new_etf_sentiment=$(get_random_sentiment $etf_sentiment $max_delta)
  local new_whale_sentiment=$(get_random_sentiment $whale_sentiment $max_delta)
  local new_retail_sentiment=$(get_random_sentiment $retail_sentiment $max_delta)
  local new_adoption=$(get_random_sentiment $adoption $max_delta)
  
  # Calculate new summary as average of all other values
  local new_summary=$(( (new_price_forecasts + new_bull_sentiment + new_bear_sentiment + 
                         new_regulation_sentiment + new_etf_sentiment + new_whale_sentiment + 
                         new_retail_sentiment + new_adoption) / 8 ))
  
  # Create new JSON
  jq -n \
    --arg type "$type" \
    --arg timestamp "$timestamp" \
    --argjson price "$new_price_forecasts" \
    --argjson bull "$new_bull_sentiment" \
    --argjson bear "$new_bear_sentiment" \
    --argjson reg "$new_regulation_sentiment" \
    --argjson etf "$new_etf_sentiment" \
    --argjson whale "$new_whale_sentiment" \
    --argjson retail "$new_retail_sentiment" \
    --argjson adopt "$new_adoption" \
    --argjson summary "$new_summary" \
    '{
      "Type": $type,
      "Timestamp": $timestamp,
      "Price Forecasts": $price,
      "Bull Sentiment": $bull,
      "Bear Sentiment": $bear,
      "Regulation Sentiment": $reg,
      "ETF Sentiment": $etf,
      "Whale Sentiment": $whale,
      "Retail Sentiment": $retail,
      "Adoption": $adopt,
      "Summary of Entire Market": $summary
    }'
}

# Generate initial sentiment values for Crypto
initial_crypto_sentiment=$(jq -n '{
  "Price Forecasts": 60,
  "Bull Sentiment": 65,
  "Bear Sentiment": 40,
  "Regulation Sentiment": 50,
  "ETF Sentiment": 70,
  "Whale Sentiment": 55,
  "Retail Sentiment": 62,
  "Adoption": 58,
  "Summary of Entire Market": 57
}')

# Generate initial sentiment values for Forex
initial_forex_sentiment=$(jq -n '{
  "Price Forecasts": 55,
  "Bull Sentiment": 58,
  "Bear Sentiment": 45,
  "Regulation Sentiment": 60,
  "ETF Sentiment": 52,
  "Whale Sentiment": 50,
  "Retail Sentiment": 56,
  "Adoption": 48,
  "Summary of Entire Market": 53
}')

# Copy the initial values to use as the "previous" values for iteration
crypto_sentiment="$initial_crypto_sentiment"
forex_sentiment="$initial_forex_sentiment"

# Calculate number of 4-hour intervals in 3 months (approximately 90 days)
# 6 intervals per day × 90 days = 540 intervals
intervals=540

echo "Generating 3 months of simulated data with 4-hour intervals..."

# Get start date (3 months ago) - format to midnight for consistent intervals
start_date=$(date -d "3 months ago" +"%Y-%m-%d 00:00:00")
echo "Starting from: $start_date"

# Generate data points
for ((day=0; day<90; day++)); do
  # Calculate the current day using your preferred date format
  current_date=$(date -d "$(date -d "$start_date") + $day days" +"%Y-%m-%d")
  
  # For each day, generate data at 4-hour intervals
  for hour in 0 4 8 12 16 20; do
    # Format the timestamp
    hour_fmt=$(printf "%02d:00:00" $hour)
    timestamp="${current_date} ${hour_fmt}"
    
    # Generate new sentiment values
    crypto_sentiment=$(generate_new_sentiment "$crypto_sentiment" "Crypto" "$timestamp")
    forex_sentiment=$(generate_new_sentiment "$forex_sentiment" "Forex" "$timestamp")
    
    # Save to data files
    echo "$crypto_sentiment" >> "$CRYPTO_DATA"
    echo "$crypto_sentiment" >> "$COMBINED_DATA"
    echo "$forex_sentiment" >> "$FOREX_DATA"
    echo "$forex_sentiment" >> "$COMBINED_DATA"
  done
  
  # Display progress every 10 days
  if ((day % 10 == 0)); then
    echo "Progress: $day/90 days generated..."
  fi
done

echo "Data generation complete!"
echo "Generated $(wc -l < "$CRYPTO_DATA") Crypto data points"
echo "Generated $(wc -l < "$FOREX_DATA") Forex data points"
echo "Generated $(wc -l < "$COMBINED_DATA") Combined data points"
echo "Data files created in $DATA_DIR/"
