options(shiny.maxRequestSize = 100*1024^2)  # Увеличение лимита до 100 MB

# Load necessary libraries
library(readxl)
library(dplyr)
library(writexl)
library(foreign)
library(rlang)
library(shiny)

# AEQ calculation function
calculate_AEQ <- function(data, survey_year_col, birth_year_col, ID_col, threshold_age, eta, theta) {
  data[[survey_year_col]] <- as.numeric(as.character(data[[survey_year_col]]))
  data[[birth_year_col]] <- as.numeric(as.character(data[[birth_year_col]]))
  
  data$age <- data[[survey_year_col]] - data[[birth_year_col]]   
  data$adult <- ifelse(data$age > threshold_age, 1, 0)
  data$children <- ifelse(data$age <= threshold_age, 1, 0)
  
  AEQ <- (tapply(data$adult, data[[ID_col]], sum) + (eta * tapply(data$children, data[[ID_col]], sum)))^theta
  data$AEQ <- AEQ[match(data[[ID_col]], names(AEQ))]
  data <- data[c(ID_col, "AEQ")]
  aeq_data <- aggregate(AEQ ~ ., data = data, mean)
  
  return(aeq_data)
}

# Total income per household calculation function
calculate_total_income <- function(income_data, ID_col, income_category_cols) {
  income_data$total_income <- rowSums(income_data[, income_category_cols], na.rm = TRUE)
  income_data$total_income_per_household <- ave(income_data$total_income, income_data[[ID_col]], FUN = sum)
  income_data <- income_data[c(ID_col, "total_income_per_household")]
  hh_income_data <- aggregate(total_income_per_household ~ ., data = income_data, mean)
  
  return(hh_income_data)
}

# Total expenses per household calculation function
calculate_total_expenses <- function(exp_data, ID_col, expenses_col) {
  exp_data$total_expenses_per_household <- ave(exp_data[[expenses_col]], exp_data[[ID_col]], FUN = sum)
  hh_exp_data <- exp_data[c(ID_col, "total_expenses_per_household")]
  hh_exp_data <- aggregate(total_expenses_per_household ~ ., data = hh_exp_data, mean)
  
  return(hh_exp_data)
}

# Merge and assign income, expenses, AEQ, weights function
merge_four_df <- function(weights, aeq_data, hh_income_data, hh_exp_data, weights_id, aeq_id, income_id, expenses_id) {
  merged_df <- merge(weights, aeq_data, by.x = weights_id, by.y = aeq_id, all.x = TRUE)
  merged_df <- merge(merged_df, hh_income_data, by.x = weights_id, by.y = income_id, all.x = TRUE)
  merged_df <- merge(merged_df, hh_exp_data, by.x = weights_id, by.y = expenses_id, all.x = TRUE)
  
  assign("merged_df", merged_df, envir = .GlobalEnv)
}

# Quarterly expenses and income per AEQ calculation function
calculate_avg_exp_income <- function(merged_df, id_col, wt_col, total_expenses_per_household, total_income_per_household, AEQ, output_exp_col = "AVG_EXP", output_income_col = "AVG_INCOME") {
  merged_df[[total_expenses_per_household]][is.na(merged_df[[total_expenses_per_household]])] <- 0
  merged_df[[total_income_per_household]][is.na(merged_df[[total_income_per_household]])] <- 0
  
  merged_df[[output_exp_col]] <- merged_df[[total_expenses_per_household]] / merged_df[[AEQ]]
  merged_df[[output_income_col]] <- merged_df[[total_income_per_household]] / merged_df[[AEQ]]
  
  per_aeq_df <- merged_df[c(id_col, wt_col, AEQ, output_exp_col, output_income_col)]
  
  return(per_aeq_df)
}

# Combined function for sequential analysis
sequential_analysis <- function(exp_data, income_data, passport_data, weights_data,
                                survey_year_col, birth_year_col, exp_ID_col, income_ID_col, passport_ID_col, weights_ID_col,
                                threshold_age, eta, theta,
                                income_category_cols, expenses_col,
                                aeq_ID_col, income_hh_ID_col, expenses_hh_ID_col,
                                wt_col, quarter) {
  
  aeq_data <- calculate_AEQ(passport_data, survey_year_col, birth_year_col, passport_ID_col, threshold_age, eta, theta)
  hh_income_data <- calculate_total_income(income_data, income_ID_col, income_category_cols)
  hh_exp_data <- calculate_total_expenses(exp_data, exp_ID_col, expenses_col)
  merged_df <- merge_four_df(weights_data, aeq_data, hh_income_data, hh_exp_data, weights_ID_col, aeq_ID_col, income_hh_ID_col, expenses_hh_ID_col)
  per_aeq_df <- calculate_avg_exp_income(merged_df, aeq_ID_col, wt_col, "total_expenses_per_household", "total_income_per_household", "AEQ")
  
  # Calculate age, adult, children and exclude children rows in the final output table
  passport_data[[survey_year_col]] <- as.numeric(as.character(passport_data[[survey_year_col]]))
  passport_data[[birth_year_col]] <- as.numeric(as.character(passport_data[[birth_year_col]]))
  
  passport_data$age <- passport_data[[survey_year_col]] - passport_data[[birth_year_col]]
  passport_data$adult <- ifelse(passport_data$age > threshold_age, 1, 0)
  passport_data$children <- ifelse(passport_data$age <= threshold_age, 1, 0)
  
  per_aeq_df <- merge(per_aeq_df, passport_data[c(passport_ID_col, "age", "adult", "children")], by.x = aeq_ID_col, by.y = passport_ID_col)
  final_table <- per_aeq_df %>% filter(children == 0)
  
  return(final_table)
}


