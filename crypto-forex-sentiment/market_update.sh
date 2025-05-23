#!/usr/bin/env bash

set -o pipefail

# Define the webhook URL
WEBHOOK_URL='https://discord.com/api/webhooks/1374475141655826472/PKgV0w5NhNd8WWYlgeNAuhI_HcAvi1VKM6sN90nl3XDI-dU-lkb90HJkvImZzwePaZ-r'

# Define the directory containing charts
CHART_DIR="/data/sentiment-data"

CRYPTO_DATE=$(date --utc)

# OpenAI API details
OPENAI_API_KEY="" # Replace with your actual API key
OPENAI_MODEL="gpt-4.1-nano" #"gpt-4o" # You can change to a different model if needed

# Maximum retries
MAX_RETRIES=10
# Initial character limit, Discord max is 2000
CHAR_LIMIT=2000

# The number of time units to look back, if hourly, then 24 is 1 day. If daily, 7 is weekly, etc.
TIME_SCALE="1 minute "
CANDLE_TIME_UNIT=1m
CANDLE_UNITS=2880

# File to store predictions
PREDICTIONS_LOG="$CHART_DIR/prediction_history.json"

# Temporary files
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Ensure predictions log exists with valid JSON
if [ ! -f "$PREDICTIONS_LOG" ]; then
    echo '[]' > "$PREDICTIONS_LOG"
fi

# Function to validate JSON file
validate_json() {
    local file="$1"
    if ! jq '.' "$file" > /dev/null 2>&1; then
        echo "Invalid JSON in $file, initializing with empty array"
        echo '[]' > "$file"
    fi
}

# Validate predictions log
validate_json "$PREDICTIONS_LOG"

send_message() {
    local analysis="$1"
    local prediction="$2"
    local accuracy_data="$3"
    local msg

    # Format the accuracy data for display
    local accuracy_info=""
    if [[ -n "$accuracy_data" ]]; then
        local total_evaluated=$(echo "$accuracy_data" | jq '.total_evaluated')
        local correct_predictions=$(echo "$accuracy_data" | jq '.correct_predictions')
        local accuracy_percentage=$(echo "$accuracy_data" | jq '.accuracy_percentage')
        
        if [[ "$total_evaluated" -gt 0 ]]; then
            accuracy_info="**Sloppy Toppy's Prediction Record:** ${correct_predictions}/${total_evaluated} correct (${accuracy_percentage}% accuracy)"
        fi
    fi

    # Format the prediction with proper formatting
    local prediction_info=""
    if [[ -n "$prediction" && "$prediction" != "0" ]]; then
        local target_time=$(date -d "+4 hours" "+%H:%M UTC %d %b %Y")
        prediction_info="**🔮 PRICE PREDICTION (${target_time}):** $prediction USD"
    fi

    # Build the final message
    local content="**Crypto Market Analysis** (Updated: $CRYPTO_DATE)\n"
    if [[ -n "$prediction_info" ]]; then
        content="${content}${prediction_info}\n"
    fi
    if [[ -n "$accuracy_info" ]]; then
        content="${content}${accuracy_info}\n"
    fi
    content="${content} Analysis:**\n${analysis}"

    msg=$(jq -n --arg content "$content" '{content: $content}')

    # Send message and capture response
    response=$(curl -s -w "%{http_code}" -H "Content-Type: application/json" \
         -d "$msg" \
         -X POST "$WEBHOOK_URL")

    http_code=${response: -3}

    # Return 0 if successful, 1 if error
    if [[ "$http_code" == "204" ]]; then
        echo "Message sent successfully"
        return 0
    else
        echo "Error sending message, HTTP code: $http_code"
        echo "Response: ${response:0:${#response}-3}"
        return 1
    fi
}

extract_hourly_data() {
    local file_path="$1"
    local hours_back="$2"
    local output_file="${3:-$TEMP_DIR/extracted_btc_data.json}"

    if [[ ! -f "$file_path" ]]; then
        echo "Error: File not found at $file_path" >&2
        return 1
    fi

    # Get total number of data points in the file
    local total_points=$(jq 'length' "$file_path")

    # Calculate how many entries to take (minimum of hours_back or all available entries)
    local entries_to_take=$((hours_back < total_points ? hours_back : total_points))

    # Extract the specified number of most recent entries
    jq ".[-${entries_to_take}:]" "$file_path" > "$output_file"

    # Return the path to the output file
    echo "$output_file"
}

