library(shiny)
library(magrittr)
library(footballstats)


# Define server logic required to draw a histogram
shinyServer(function(input, output) {

  # Return the requested dataset ----
  datasetInput <- reactive({
    switch(
      input$league,
      "premier-league" = 1204,
      "championship" = 1205,
      "france" = 1206
     )
  })

  seasonInput <- reactive({
    switch(
      input$season,
      "2017/2018" = 2017,
      "2018/2019" = 2018
    )
  })

  monthInput <- reactive({
    switch(
      input$month,
      "January" = 1,
      "February" = 2
    )
  })

  # Connect to redis (if not already)
  tryCatch({
    rredis::redisCmd('PING')
    cat('Redis stable ... \n')
  }, error = function(e) {
    footballstats::redis_con()
  })

  # Get the data set from the predictions
  get_frame <- function(compID, ssn, mnth) {
    keys <- paste0('csdm_pred:', compID, ':', ssn, ':', mnth, ':*') %>%
      rredis::redisKeys()

    totF <- data.frame(stringsAsFactors = FALSE)
    if (keys %>% is.null %>% `!`()) {
      for (i in 1:(length(keys))) {
        res <- keys[i] %>%
          rredis::redisHGetAll() %>%
          as.data.frame
        totF %<>% rbind(res)
      }
    }
    return(totF)
  }

  # --- Convert the data frame to the correct format --- #
  conv_frame <- function(totF) {
    totF$week %<>%
      as.character %>%
      as.Date(format = '%d.%m.%Y')
    totF <- totF[
      totF$week %>%
        as.integer %>%
        order, ]
    totF$week %<>% format('%d/%m')
    return(totF)
  }

  # Print the entire table ----
  output$view <- renderTable({
    compID <- datasetInput()
    ssn <- seasonInput()
    mnth <- monthInput()

    results <- get_frame(compID, ssn, mnth) %>% conv_frame()
  })

  # Show the first "n" observations ----
  output$summary <- renderPrint({
    compID <- datasetInput()
    ssn <- seasonInput()
    mnth <- monthInput()

    totF <- get_frame(compID, ssn, mnth)
    res <- if (totF %>% nrow %>% `>`(0)) {
      summary(totF)
    } else {
      cat(' ## Nothing to display :( \n ## Try selecting different parameters from the side!')
    }
    res
  })

})


