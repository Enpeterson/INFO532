### Common startup script for each chapter ###
### Aug 18 2021

### this is from R for EPI
# clear workspace
rm(list = ls(all = TRUE))


knitr::opts_chunk$set(message =F, warning =F)

# save the built-in output hook
hook_output <- knitr::knit_hooks$get("output")

# set a new output hook to truncate text output
knitr::knit_hooks$set(output = function(x, options) {
  if (!is.null(n <- options$out.lines)) {
    x <- xfun::split_lines(x)
    if (length(x) > n) {
      # truncate the output
      x <- c(head(x, n), "....\n")
    }
    x <- paste(x, collapse = "\n")
  }
  hook_output(x, options)
})

# dealing in advance with package conflicts:
library(conflicted)
#conflict_prefer('shift', 'spatstat', quiet = T)
conflict_prefer('filter', 'dplyr', quiet = T)
conflict_prefer('select', 'dplyr', quiet = T)
conflict_prefer("area", "spatstat.geom", quiet = T)


#load core packages
pacman::p_load(
  rio,
  here,
  tidyverse,
  sf,
  sp,
  tmap,
  huxtable
)


# Settings

options(scipen=1, digits=7)

