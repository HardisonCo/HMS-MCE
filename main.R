source("R/data_stream_processor.R")

if (!require(R6)) install.packages("R6")
library(R6)

main <- function() {
  processor <- EconomicsProcessor$new()
  
  sample_data <- data.frame(
    date = seq(as.Date("2020-01-01"), as.Date("2023-12-01"), by = "month"),
    value = rnorm(48, mean = 100, sd = 10) + 1:48 * 0.5
  )
  
  ts_data <- processor$process_stream(sample_data)
  
  trends <- processor$detect_trends(ts_data, method = "moving_average")
  
  forecasts <- processor$generate_forecast(ts_data, periods = 12, method = "auto")
  
  results_json <- processor$export_results(format = "json", 
                                          file_path = "output/forecast_results.json")
  
  cat("Analysis complete. Results saved to output/forecast_results.json\n")
  cat("Trend direction:", trends$direction[length(trends$direction)], "\n")
  cat("Forecast mean:", mean(forecasts$values), "\n")
  
  return(processor)
}

if (!interactive()) {
  main()
}