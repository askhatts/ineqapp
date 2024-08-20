
library(rsconnect)

# Замените 'YOUR_ACCOUNT' и 'YOUR_TOKEN' на ваши учетные данные
rsconnect::setAccountInfo(name='semey', token='E0FF219555C13A10E0E5158F2E0A90C4', secret='S1vefjyK/aGx0ykso0+1YxRRobFPOoayOiPr2vQc')

# Перейдите в директорию, где находится ваш код приложения №1
setwd("D:/Jas_galym/MyShinyApp/net/preprochousehold/")

# Разверните приложение
rsconnect::deployApp()
tags$iframe(src = "https://semey.shinyapps.io/hhprep", height = "800px", width = "100%", frameborder = "0")



setwd("D:/Jas_galym/MyShinyApp/net/preprocindividual")
# Разверните приложение
rsconnect::deployApp()


setwd("D:/Jas_galym/MyShinyApp/net/kkwn")
rsconnect::deployApp()


setwd("D:/Jas_galym/MyShinyApp/net/inequalityapp")
rsconnect::deployApp()
