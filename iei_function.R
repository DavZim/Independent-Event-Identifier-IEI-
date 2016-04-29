# Libraries -----
library(data.table)
library(microbenchmark)
library(compiler)
library(ggplot2)

# Functions -------

#' Efficient Independent Event Identifier
#' The function identifies independent dates are more than 60 days away from the next independent date.
#' @param x a vector of dates or integers
#'
#' @return a vector of 0s and 1s that indicates if the date is independent (1) 
#'
#' @examples
#' dates <- as.Date(paste(2000, c(1, 3, 5, 9, 11), c(1, 25, 9, 2, 17), sep = "-"))
#' independent_dates <- iei(dates)
#' dates[independent_dates]
#' 
#' # or with integers (faster)
#' dates_int <- as.integers(dates)
#' independent_dates <- iei(dates)
#' dates[independent_dates]

iei <- function(x) {
  count <- c(1, rep(0, length(x) - 1))
  
  count[(x - x[1]) > 60] <- 1
  
  take <- cumsum(count) < 2
  count_stay <- count[take]
  x_new <- x[!take]
  
  if (length(x_new) != 0) {
    count_new <- iei(x_new)
  } else {
    count_new <- numeric(0)
  }
  c(count_stay, count_new)
}
comp_iei <- cmpfun(iei)

# load data -------
dt <- data.table(read.csv("https://raw.githubusercontent.com/gregcodes/counter_challenge/master/dataset.csv", sep = ";"))
setnames(dt, c("id", "comp", "date"))
dt[, date := as.Date(date)]
dt <- dt[order(comp, date)]
dt[, date_int := as.integer(date)]
# compute 
dt[, count := comp_iei(date_int), by = "comp"]

dt

# check for the number of counts
sum(dt$count)

# microbenchmark --------
res_bench <- microbenchmark(
  iei = dt[, count := iei(date), by = "comp"],
  iei_int = dt[, count_comp := comp_iei(date), by = "comp"],
  comp_iei = dt[, count_int := iei(date_int), by = "comp"],
  comp_iei_int = dt[, count_int_comp := comp_iei(date_int), by = "comp"],
  times = 100
)

res_bench
autoplot(res_bench) 

# check if the results are the same
dt[, count := iei(date), by = "comp"]
dt[, count_comp := comp_iei(date), by = "comp"]
dt[, count_int := iei(date_int), by = "comp"]
dt[, count_int_comp := comp_iei(date_int), by = "comp"]

all.equal(dt$count, dt$count_comp, dt$count_int, dt$count_int_comp)

