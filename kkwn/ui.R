library(shiny)

# Define UI for data upload app ----
ui <- fluidPage(
  
  # App title ----
  titlePanel("Расчет индексов неравенства:"),
  
  # Subheading ----
  p("Данное приложение служит для расчета индекса Каквани. Индекс Каквани (англ. Kakwani index, Kakwani's progressivity index) ― показатель прогрессивности социального вмешательства, оценивающий неравенство между доходами и расходами физических лиц, чаще всего используется для измерения вертикального неравенства расходов на медицинскую помощь."),
  p("Для расчета индексов нужно загрузить таблицу с данными, выбрать необходимые столбцы, и нажать кнопку 'Нарисовать график'. Рассчитанные индексы появятся автоматически."),
  
  # Sidebar layout with input and output definitions ----
  sidebarLayout(
    
    # Sidebar panel for inputs ----
    sidebarPanel(
      
      # Input: Select a file ----
      fileInput("data", "Добавить таблицу:",
                multiple = FALSE,
                accept = c(
                  "application/x-dta",
                  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                  "application/dbase"
                )),
      
      # Include clarifying text ----
      helpText("СПРАВКА: Для выбора табличных данных о 
               расходах и доходах домохозяйств в форматах 
               .xlsx, .dta, .dbf. нажмите Browse"),
      
      # Horizontal line ----
      tags$hr(),
      
      # Input: Select number of rows to display ----
      radioButtons("disp", "Вид таблицы",
                   choices = c("Отображать только первые 10 строк" = "head"),
                   selected = "head"),
      
      # Select columns for further operations ----
      selectInput("x", "Расходы", choices = NULL),
      selectInput("y", "Доходы", choices = NULL),
      selectInput("w", "Выборочные веса", choices = NULL),
      
      # Include clarifying text ----
      helpText("СПРАВКА: Для расчетов необходимо выбрать столбцы с 1) доходами, 2) расходами, 
               и 3) выборочными весами."),
      
      # Button to trigger plotting
      actionButton("plot_button", "Нарисовать график"),
      
      # Include clarifying text ----
      helpText("СПРАВКА: На выходе приложение расчитывает 
              и выводит в панель справа индексы: концентрации, Джини, Каквани, 
               а также графическое представление индексов. Для отображения 
               графика нажмите 'Нарисовать график'")
      
    ),
    
    # Main panel for displaying outputs ----
    mainPanel(
      
      # Output: Data file ----
      tableOutput("contents"),
      
      # Output: Results ----
      textOutput("results"),
      
      # Output: Plot ----
      plotOutput("plot"),
      
      helpText('СПРАВКА: Индекс Каквани колеблется от − 2 до 1; 
               Отрицательные значения указывают на регрессивную систему финансирования, когда с ростом дохода падает доля платежей (платежи за мед. услуги составляют большую долю в доходах бедных семей), т.е. кривая концентрации ниже кривой Лоренца. 
               Положительные значения — на прогрессивную систему, когда с ростом дохода растёт доля платежей, значит система прогрессивная, т.е. кривая концентрации выше кривой Лоренца; 
               а значения, близкие к нулю — на пропорциональную систему. Пропорциональное финансирование, при котором индекс Каквани теоретически равен нулю, соответствует ситуации, 
               когда кривая Лоренца и кривая концентрации накладываются друг на друга. В некоторых случаях индекс Каквани может быть равен нулю при пересечении двух кривых.')
      
    )
  ),
  
  # Add image at the bottom and center it
  wellPanel(
    tags$h4("Справочная иллюстрация", align = "center"),
    tags$div(
      style = "text-align: center;",
      tags$img(src = "ex.png", height = "500px", width = "auto")
    )
  )
)
