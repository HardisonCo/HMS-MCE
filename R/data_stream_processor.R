library(forecast)
library(dplyr)
library(lubridate)
library(jsonlite)
library(httr)
library(zoo)
library(xts)
library(TTR)

EconomicsProcessor <- R6::R6Class("EconomicsProcessor",
  public = list(
    data = NULL,
    trends = NULL,
    forecasts = NULL,
    
    initialize = function() {
      message("Economics Data Stream Processor initialized")
    },
    
    process_stream = function(data_stream, date_col = "date", value_col = "value") {
      tryCatch({
        if (is.character(data_stream)) {
          self$data <- fromJSON(data_stream)
        } else {
          self$data <- data_stream
        }
        
        self$data[[date_col]] <- as.Date(self$data[[date_col]])
        self$data <- self$data[order(self$data[[date_col]]), ]
        
        ts_data <- ts(self$data[[value_col]], 
                     start = c(year(min(self$data[[date_col]])), 
                              month(min(self$data[[date_col]]))),
                     frequency = 12)
        
        return(ts_data)
      }, error = function(e) {
        stop(paste("Error processing data stream:", e$message))
      })
    },
    
    detect_trends = function(ts_data, method = "moving_average", window = 12) {
      trends <- list()
      
      if (method == "moving_average") {
        trends$ma <- SMA(ts_data, n = window)
        trends$direction <- ifelse(diff(trends$ma, lag = 1) > 0, "upward", "downward")
        trends$slope <- diff(trends$ma, lag = 1)
      } else if (method == "linear") {
        time_index <- 1:length(ts_data)
        lm_model <- lm(as.numeric(ts_data) ~ time_index)
        trends$linear_trend <- fitted(lm_model)
        trends$slope <- coef(lm_model)[2]
        trends$direction <- ifelse(trends$slope > 0, "upward", "downward")
      }
      
      trends$strength <- abs(trends$slope)
      trends$method <- method
      
      self$trends <- trends
      return(trends)
    },
    
    generate_forecast = function(ts_data, periods = 12, method = "auto") {
      forecasts <- list()
      
      if (method == "auto") {
        fit <- auto.arima(ts_data)
        forecast_result <- forecast(fit, h = periods)
      } else if (method == "exponential") {
        fit <- ets(ts_data)
        forecast_result <- forecast(fit, h = periods)
      } else if (method == "naive") {
        forecast_result <- naive(ts_data, h = periods)
      }
      
      forecasts$values <- as.numeric(forecast_result$mean)
      forecasts$lower <- as.numeric(forecast_result$lower[, 2])
      forecasts$upper <- as.numeric(forecast_result$upper[, 2])
      forecasts$method <- method
      forecasts$periods <- periods
      
      last_date <- max(self$data$date)
      forecasts$dates <- seq(from = last_date + months(1), 
                           by = "month", 
                           length.out = periods)
      
      self$forecasts <- forecasts
      return(forecasts)
    },
    
    export_results = function(format = "json", file_path = NULL) {
      results <- list(
        timestamp = Sys.time(),
        trends = self$trends,
        forecasts = self$forecasts,
        summary = list(
          trend_direction = self$trends$direction[length(self$trends$direction)],
          forecast_mean = mean(self$forecasts$values, na.rm = TRUE),
          confidence_interval = list(
            lower = mean(self$forecasts$lower, na.rm = TRUE),
            upper = mean(self$forecasts$upper, na.rm = TRUE)
          )
        )
      )
      
      if (format == "json") {
        json_output <- toJSON(results, pretty = TRUE, auto_unbox = TRUE)
        if (!is.null(file_path)) {
          writeLines(json_output, file_path)
        }
        return(json_output)
      }
      
      return(results)
    },
    
    send_to_system = function(endpoint_url, auth_token = NULL) {
      results <- self$export_results()
      
      headers <- list("Content-Type" = "application/json")
      if (!is.null(auth_token)) {
        headers$Authorization <- paste("Bearer", auth_token)
      }
      
      response <- POST(
        url = endpoint_url,
        body = results,
        add_headers(.headers = headers),
        encode = "json"
      )
      
      if (status_code(response) == 200) {
        message("Data successfully sent to system")
        return(TRUE)
      } else {
        warning(paste("Failed to send data. Status code:", status_code(response)))
        return(FALSE)
      }
    }
  )
)