library(data.table)
library(compiler)
library(microbenchmark)
library(ggplot2)

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

link_big <- "https://raw.githubusercontent.com/gregcodes/counter_challenge/master/Datasets/dataset_big.csv"
link_small <- "https://raw.githubusercontent.com/gregcodes/counter_challenge/master/Datasets/dataset_small.csv"

dt <- data.table(read.csv(link_big, sep = ";"))
setnames(dt, c("id", "comp", "date"))

dt[, date := as.Date(date)]
dt[, date_int := as.integer(date)]


res_bench <- microbenchmark(
  iei = dt[, count := iei(date), by = "comp"],
  iei_int = dt[, count_comp := comp_iei(date), by = "comp"],
  comp_iei = dt[, count_int := iei(date_int), by = "comp"],
  comp_iei_int = dt[, count_int_comp := comp_iei(date_int), by = "comp"],
  times = 10
)

res_bench
autoplot(res_bench)
