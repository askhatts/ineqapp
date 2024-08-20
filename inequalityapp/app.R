library(shiny)
library(bslib)

# Создание пользовательского интерфейса
ui <- fluidPage(
  # Темная тема
  theme = bs_theme(bg = "#2B3E50", fg = "#EAECEE", primary = "#00B8D4"),
  
  # Хедер с логотипом и названием
  div(style = "padding: 10px; background-color: #00B8D4; text-align: center;",
      img(src = "logo.png", height = "50px", style = "vertical-align: middle; margin-right: 15px;"),
      span("Веб-приложение для оценки неравенства в расходах на здравоохранение из кармана",
           style = "font-size: 24px; color: white; vertical-align: middle;")
  ),
  
  # Основное содержание приложения
  tabsetPanel(
    id = "tabs",
    tabPanel("ГЛАВНАЯ",
             div(style = "display: flex; align-items: flex-start; padding: 20px;",
                 img(src = "anime.gif", style = "max-width: 700px; height: 400px; margin-right: 30px;"),
                 div(style = "color: #EAECEE;",
                     p("Данное веб-приложение служит для расчета индексов неравенства (Каквани, Джини, концентрации) в расходах на здравоохранении из кармана. Также приложение позволяет получить графическое изображение кривых Лоренца и концентрации для визуализации индексов неравенства."),
                     p("Расчет индексов и создание графиков выполняется с готовыми агрегированными данными на странице 'Расчет индексов неравенства'. Для подготовки данных Бюро национальной статистики Агентства по стратегическому планированию и реформам Республики Казахстан (БНС АСПиР РК) необходимо перейти на страницу 'Подготовка данных БНС АСПиР РК'.")
                 )
             )
    ),
    tabPanel("Подготовка данных БНС АСПиР РК",
             tags$iframe(src = "https://semey.shinyapps.io/preprocindividual/", height = "800px", width = "100%", frameborder = "0")
    ),
    tabPanel("Расчет индексов неравенства",
             tags$iframe(src = "https://semey.shinyapps.io/kkwn/", height = "800px", width = "100%", frameborder = "0")
    )
  ),
  
  # Футер
  div(style = "text-align:center; margin-top:40px; padding:20px; background-color:#00B8D4; color:white;",
      img(src = "logo.png", height = "40px"),
      p("© 2024 Веб-приложение для оценки неравенства в расходах на здравоохранение из кармана."),
      p("Выполнено в рамках грантового финансирования 'Жас Ғалым 22-24' Комитета науки и высшего образования Министерства Казахстана (№ AP15473445, 2022 г.)"),
      p("Контакт: askhat.shaltynov@smu.edu.kz | Телефон: +77055665380")
  )
)

# Серверная функция (в данном случае нет дополнительной логики)
server <- function(input, output, session) {
  # Здесь можно добавить серверную логику, если потребуется
}

# Запуск приложения
shinyApp(ui, server)


# Запуск приложения
shinyApp(ui, server)
