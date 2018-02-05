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

  # Connect to redis
  footballstats::redis_con()

  getFrame <- function(compID, ssn, mnth) {
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

  # Print the entire table ----
  output$view <- renderTable({
    compID <- datasetInput()
    ssn <- seasonInput()
    mnth <- monthInput()

    getFrame(compID, ssn, mnth)
  })

  # Show the first "n" observations ----
  output$summary <- renderPrint({
    compID <- datasetInput()
    ssn <- seasonInput()
    mnth <- monthInput()

    totF <- getFrame(compID, ssn, mnth)
    res <- if (totF %>% nrow %>% `>`(0)) {
      summary(totF)
    } else {
      cat(' ## Nothing to display :( \n ## Try selecting different parameters from the side!')
    }
    res
  })

})

