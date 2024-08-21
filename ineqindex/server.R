#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
options(shiny.maxRequestSize=30*1024^2)

# Define server logic ----
server <- function(input, output, session) {
  
  # Reactive expression to read the file ----
  dataset <- reactive({
    req(input$data)
    
    # Check the file extension and read accordingly
    file_extension <- tools::file_ext(input$data$name)
    data <- switch(file_extension,
                   "dta" = haven::read_dta(input$data$datapath),
                   "xlsx" = readxl::read_excel(input$data$datapath),
                   "dbf" = foreign::read.dbf(input$data$datapath))
    
    data
  })
  
  # Display uploaded data ----
  output$contents <- renderTable({
    req(dataset())
    
    # Always display the first 10 rows
    head(dataset(), 10)
  })
  
  # Update selectInput choices based on uploaded data ----
  observe({
    req(dataset())
    
    # Update choices for selectInput
    updateSelectInput(session, "x", choices = colnames(dataset()))
    updateSelectInput(session, "y", choices = colnames(dataset()))
    updateSelectInput(session, "w", choices = colnames(dataset()))
  })
  
  # Perform operations with selected variables and display results ----
  output$results <- renderText({
    req(input$x, input$y, input$w)
    
    x <- dataset()[[input$x]]
    y <- dataset()[[input$y]]
    w <- dataset()[[input$w]]
    
    # Concentration index
    Conc <- calcSConc(x, y, w) 
    
    # Gini index
    Gin <- calcSGini(y, w)
    
    # Kakwani index
    Kkwn <- Conc$ineq$index - Gin$ineq$index
    
    # Combine results into one string
    result_string <- paste(
      "индекс концентрации (Concentration index):", round(Conc$ineq$index, 5),
      "коэффициент Джини (Gini index):", round(Gin$ineq$index, 5),
      "индекс Каквани (Kakwani index):", round(Kkwn, 5)
    )
    
    # Return result string
    result_string
  })
  
  # Plotting function
  output$plot <- renderPlot({
    req(input$plot_button)
    req(input$x, input$y, input$w)
    
    x <- dataset()[[input$x]]
    y <- dataset()[[input$y]]
    w <- dataset()[[input$w]]
    
    df_plot <- curveConcent(x, y, w, col="green", 
                            xlab="совокупная доля домохозяйств, ранжированных по доходу (%)", 
                            ylab = "совокупная доля доходов и расходов (%)")
    par(new=TRUE)
    curveLorenz(y, w, col="red")
    
    # Add legend
    legend("bottomright", legend=c("Кривая концентрации", "Кривая Лоренца"),
           col=c("green", "red"), lty=1)
    
    }
  )
}