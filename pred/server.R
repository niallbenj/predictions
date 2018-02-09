library(shiny)
library(magrittr)
library(footballstats)
library(DT)


# Define server logic required to draw a histogram
shinyServer(function(input, output) {

  # Return the requested dataset ----
  datasetInput <- reactive({
    switch(
      input$league,
      "premier-league" = 1204,
      "championship" = 1205,
      "france" = 1221,
      "germany" = 1229,
      "italy" = 1269,
      "portugal" = 1352,
      "turkey" = 1425
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
      "February" = 2,
      "March" = 3,
      "April" = 4,
      "May" = 5,
      "June" = 6,
      "July" = 7,
      "August" = 8,
      "September" = 9,
      "October" = 10,
      "November" = 11,
      "December" = 12
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

    print(keys)
    totF <- data.frame(stringsAsFactors = FALSE)
    if (keys %>% is.null %>% `!`()) {
      for (i in 1:(length(keys))) {
        res <- keys[i] %>%
          rredis::redisHGetAll() %>%
          as.data.frame
        res$month <- mnth
        res$season <- ssn
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
    totF$week %<>% format('%d') %>% as.integer

    newF <- data.frame(
      day = totF$week,
      month = totF$month,
      season = totF$season,
      home = totF$localteam,
      away = totF$visitorteam,
      `predicted-result` = paste0(totF$home, ' - ', totF$away),
      prediction = totF$prediction,
      stringsAsFactors = FALSE
    )

    return(newF)
  }


  # --- Convert for summary --- #
  conv_summary <- function(totF) {

    newF <- data.frame(
      prediction = totF$prediction,
      stringsAsFactors = FALSE
    )

    return(newF)
  }


  # Print the entire table ----
  output$view <- DT::renderDataTable({
    compID <- datasetInput()
    ssn <- seasonInput()
    mnth <- monthInput()

    results <- get_frame(compID, ssn, mnth) %>% conv_frame()
    rownames(results) <- NULL
    datatable(results, options = list(dom = 'ftp'), rownames = FALSE) %>% formatStyle(
      columns = names(results),
      color = '#FFFFFF',
      backgroundColor = '#212121'
    )
  })

  # Show the first "n" observations ----
  output$summary <- renderPrint({
    compID <- datasetInput()
    ssn <- seasonInput()
    mnth <- monthInput()

    totF <- get_frame(compID, ssn, mnth) %>% conv_summary()
    res <- if (totF %>% nrow %>% `>`(0)) {
      cat(' ## Prediction Summary ## \n\n')
      nonEmpty <- totF %>% subset(totF$prediction != '-')
      cat(paste0('     Analysing ', totF %>% nrow, ' match(es)'))
      cat(paste0(' / ', nonEmpty %>% nrow, ' have been predicted \n\n'))
      nonEmpty <- totF %>% subset(totF$prediction != '-')
      if (nonEmpty %>% nrow %>% `>`(0)) {
        correct <- nonEmpty$prediction %>% `==`('T') %>% sum
        cat(paste0(' ## Success rate of ', correct/(nonEmpty %>% nrow) *100, '% \n'))
      }
    } else {
      cat(' ## Nothing to display :( \n ## Try selecting different parameters from the side!')
    }
  })

})


