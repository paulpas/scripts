#!/usr/bin/env bash

# Process command line arguments
CHARTS_ONLY=false
for arg in "$@"; do
  case $arg in
    --charts-only)
      CHARTS_ONLY=true
      shift # Remove --charts-only from processing
      ;;
    *)
      # Unknown option
      ;;
  esac
done

# Define feed URLs
CRYPTO_FEEDS="https://www.coindesk.com/arc/outboundfeeds/rss/ https://cointelegraph.com/rss https://bitcoinist.com/feed/ https://www.newsbtc.com/feed/ https://cryptopotato.com/feed/ https://99bitcoins.com/news/feed/ https://cryptobriefing.com/feed/ https://crypto.news/tag/cryptocurrency/ https://www.fxempire.com/api/v1/en/articles/rss/forecasts"

FOREX_FEEDS="https://feeds.content.dowjones.io/public/rss/WSJcomUSBusiness https://feeds.content.dowjones.io/public/rss/latestnewsrealestate https://feeds.content.dowjones.io/public/rss/RSSWorldNews https://feeds.content.dowjones.io/public/rss/socialpoliticsfeed"

# Define prompt and schema
PROMPT="Based on these headlines from news feeds, what is the general sentiment of the markets? Give it a scale from 0-100, 0 being absolute pessimism and despair, and 100 being euphoric optimism. Break down the score by major topic subjects, price forecasts, bull sentiment, bear sentiment, regulation sentiment, ETF sentiment, whale sentiment, retail sentiment, adoption, and summary of entire market. Only provide the score in json format using this schema:"

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