# UI
ui <- fluidPage(
  titlePanel("Приложение для подготовки данных"),
  
  fluidRow(
    div(style = "padding: 10px; background-color: #f8f9fa; border-radius: 5px;",
        p("Для подготовки данных на этой странице необходимо обработать формы D004 (Журнал учета ежеквартальных расходов и доходов домашних хозяйств),", 
          br(), 
          "D008 (Контрольная карточка состава домашнего хозяйства) и весов выборки. После выполнения всех расчетов нажмите кнопку 'СОХРАНИТЬ ПОЛНУЮ ТАБЛИЦУ',", 
          br(), 
          "чтобы сохранить готовые данные. Эти данные можно будет использовать для дальнейшего анализа на странице 'Расчет индексов неравенства'.")
    )
  ),
  
  
  sidebarLayout(
    sidebarPanel(
      fileInput("exp_data", "Загрузить данные о расходах"),
      fileInput("income_data", "Загрузить данные о доходах"),
      fileInput("passport_data", "Загрузить контрольные данные"),
      fileInput("weights_data", "Загрузить данные о весах выборки"),
      selectInput("survey_year_col", "Выберите столбец с информацией о годе проведения обследования", NULL),
      selectInput("birth_year_col", "Выберите столбец с годом рождения респондентов", NULL),
      selectInput("passport_ID_col", "Выберите столбец ID в контрольных данных", NULL),
      selectInput("exp_ID_col", "Выберите ID столбец в данных о расходах", NULL),
      selectInput("expenses_col", "Выберите столбец с информацией о расходах", NULL),
      selectInput("income_ID_col", "Выберите ID столбец в данных о доходах", NULL),
      selectInput("income_category_cols", "Выберите столбец с информацией о доходах", NULL, multiple = TRUE),
      selectInput("wt_col", "Выберите столбец содержащий веса", NULL),
      selectInput("weights_ID_col", "Выберите ID столбец в данных о весах", NULL),
      numericInput("threshold_age", "Выбрать пороговый возраст (14 по умолчанию)", value = 14),
      numericInput("eta", "Коэффициент Eta (0,5 по умолчанию)", value = 0.5),
      numericInput("theta", "Коэффициент Theta (1 по умолчанию)", value = 1),
      numericInput("quarter", "Квартал обследования", value = 1),
      actionButton("add_to_table", "Вывести расчеты (10 строк)"),
      downloadButton("downloadData", "СОХРАНИТЬ ПОЛНУЮ ТАБЛИЦУ")
    ),
    
    mainPanel(
      tableOutput("Output_table")
    )
  )
)


# Server
server <- function(input, output, session) {
  
  # Function to read files based on extension
  read_file <- function(file_path) {
    ext <- tools::file_ext(file_path)
    if (ext == "xlsx" || ext == "xls") {
      return(read_excel(file_path))
    } else if (ext == "dbf") {
      return(read.dbf(file_path))
    } else {
      stop("Unsupported file type")
    }
  }
  
  # Reading files
  exp_data <- reactive({
    req(input$exp_data)
    read_file(input$exp_data$datapath)
  })
  
  income_data <- reactive({
    req(input$income_data)
    read_file(input$income_data$datapath)
  })
  
  passport_data <- reactive({
    req(input$passport_data)
    read_file(input$passport_data$datapath)
  })
  
  weights_data <- reactive({
    req(input$weights_data)
    read_file(input$weights_data$datapath)
  })
  
  final_table_full <- reactiveVal(data.frame())
  final_table_display <- reactiveVal(data.frame())
  
  # Update selectInput options when files are uploaded
  observe({
    updateSelectInput(session, "survey_year_col", choices = colnames(passport_data()))
    updateSelectInput(session, "birth_year_col", choices = colnames(passport_data()))
    updateSelectInput(session, "passport_ID_col", choices = colnames(passport_data()))
    updateSelectInput(session, "exp_ID_col", choices = colnames(exp_data()))
    updateSelectInput(session, "expenses_col", choices = colnames(exp_data()))
    updateSelectInput(session, "income_ID_col", choices = colnames(income_data()))
    updateSelectInput(session, "income_category_cols", choices = colnames(income_data()), selected = colnames(income_data())[1])
    updateSelectInput(session, "wt_col", choices = colnames(weights_data()))
    updateSelectInput(session, "weights_ID_col", choices = colnames(weights_data()))
  })
  
  # Update final_table and Output_table when the "Add to Table" button is clicked
  observeEvent(input$add_to_table, {
    result_table <- sequential_analysis(exp_data(), income_data(), passport_data(), weights_data(),
                                        input$survey_year_col, input$birth_year_col, input$exp_ID_col, input$income_ID_col, input$passport_ID_col, input$weights_ID_col,
                                        input$threshold_age, input$eta, input$theta,
                                        input$income_category_cols, input$expenses_col,
                                        input$passport_ID_col, input$income_ID_col, input$exp_ID_col,
                                        input$wt_col, input$quarter)
    
    final_table_full(result_table)
    final_table_display(head(result_table, 10))
    output$Output_table <- renderTable(final_table_display())
  })
  
  # Download handler for saving the output table as an Excel file
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("output_table_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      write_xlsx(final_table_full(), file)
    }
  )
}

# Run the Shiny app
shinyApp(ui, server)
