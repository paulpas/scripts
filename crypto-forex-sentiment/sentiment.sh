#!/usr/bin/env bash

# Source user profile to get environment variables
source $HOME/.profile
source $HOME/.bashrc  # Also source bashrc if needed

# Define feed URLs
CRYPTO_FEEDS="https://www.coindesk.com/arc/outboundfeeds/rss/ \
https://cointelegraph.com/rss \
https://bitcoinist.com/feed/ \
https://www.newsbtc.com/feed/ \
https://cryptopotato.com/feed/ \
https://99bitcoins.com/news/feed/ \
https://cryptobriefing.com/feed/ \
https://crypto.news/tag/cryptocurrency/ \
https://www.fxempire.com/api/v1/en/articles/rss/forecasts"

FOREX_FEEDS="https://feeds.content.dowjones.io/public/rss/WSJcomUSBusiness \
https://feeds.content.dowjones.io/public/rss/latestnewsrealestate \
https://feeds.content.dowjones.io/public/rss/RSSWorldNews \
https://feeds.content.dowjones.io/public/rss/socialpoliticsfeed"

# Define prompt and schema
PROMPT="what is the general sentiment of the markts from this rss feeds? Give it a scale from 0-100, 0 being absolute pessimism and despair, and 100 being euphoric optimism. Break down the score by major topic subjects, price forcasts, bull sentiment, bear sentiment, regulation sentiment, ETF sentiment, whale sentiment, retail sentiment, price forcasts, adoption, summary of entire market. Only tell me the score, nothing else, and say it in json format using this schema:"

SCHEMA='{ 
  "Price Forecasts": 0, 
  "Bull Sentiment": 0, 
  "Bear Sentiment": 0, 
  "Regulation Sentiment": 0, 
  "ETF Sentiment": 0, 
  "Whale Sentiment": 0, 
  "Retail Sentiment": 0, 
  "Adoption": 0, 
  "Summary of Entire Market": 0 
}'

# Create data directory if it doesn't exist
DATA_DIR="/data/sentiment-data"
mkdir -p ${DATA_DIR} 2>/dev/null
CRYPTO_DATA="$DATA_DIR/crypto_sentiment_data.txt"
FOREX_DATA="$DATA_DIR/forex_sentiment_data.txt"
COMBINED_DATA="$DATA_DIR/combined_sentiment_data.txt"

# Remove any old CSV files that might be causing issues
rm -f "$DATA_DIR/crypto_sentiment.csv" "$DATA_DIR/forex_sentiment.csv" "$DATA_DIR/combined_sentiment.csv"

# Function to process feeds and extract sentiment data
get_sentiment() {
  local feeds="$1"
  local type="$2"
  
  # Fetch feeds and process with mods
  curl -s -L $feeds | mods --no-cache --quiet "${PROMPT} ${SCHEMA}" |
    # Extract JSON block
    awk '/^[[:space:]]*{/,/^[[:space:]]*}/ {print}' |
    # Add type field and format with jq
    jq --arg type "$type" --arg timestamp "$(date +"%Y-%m-%d %H:%M:%S")" '. + {Type: $type, Timestamp: $timestamp}'
}

# Function to add a record to the data store (JSON Lines format)
add_to_data() {
  local json="$1"
  local data_file="$2"
  
  # Append JSON to the data file
  echo "$json" >> "$data_file"
}

# Function to clean old data (keep only last 3 months)
clean_old_data() {
  local data_file="$1"
  local cutoff_date=$(date -d "3 months ago" +"%Y-%m-%d %H:%M:%S")
  
  # If the file exists
  if [ -f "$data_file" ]; then
    # Create a temporary file
    local temp_file="${data_file}.tmp"
    
    # Filter to keep only recent records
    cat "$data_file" | jq -c --arg cutoff "$cutoff_date" 'select(.Timestamp >= $cutoff)' > "$temp_file"
    
    # Replace original file with temp file
    mv "$temp_file" "$data_file"
  fi
}