create_api_payload() {
    local system_message="$1"
    local user_message="$2"
    local max_tokens="$3"
    local model="$4"
    local output_file="$5"
    
    # Create the JSON payload file for OpenAI API
    cat > "$output_file" << EOL
{
  "model": "$model",
  "messages": [
    {
      "role": "system",
      "content": "$system_message"
    },
    {
      "role": "user",
      "content": "$user_message"
    }
  ],
  "max_tokens": $max_tokens,
  "temperature": 0.9
}
EOL
}

# Extract price prediction from LLM response
extract_price_prediction() {
    local analysis="$1"
    local prediction_file="$TEMP_DIR/prediction_extraction.json"
    
    # Create a payload for the extraction
    cat > "$prediction_file" << EOL
{
  "model": "$OPENAI_MODEL",
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful assistant that extracts numerical Bitcoin price predictions from text. Only return the predicted price as a number with no other text or formatting."
    },
    {
      "role": "user",
      "content": "Extract the Bitcoin price prediction mentioned for the next 4 hours from this analysis. Only return the numerical price value (like 65432.10) with no other text:\n\n$analysis"
    }
  ],
  "max_tokens": 20,
  "temperature": 0
}
EOL

    # Call OpenAI API to extract prediction
    local response=$(curl -s https://api.openai.com/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d @"$prediction_file")

    # Extract the predicted price
    local extracted_price=$(echo "$response" | jq -r '.choices[0].message.content' | grep -o -E '[0-9]+(\.[0-9]+)?')
    
    # If empty or not a number, return 0
    if [[ -z "$extracted_price" ]] || ! [[ "$extracted_price" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        echo "0"
    else
        echo "$extracted_price"
    fi
}

# Save prediction to history
save_prediction() {
    local predicted_price="$1"
    local current_price="$2"
    local timestamp=$(date --utc +%s)
    local formatted_time=$(date --utc -d "@$timestamp" "+%Y-%m-%d %H:%M:%S UTC")
    local target_time=$((timestamp + 4*3600))  # 4 hours in the future
    local formatted_target=$(date --utc -d "@$target_time" "+%Y-%m-%d %H:%M:%S UTC")
    
    # Create temporary JSON with new prediction
    local new_prediction=$(jq -n \
      --arg timestamp "$timestamp" \
      --arg formatted_time "$formatted_time" \
      --arg target_time "$target_time" \
      --arg formatted_target "$formatted_target" \
      --arg current_price "$current_price" \
      --arg predicted_price "$predicted_price" \
      '{
        timestamp: ($timestamp | tonumber),
        formatted_time: $formatted_time,
        target_time: ($target_time | tonumber),
        formatted_target: $formatted_target,
        current_price: ($current_price | tonumber),
        predicted_price: ($predicted_price | tonumber),
        actual_price: null,
        was_correct: null
      }')
    
    # Append to predictions log
    jq --argjson new_pred "$new_prediction" '. += [$new_pred]' "$PREDICTIONS_LOG" > "$TEMP_DIR/updated_predictions.json"
    mv "$TEMP_DIR/updated_predictions.json" "$PREDICTIONS_LOG"
}

# Update past predictions with actual prices
update_past_predictions() {
    local current_btc_price="$1"
    local now=$(date --utc +%s)
    
    # Create a temp file for updating
    local temp_file="$TEMP_DIR/updating_predictions.json"
    
    # Read each prediction that needs updating
    jq -c --arg now "$now" --arg price "$current_btc_price" '
      [.[] | select(.actual_price == null and .target_time < ($now | tonumber))]
    ' "$PREDICTIONS_LOG" > "$TEMP_DIR/predictions_to_update.json"
    
    # Process each prediction that needs updating
    local updated=false
    
    # For each prediction that needs updating, get the historical price
    while read -r prediction; do
        if [ -z "$prediction" ] || [ "$prediction" = "[]" ]; then
            continue
        fi
        
        local target_time=$(echo "$prediction" | jq -r '.target_time')
        local target_date=$(date -u -d "@$target_time" "+%Y-%m-%d")
        
        # Get historical price at the target time
        # Using Coindesk API to get historical price data
        local historical_url="https://data-api.coindesk.com/index/cc/v1/historical/days?market=cadli&instrument=BTC-USD&start_date=${target_date}&end_date=${target_date}&limit=1&aggregate=1&fill=true&apply_mapping=true&response_format=JSON"
        local historical_price=$(curl -s "$historical_url" | jq '.Data[0].CLOSE')
        
        if [ -z "$historical_price" ] || [ "$historical_price" = "null" ]; then
            # If we can't get historical price, use current price as fallback
            historical_price=$current_btc_price
        fi
        
        # Update the prediction with actual price
        local target_time_num=$(echo "$prediction" | jq '.target_time')
        local predicted_price=$(echo "$prediction" | jq '.predicted_price')
        
        # Calculate if prediction was correct (within 2% of actual)
        local was_correct=$(echo "$predicted_price $historical_price" | awk '{
            if ($2 > $1 * 0.98 && $2 < $1 * 1.02) print "true"; else print "false"
        }')
        
        # Update the prediction in the file
        jq --arg time "$target_time_num" --arg price "$historical_price" --arg correct "$was_correct" '
          map(if (.target_time | tostring) == $time then 
            . + {actual_price: ($price | tonumber), was_correct: ($correct == "true")} 
          else 
            . 
          end)
        ' "$PREDICTIONS_LOG" > "$temp_file"
        
        # Replace the predictions log with updated data
        mv "$temp_file" "$PREDICTIONS_LOG"
        updated=true
    done < <(jq -c '.[]' "$TEMP_DIR/predictions_to_update.json")
    
    # If nothing was updated, just touch the file to ensure it exists
    if [ "$updated" = false ]; then
        touch "$PREDICTIONS_LOG"
    fi
}

# Get the recent prediction accuracy information
get_prediction_accuracy() {
    local accuracy_data
    
    # Count total predictions with results and how many were correct
    accuracy_data=$(jq '
      [.[] | select(.was_correct != null)] as $evaluated |
      [.[] | select(.was_correct == true)] as $correct |
      {
        total_evaluated: ($evaluated | length),
        correct_predictions: ($correct | length),
        accuracy_percentage: (if ($evaluated | length) > 0 then 
                               (($correct | length) / ($evaluated | length) * 100) | round 
                             else 0 end),
        recent_predictions: [.[] | select(.was_correct != null) | {
          time: .formatted_time,
          current_price: .current_price,
          predicted_price: .predicted_price,
          actual_price: .actual_price,
          was_correct: .was_correct
        } | select(.time != null)][-5:] # Last 5 evaluated predictions
      }
    ' "$PREDICTIONS_LOG")
    
    echo "$accuracy_data"
}

generate_analysis() {
    local char_limit=$1
    local hours_back="${2:-24}"  # Default to 24 hours if not specified

    # Get current BTC price
    BTC_PRICE=$(curl -s "https://data-api.coindesk.com/index/cc/v1/historical/days?market=cadli&instrument=BTC-USD&limit=1&aggregate=1&fill=true&apply_mapping=true&response_format=JSON" | jq '.Data[0].CLOSE')

    # Update past predictions with actual prices
    update_past_predictions "$BTC_PRICE"
    
    # Get prediction accuracy data
    local accuracy_data=$(get_prediction_accuracy)
    local total_evaluated=$(echo "$accuracy_data" | jq '.total_evaluated')
    local correct_predictions=$(echo "$accuracy_data" | jq '.correct_predictions')
    local accuracy_percentage=$(echo "$accuracy_data" | jq '.accuracy_percentage')
    local recent_predictions=$(echo "$accuracy_data" | jq -c '.recent_predictions')

    # Extract the specified hours of data
    local data_file=$(extract_hourly_data "/data/git/ft_userdata/user_data/data/kucoin/BTC_USDT-${CANDLE_TIME_UNIT}.json" "$hours_back")
    
    # Create a simpler representation of the JSON data (for easier inclusion in the prompt)
    local simplified_data_file="$TEMP_DIR/simplified_data.json"
    jq -c '.' "$data_file" > "$simplified_data_file"
    
    # Build the system message
    local system_message="You are a sexually perverted crypto currency master social influencer who loves to speak technical analysis named Sloppy Toppy who speaks with detailed degen memelord perverted sexual mentions of fellatio slang."
    
    # Build the user message with simplified JSON reference and prediction history
    local user_message_file="$TEMP_DIR/user_message.txt"
    cat > "$user_message_file" << EOL
Based on the following ${TIME_SCALE} candlestick data (open, high, low, close, volume) for Bitcoin, what are your thoughts on if it is going to do up or down based on the past $hours_back ${TIME_SCALE} of data? Keep in mind the current price is $BTC_PRICE to extrapolate current activity for the next 2-4 hours into the future.

Make the output format good for a discord post, including sensational degen emojis and eggplants and water splashes and bold text for effect. Convert UNIX timestamps to standard time for human readability. Always include the timezone in any mentioned times and dates. At the end always have a section of most probable BTC price in the next 4 hours.

Your reply must be EQUAL to or UNDER ${char_limit} characters. Only consider candle data no more than 2 days old from $(date --utc).

IMPORTANT - Here's your prediction accuracy history:
- Total predictions evaluated: $total_evaluated
- Correct predictions: $correct_predictions
- Accuracy rate: ${accuracy_percentage}%

Recent prediction results:
$recent_predictions

Based on these past predictions, reflect on your accuracy and adjust your prediction methodology accordingly. Your prediction should be a specific price value for BTC in 4 hours from now. Make the price prediction very clear and easily extractable from your text.

Here's the Bitcoin candlestick data:
$(cat "$simplified_data_file")
EOL

    # Create payload file
    local payload_file="$TEMP_DIR/openai_payload.json"
    local user_message=$(cat "$user_message_file")
    
    # Escape special characters for JSON
    system_message=$(echo "$system_message" | sed 's/"/\\"/g')
    user_message=$(echo "$user_message" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    
    # Create API payload file
    create_api_payload "$system_message" "$user_message" "$char_limit" "$OPENAI_MODEL" "$payload_file"

    # Call OpenAI API
    local response=$(curl -s https://api.openai.com/v1/chat/completions \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $OPENAI_API_KEY" \
      -d @"$payload_file")

    # Extract the content from the response
    local analysis=$(echo "$response" | jq -r '.choices[0].message.content')

    # If we got an error in the response, print it
    if echo "$response" | jq -e '.error' > /dev/null; then
        echo "Error from OpenAI API:" >&2
        echo "$response" | jq '.error' >&2
    fi

    # Extract and save the price prediction
    local predicted_price=$(extract_price_prediction "$analysis")
    if [[ "$predicted_price" != "0" ]]; then
        echo "Extracted price prediction: $predicted_price" >&2
        save_prediction "$predicted_price" "$BTC_PRICE"
    else
        echo "Could not extract a valid price prediction" >&2
    fi

    # Return both analysis and prediction
    echo -e "$analysis\n__PRICE_PREDICTION__$predicted_price\n__ACCURACY_DATA__$accuracy_data"
}

# Loop until message sends successfully or max retries reached
retry_count=0
success=false

while [[ $retry_count -lt $MAX_RETRIES && $success == false ]]; do
    echo "Attempt $((retry_count+1)) with character limit $CHAR_LIMIT"

    # Generate analysis with current character limit
    ANALYSIS_OUTPUT=$(generate_analysis $CHAR_LIMIT $CANDLE_UNITS)
    
    # Extract parts using pattern matching
    BTC_ANALYSIS=$(echo "$ANALYSIS_OUTPUT" | sed -n '1,/__PRICE_PREDICTION__/p' | sed 's/__PRICE_PREDICTION__.*$//')
    PRICE_PREDICTION=$(echo "$ANALYSIS_OUTPUT" | sed -n 's/.*__PRICE_PREDICTION__$.*$__ACCURACY_DATA__.*/\1/p')
    ACCURACY_DATA=$(echo "$ANALYSIS_OUTPUT" | sed -n 's/.*__ACCURACY_DATA__$.*$/\1/p')
    
    # Check actual length for debugging
    actual_length=${#BTC_ANALYSIS}
    echo "Generated analysis length: $actual_length characters"
    echo "Price prediction: $PRICE_PREDICTION"

    # Format the prediction for display (to ensure it has 2 decimal places if needed)
    if [[ -n "$PRICE_PREDICTION" && "$PRICE_PREDICTION" != "0" ]]; then
        FORMATTED_PREDICTION=$(printf "%.2f" "$PRICE_PREDICTION")
    else
        FORMATTED_PREDICTION=""
    fi

    # Try to send message with the prediction included
    if send_message "$BTC_ANALYSIS" "$FORMATTED_PREDICTION" "$ACCURACY_DATA"; then
        success=true
    else
        # Decrease character limit by 1% for next attempt
        CHAR_LIMIT=$((CHAR_LIMIT * 99 / 100))
        retry_count=$((retry_count + 1))
        echo "Retrying with reduced limit: $CHAR_LIMIT characters"
        sleep 2 # Brief pause before retrying
    fi
done

if [[ $success == false ]]; then
    echo "Failed to send message after $MAX_RETRIES attempts"
    exit 1
fi
