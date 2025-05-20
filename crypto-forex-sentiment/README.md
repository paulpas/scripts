# Crypto & Forex Market Sentiment Tracker

This toolkit consists of scripts that track and visualize market sentiment trends from cryptocurrency and forex news sources. The system collects sentiment scores from RSS feeds, analyzes them using AI, and generates charts to track sentiment trends over time.

## Overview

The Sentiment Tracker:

1. Collects data from multiple crypto and forex news RSS feeds
2. Uses AI to analyze the overall sentiment on various market topics
3. Stores the sentiment data in a structured format
4. Generates time-series charts to visualize sentiment trends
5. Maintains a 3-month rolling window of historical data

## Scripts

### sentiment_tracker.sh

The main script that performs data collection, analysis, and chart generation.

```
bash sentiment_tracker.sh
```

This script:
- Fetches and analyzes RSS feeds from top crypto and forex news sources
- Calculates sentiment scores (0-100) for different aspects of the market
- Stores the data in JSON Lines format for reliable data storage
- Generates three charts: crypto sentiment, forex sentiment, and combined
- Maintains a 3-month rolling window of historical data

### Features

- **Multiple Data Sources**: Aggregates data from diverse news sources for comprehensive sentiment analysis
- **Topic Breakdown**: Separates sentiment by topic (price forecasts, bull/bear sentiment, regulation, etc.)
- **Smoothed Visualization**: Uses simple moving averages to smooth out data and show clearer trends
- **Distinct Visual Styling**: Each metric uses a unique combination of color, line style, and markers
- **Automatic Data Retention**: Automatically maintains a 3-month rolling window of historical data

## Data Structure

The sentiment data is stored in JSON Lines format, with each entry containing:

- Timestamp: When the data was collected
- Type: "Crypto" or "Forex"
- Various sentiment metrics (scale 0-100):
  - Price Forecasts
  - Bull Sentiment
  - Bear Sentiment
  - Regulation Sentiment
  - ETF Sentiment
  - Whale Sentiment
  - Retail Sentiment
  - Adoption
  - Summary of Entire Market

## Generated Charts

The script generates three PNG charts (1024x1024):

1. `crypto_sentiment_chart.png`: Shows sentiment trends for cryptocurrency markets
2. `forex_sentiment_chart.png`: Shows sentiment trends for forex markets
3. `combined_sentiment_chart.png`: Shows both crypto and forex sentiment trends together

## Requirements

- Linux/Unix environment
- Bash shell
- Python 3 with the following packages:
  - pandas
  - matplotlib
  - numpy
- curl (for fetching data)
- jq (for JSON processing)
- mods (for AI sentiment analysis
  - https://github.com/charmbracelet/mods

You can install the required Python packages with:

```
sudo apt update
sudo apt install -y python3-pip python3-pandas python3-matplotlib python3-numpy
pip3 install pyparsing
```

## Installation

1. Clone or download this repository
2. Make the script executable:
   ```
   chmod +x sentiment_tracker.sh
   ```
3. Install dependencies as listed above
4. Run the script:
   ```
   ./sentiment_tracker.sh
   ```

## Scheduling

For continuous sentiment tracking, set up a cron job to run the script at regular intervals:

```
# Run every 4 hours
0 */4 * * * /path/to/sentiment_tracker.sh
```

## Data Storage

All data and charts are stored in the `data/` directory:

- `crypto_sentiment_data.txt`: Historical crypto sentiment data
- `forex_sentiment_data.txt`: Historical forex sentiment data
- `combined_sentiment_data.txt`: Combined historical data
- PNG chart files with the latest visualizations

## Customization

You can customize the script by modifying:

- RSS feed sources in the `CRYPTO_FEEDS` and `FOREX_FEEDS` variables
- Moving average window size (default: 3) in the Python script
- Chart appearance, colors, and styles in the Python plotting section
- Data retention period (default: 3 months) in the `clean_old_data` function

## Troubleshooting

- **Missing Charts**: Ensure Python and its dependencies are correctly installed
- **Empty Data Files**: Check that the RSS feeds are accessible and returning data
- **X11 Errors**: These can be safely ignored as the script uses the Agg backend for matplotlib

## License

This toolkit is provided under the MIT License. Feel free to modify and distribute as needed.

## Acknowledgments

- Uses matplotlib for chart generation
- Uses pandas for data processing
- Uses jq for JSON manipulation

---

For questions or issues, please open an issue in the GitHub repository.