# Generate chart using Python with direct JSON input
create_chart_with_python() {
  local data_file="$1"
  local output_file="$2"
  local title="$3"
  local summary_only="$4"  # Optional parameter for summary-only mode
  
  # Check if the data file exists and has content
  if [ ! -s "$data_file" ]; then
    echo "Warning: No data in $data_file to create chart. Skipping." >&2
    return 1
  fi

  # Create a Python script to generate the chart
  local python_script=$(mktemp)
  
  cat > "$python_script" << 'EOF'
#!/usr/bin/env python3
import sys
import json
import pandas as pd
import numpy as np
import matplotlib
# Use Agg backend to avoid X11 issues
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from datetime import datetime

data_file = sys.argv[1]
output_file = sys.argv[2]
title = sys.argv[3]
summary_only = len(sys.argv) > 4 and sys.argv[4] == "summary_only"

# Define the window size for the moving average
WINDOW_SIZE = 3  # Can be adjusted for more or less smoothing

try:
    # Create an empty list to store data
    records = []
    
    # Read JSON Lines file
    with open(data_file, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:  # Skip empty lines
                continue
            try:
                # Parse each line as a JSON object
                record = json.loads(line)
                records.append(record)
            except json.JSONDecodeError as e:
                print(f"Error parsing JSON: {e}")
                continue
    
    if not records:
        print("No valid JSON records found")
        exit(1)
    
    # Convert to DataFrame
    df = pd.DataFrame(records)
    
    # Convert timestamp to datetime
    df['Timestamp'] = pd.to_datetime(df['Timestamp'])
    
    # Sort by timestamp
    df = df.sort_values('Timestamp')
    
    # List of columns to plot
    if summary_only:
        columns = ['Summary of Entire Market']
    else:
        columns = [
            'Price Forecasts', 'Bull Sentiment', 'Bear Sentiment',
            'Regulation Sentiment', 'ETF Sentiment', 'Whale Sentiment',
            'Retail Sentiment', 'Adoption', 'Summary of Entire Market'
        ]
    
    # Apply smoothing using moving average if we have enough data points
    if len(df) >= WINDOW_SIZE:
        for col in columns:
            if col in df.columns:
                # Create a new column for the smoothed values
                # The original values remain untouched
                df[f"{col}_Smoothed"] = df[col].rolling(window=WINDOW_SIZE, min_periods=1).mean()
    
    # Define different line styles, markers, and colors for each metric
    styles = {
        'Price Forecasts': {'color': 'blue', 'linestyle': '-', 'marker': 'o', 'markersize': 5},
        'Bull Sentiment': {'color': 'green', 'linestyle': '-', 'marker': '^', 'markersize': 5},
        'Bear Sentiment': {'color': 'red', 'linestyle': '-', 'marker': 'v', 'markersize': 5},
        'Regulation Sentiment': {'color': 'purple', 'linestyle': '-.', 'marker': 's', 'markersize': 5},
        'ETF Sentiment': {'color': 'brown', 'linestyle': '--', 'marker': 'D', 'markersize': 5},
        'Whale Sentiment': {'color': 'orange', 'linestyle': ':', 'marker': 'p', 'markersize': 5},
        'Retail Sentiment': {'color': 'pink', 'linestyle': '-', 'marker': 'h', 'markersize': 5},
        'Adoption': {'color': 'cyan', 'linestyle': '--', 'marker': '*', 'markersize': 6},
        'Summary of Entire Market': {'color': 'black', 'linestyle': '-', 'marker': 'X', 'markersize': 8}
    }
    
    # Create the plot
    plt.figure(figsize=(32, 9))  # Slightly wider to accommodate the legend
    plt.title(title, fontsize=16)
    plt.xlabel('Date', fontsize=12)
    plt.ylabel('Sentiment Score (0-100)', fontsize=12)
    
    # For summary only mode with combined data, split by Type
    if summary_only and 'Type' in df.columns:
        # Group by Type and plot each group's summary
        for type_name, group_df in df.groupby('Type'):
            # Sort the group by timestamp
            group_df = group_df.sort_values('Timestamp')
            
            # Apply smoothing if needed
            if len(group_df) >= WINDOW_SIZE:
                group_df['Summary_Smoothed'] = group_df['Summary of Entire Market'].rolling(
                    window=WINDOW_SIZE, min_periods=1).mean()
                data_col = 'Summary_Smoothed'
            else:
                data_col = 'Summary of Entire Market'
            
            # Choose color based on type
            if type_name == 'Crypto':
                color = 'blue'
                marker = 'o'
            else:  # Forex
                color = 'red'
                marker = 's'
            
            # Plot with specified style
            plt.plot(
                group_df['Timestamp'],
                group_df[data_col],
                label=f"{type_name} Market Summary",
                color=color,
                linestyle='-',
                marker=marker,
                markersize=8,
                linewidth=3,
                markevery=max(1, len(group_df) // 10)
            )
    else:
        # Standard plotting for all metrics
        for col in columns:
            if col in df.columns:
                style = styles.get(col, {})  # Get style or empty dict if not found
                linewidth = 4 if col == 'Summary of Entire Market' else 2
                
                # Determine which column to use (smoothed or original)
                data_col = f"{col}_Smoothed" if f"{col}_Smoothed" in df.columns else col
                
                # Plot with specified style
                plt.plot(
                    df['Timestamp'], 
                    df[data_col], 
                    label=col,
                    color=style.get('color', 'black'),
                    linestyle=style.get('linestyle', '-'),
                    marker=style.get('marker', None),
                    markersize=style.get('markersize', 6),
                    linewidth=linewidth,
                    markevery=max(1, len(df) // 10)  # Show fewer markers to avoid clutter
                )
    
    # Format the x-axis to show dates nicely
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%d-%b'))
    plt.gca().xaxis.set_major_locator(mdates.DayLocator(interval=5))  # Show every 5 days
    plt.gcf().autofmt_xdate()  # Rotate date labels
    
    # Set y-axis range
    plt.ylim(0, 100)
    
    # Add a grid
    plt.grid(True, linestyle='--', alpha=0.7)
    
    # Add legend
    plt.legend(loc='best')
    
    # Ensure the plot fits in the figure
    plt.tight_layout()
    
    # Save the plot
    plt.savefig(output_file, dpi=100, bbox_inches='tight')
    print(f"Chart saved to {output_file}")
    
except Exception as e:
    print(f"Error creating chart: {e}")
    import traceback
    traceback.print_exc()
    exit(1)
EOF

  # Make the script executable
  chmod +x "$python_script"
  
  # Add summary_only flag if requested
  local summary_flag=""
  if [ "$summary_only" = "true" ]; then
    summary_flag="summary_only"
  fi
  
  # Run the Python script
  python3 "$python_script" "$data_file" "$output_file" "$title" $summary_flag
  
  # Check if the chart was created
  if [ -s "$output_file" ]; then
    echo "Successfully created $output_file using Python" >&2
  else
    echo "Error: Failed to create chart $output_file" >&2
  fi
  
  # Remove the temporary script
  rm -f "$python_script"
}

# Get results
echo "Fetching crypto sentiment data..."
CRYPTO_RESULTS=$(get_sentiment "$CRYPTO_FEEDS" "Crypto")
if [ -z "$CRYPTO_RESULTS" ]; then
  echo "Error: Failed to get crypto sentiment data" >&2
else
  echo "Successfully fetched crypto sentiment data"
  # Add results to data files
  add_to_data "$CRYPTO_RESULTS" "$CRYPTO_DATA"
  add_to_data "$CRYPTO_RESULTS" "$COMBINED_DATA"
fi

echo "Fetching forex sentiment data..."
FOREX_RESULTS=$(get_sentiment "$FOREX_FEEDS" "Forex")
if [ -z "$FOREX_RESULTS" ]; then
  echo "Error: Failed to get forex sentiment data" >&2
else
  echo "Successfully fetched forex sentiment data"
  # Add results to data files
  add_to_data "$FOREX_RESULTS" "$FOREX_DATA"
  add_to_data "$FOREX_RESULTS" "$COMBINED_DATA"
fi

# Clean old data (keep only last 3 months)
clean_old_data "$CRYPTO_DATA"
clean_old_data "$FOREX_DATA"
clean_old_data "$COMBINED_DATA"

# Create charts using Python
echo "Generating crypto sentiment chart..."
create_chart_with_python "$CRYPTO_DATA" "$DATA_DIR/crypto_sentiment_chart.png" "Crypto Market Sentiment (Last 3 Months)" &

echo "Generating forex sentiment chart..."
create_chart_with_python "$FOREX_DATA" "$DATA_DIR/forex_sentiment_chart.png" "Forex Market Sentiment (Last 3 Months)" &

echo "Generating combined sentiment chart..."
create_chart_with_python "$COMBINED_DATA" "$DATA_DIR/combined_sentiment_chart.png" "Crypto vs Forex Market Summary (Last 3 Months)" "true"

echo "Sentiment data updated and charts generated in $DATA_DIR/" &
wait