# Function to fetch and extract structured content from RSS feeds
extract_headlines_from_feeds() {
    local output=""
    local temp_file=$(mktemp)
    local count=0
    local total_feeds=$(echo $1 | wc -w)
    
    # Use bash word splitting to process each URL
    for feed_url in $1; do
        count=$((count + 1))
        echo "Fetching data from feed $count/$total_feeds: $feed_url..."
        
        # Fetch the RSS feed
        curl -s -L "$feed_url" > "$temp_file"
        
        # Check if the feed was fetched successfully
        if [ -s "$temp_file" ]; then
            # Extract feed content
            local feed_content=$(cat "$temp_file")
            
            # Start with feed source information
            output="${output}SOURCE: $feed_url\n"
            
            # Process each item in the feed
            # First, try to identify item boundaries
            local items=$(echo "$feed_content" | sed 's/<item>/\n<item>/g' | grep -o '<item>.*</item>' || echo "")
            
            if [ -z "$items" ]; then
                # If no <item> tags found, process the whole feed
                # Extract titles (skip the first which is usually the feed title)
                local titles=$(echo "$feed_content" | grep -o "<title>.*</title>" | 
                              sed 's/<title>//g; s/<\/title>//g' | 
                              sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&quot;/"/g; s/&#39;/'"'"'/g' |
                              tail -n +2)
                
                # Extract headlines if available
                local headlines=$(echo "$feed_content" | grep -o "<headline>.*</headline>" | 
                                 sed 's/<headline>//g; s/<\/headline>//g' | 
                                 sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&quot;/"/g; s/&#39;/'"'"'/g')
                
                # Extract descriptions
                local descriptions=$(echo "$feed_content" | grep -o "<description>.*</description>" | 
                                    sed 's/<description>//g; s/<\/description>//g' | 
                                    sed 's/<!$$CDATA\[//g; s/$$\]>//g' | 
                                    sed 's/<[^>]*>//g' |  # Remove any HTML tags inside descriptions
                                    sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&quot;/"/g; s/&#39;/'"'"'/g' |
                                    grep -v "^$" | tail -n +2)
                
                # Extract content
                local content=$(echo "$feed_content" | grep -o "<content>.*</content>\|<content:encoded>.*</content:encoded>" | 
                               sed 's/<content>//g; s/<\/content>//g; s/<content:encoded>//g; s/<\/content:encoded>//g' | 
                               sed 's/<!$$CDATA\[//g; s/$$\]>//g' | 
                               sed 's/<[^>]*>//g' |  # Remove any HTML tags inside content
                               sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&quot;/"/g; s/&#39;/'"'"'/g' |
                               grep -v "^$")
                
                # Add structured content to output
                if [ -n "$titles" ]; then
                    output="${output}TITLES:\n$titles\n\n"
                fi
                
                if [ -n "$headlines" ]; then
                    output="${output}HEADLINES:\n$headlines\n\n"
                fi
                
                if [ -n "$descriptions" ]; then
                    output="${output}DESCRIPTIONS:\n$descriptions\n\n"
                fi
                
                if [ -n "$content" ]; then
                    # Limit content to first 200 chars to avoid overloading
                    local trimmed_content=$(echo "$content" | cut -c1-200 | sed 's/$/.../')
                    output="${output}CONTENT SNIPPETS:\n$trimmed_content\n\n"
                fi
            else
                # Process each item individually if <item> tags were found
                local item_count=0
                while read -r item; do
                    item_count=$((item_count + 1))
                    
                    # Extract elements from the item
                    local title=$(echo "$item" | grep -o "<title>.*</title>" | 
                                 sed 's/<title>//g; s/<\/title>//g' |
                                 sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&quot;/"/g; s/&#39;/'"'"'/g')
                    
                    local description=$(echo "$item" | grep -o "<description>.*</description>" | 
                                       sed 's/<description>//g; s/<\/description>//g' | 
                                       sed 's/<!$$CDATA\[//g; s/$$\]>//g' | 
                                       sed 's/<[^>]*>//g' |  # Remove any HTML tags inside descriptions 
                                       sed 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&quot;/"/g; s/&#39;/'"'"'/g')
                    
                    # Add item information if available
                    if [ -n "$title" ] || [ -n "$description" ]; then
                        output="${output}ITEM $item_count:\n"
                        
                        if [ -n "$title" ]; then
                            output="${output}Title: $title\n"
                        fi
                        
                        if [ -n "$description" ]; then
                            # Limit description to first 150 chars to avoid overloading
                            local trimmed_desc=$(echo "$description" | cut -c1-150 | sed 's/$/.../')
                            output="${output}Description: $trimmed_desc\n"
                        fi
                        
                        output="${output}\n"
                    fi
                done <<< "$items"
            fi
            
            # Add separator between feeds
            output="${output}----------------------------------------\n\n"
        else
            echo "Warning: Failed to fetch feed from $feed_url"
        fi
    done
    
    # Clean up the temporary file
    rm -f "$temp_file"
    
    # Output the structured content
    echo "$output"
}

# Function to process feeds and extract sentiment data
get_sentiment() {
  local feeds="$1"
  local type="$2"

  # Extract just the headlines from feeds
  local headlines=$(extract_headlines_from_feeds "$feeds")
  
  if [ -z "$headlines" ]; then
    echo "Error: No headlines extracted from feeds" >&2
    return 1
  fi
  
  # Process headlines with mods
  #echo "$headlines" | mods --no-cache --quiet --api ollama --model gemma3:27b "${PROMPT} ${SCHEMA}" |
  #echo "$headlines" | mods --no-cache --quiet --api ollama --model deepseek-r1:32b "${PROMPT} ${SCHEMA}" |
  echo "$headlines" | mods --no-cache --quiet --api ollama --model phi4:14b "${PROMPT} ${SCHEMA}" |
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

# Function to clean old data (keep only last 1 months)
clean_old_data() {
  local data_file="$1"
  local cutoff_date=$(date -d "1 months ago" +"%Y-%m-%d %H:%M:%S")

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

# Define the window size for the moving average
WINDOW_SIZE = 24  # Can be adjusted for more or less smoothing

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
        'Summary of Entire Market': {'color': 'black', 'linestyle': '-', 'marker': 'X', 'markersize': 8},
        'Neutral Line': {'color': '#FF5733', 'linestyle': '-', 'linewidth': 2.5}  # Added for legend
    }

    # Create the plot
    plt.figure(figsize=(24, 10))
    plt.title(title, fontsize=16)
    plt.xlabel('Date', fontsize=12)
    plt.ylabel('Sentiment Score (0-100)', fontsize=12)

    # Draw the horizontal line at 50 first (so it's behind the data series)
    plt.axhline(y=50, color='#696969', linestyle='dashed', linewidth=1.5)

    # Add the neutral line to the plot for legend purposes (but don't show it)
    plt.plot([], [],
             label='Neutral Sentiment (50)',
             color='#FF5733',
             linestyle='-',
             linewidth=2.5)
    # Plot each metric with its unique style
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

    # Define sentiment markers with their properties
    sentiment_markers = [
        {'y': 0, 'position': 0.01, 'text': 'MAX BEARISH', 'color': '#A52A2A', 'valign': 'bottom'},
        {'y': 50, 'position': 0.5, 'text': 'NEUTRAL SENTIMENT', 'color': '#696969', 'valign': 'center'},
        {'y': 100, 'position': 0.99, 'text': 'MAX BULLISH', 'color': '#006400', 'valign': 'top'}
    ]
    
    # Add horizontal lines and text boxes for each sentiment marker
    for marker in sentiment_markers:
        # Draw horizontal line
        plt.axhline(y=marker['y'], color=marker['color'], linestyle='dashed', linewidth=1.5)
        
        # Add text box
        plt.text(
            0.99, marker['position'],  # x position at right side, y position as specified
            marker['text'],
            fontsize=10,
            fontweight='bold',
            color=marker['color'],
            transform=plt.gca().transAxes,
            verticalalignment=marker['valign'],
            horizontalalignment='right',
            bbox=dict(facecolor='white', alpha=0.8, edgecolor=marker['color'], boxstyle='round,pad=0.3')
        )

    # Format the x-axis to show dates nicely
    plt.gca().xaxis.set_major_formatter(mdates.DateFormatter('%d-%b'))
    plt.gca().xaxis.set_major_locator(mdates.DayLocator(interval=5))  # Show every 5 days
    plt.gcf().autofmt_xdate()  # Rotate date labels

    # Set y-axis range
    plt.ylim(0, 100)

    # Add a grid
    plt.grid(True, linestyle='--', alpha=0.7)

    # Add legend outside the plot
    plt.legend(bbox_to_anchor=(1.05, 1), loc='upper left')

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

  # Run the Python script
  python3 "$python_script" "$data_file" "$output_file" "$title"

  # Check if the chart was created
  if [ -s "$output_file" ]; then
    echo "Successfully created $output_file using Python" >&2
  else
    echo "Error: Failed to create chart $output_file" >&2
  fi

  # Remove the temporary script
  rm -f "$python_script"
}

# Only fetch new data if not in charts-only mode
if [ "$CHARTS_ONLY" = false ]; then
  # Get results
  echo "Fetching crypto sentiment data..."
  CRYPTO_RESULTS=$(get_sentiment "$CRYPTO_FEEDS" "Crypto")
echo $CRYPTO_RESULTS
  if [ -z "$CRYPTO_RESULTS" ]; then
    echo "Error: Failed to get crypto sentiment data" >&2
  else
    echo "Successfully fetched crypto sentiment data"
    # Add results to data files
    add_to_data "$CRYPTO_RESULTS" "$CRYPTO_DATA"
    add_to_data "$CRYPTO_RESULTS" "$COMBINED_DATA"
  fi

#  echo "Fetching forex sentiment data..."
#  FOREX_RESULTS=$(get_sentiment "$FOREX_FEEDS" "Forex")
#  if [ -z "$FOREX_RESULTS" ]; then
#    echo "Error: Failed to get forex sentiment data" >&2
#  else
#    echo "Successfully fetched forex sentiment data"
#    # Add results to data files
#    add_to_data "$FOREX_RESULTS" "$FOREX_DATA"
#    add_to_data "$FOREX_RESULTS" "$COMBINED_DATA"
#  fi
#
  # Clean old data (keep only last 1 months)
  clean_old_data "$CRYPTO_DATA"
  clean_old_data "$FOREX_DATA"
  clean_old_data "$COMBINED_DATA"
else
  echo "Charts-only mode: Skipping data fetch and using existing data..."
fi

echo $CRYPTO_RESULTS

# Create charts using Python (this happens in both modes)
echo "Generating crypto sentiment chart..."
create_chart_with_python "$CRYPTO_DATA" "$DATA_DIR/crypto_sentiment_chart.png" "Crypto Market Sentiment (Last 1 Months)"

#echo "Generating forex sentiment chart..."
#create_chart_with_python "$FOREX_DATA" "$DATA_DIR/forex_sentiment_chart.png" "Forex Market Sentiment (Last 1 Months)"

#echo "Generating combined sentiment chart..."
#create_chart_with_python "$COMBINED_DATA" "$DATA_DIR/combined_sentiment_chart.png" "Combined Market Sentiment (Last 1 Months)"

#echo "Sentiment data updated and charts generated in $DATA_DIR/"
