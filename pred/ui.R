library(shiny)

# Define UI for application that plots random distributions
shinyUI(fluidPage(

  # App CSS ----
  #theme = "bootstrap.css",
  includeCSS("styles.css"),

  # App title ----
  #titlePanel("Select Options"),

  headerPanel("Select Options"),

  # Sidebar layout with a input and output definitions ----
  sidebarLayout(

    # Sidebar panel for inputs ----
    sidebarPanel(

      id = 'sidebar',

      # Input: Selector for choosing dataset ----
      selectInput(inputId = "league",
                  label = "Choose a competition:",
                  choices = c("premier-league", "championship", "france",
                              "germany", "italy", "portugal", "turkey")),

      selectInput(inputId = "season",
                  label = "Select season (2017='17/'18)",
                  choices = c("2017/2018", "2018/2019")),

      # Input: Numeric entry for number of obs to view ----
      selectInput(inputId = "month",
                  label = "Month to look at",
                  choices = c("January", "February", "March", "April",
                              "May", "June", "July", "August", "September",
                              "October", "November", "December"))
    ),

    # Main panel for displaying outputs ----
    mainPanel(

      # Output: Verbatim text for data summary ----
      verbatimTextOutput("summary"),

      # Output: HTML table with requested number of observations ----
      #tableOutput("view")

      DT::dataTableOutput("view")
    )
  )
))
