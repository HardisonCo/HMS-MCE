# Economics Data Stream Analysis

R project for processing economic data streams, detecting trends, and generating forecasts.

## Setup

1. Install required packages:
```r
source("install_packages.R")
```

2. Run the main analysis:
```r
source("main.R")
```

## Usage

```r
# Create processor instance
processor <- EconomicsProcessor$new()

# Process data stream
ts_data <- processor$process_stream(your_data)

# Detect trends
trends <- processor$detect_trends(ts_data, method = "moving_average")

# Generate forecasts
forecasts <- processor$generate_forecast(ts_data, periods = 12)

# Export results
results <- processor$export_results(format = "json")

# Send to external system
processor$send_to_system("https://your-api-endpoint.com/data")
```

## Features

- Data stream processing from JSON or data frames
- Trend detection using moving averages or linear regression
- Forecasting with auto ARIMA, exponential smoothing, or naive methods
- JSON export functionality
- System integration via HTTP API calls