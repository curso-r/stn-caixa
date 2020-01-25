library(shiny)
library(tidyverse)
library(sparkline)
library(reactable)
js <- "
$(document).on('shiny:value', function(e) {
  if(e.name === 'tabela'){
    setTimeout(function(){Shiny.bindAll(document.getElementById('tabela'))}, 0);
  }
});
"

ui <- fluidPage(
  tags$head(tags$script(js)),
  h1("App para rotular as curvas como 'empoçamento', 'saudável', etc."),
  fluidRow(
    reactable::reactableOutput("tabela")
  )
)

ts_das_disponibilidades_liquidas <- readRDS("ts_das_disponibilidades_liquidas.rds")
ts_das_disponibilidades_liquidas <- ts_das_disponibilidades_liquidas %>%
  mutate(
    rotulo = map_chr(id, ~ as.character(selectInput(inputId = .x, label = NULL, choices = 1:5)))
  )

print(head(ts_das_disponibilidades_liquidas))
server <- function(input, output, session) {
  
  output$tabela <- reactable::renderReactable({
    
    ts_das_disponibilidades_liquidas %>% 
      select(
        NO_ORGAO,
        NO_UG,
        NO_FONTE_RECURSO,
        serie_temporal,
        rotulo,
        disponibilidade_estritamente_crescente,
        disponibilidade_mais_recente,
        integral,
        integral_sobre_media_dos_gastos
      ) %>%
      slice(1:30) %>%
      reactable::reactable(
        filterable = TRUE,
        wrap = TRUE,
        defaultColDef = colDef(format = colFormat(digits = 3)),
        defaultPageSize = 100,
        columns = list(
          rotulo = colDef(
            html = TRUE, 
            align = "center"
          ),
          serie_temporal = colDef(
            width = 300, 
            cell = function(values) {
            min_y <- min(0, max(-1e9, min(values$disponibilidade_liquida, na.rm = TRUE)))
            max_y <- max(0, min(1e9, max(values$disponibilidade_liquida, na.rm = TRUE)))
            values %>% 
              select(NO_DIA_COMPLETO_dmy, disponibilidade_liquida) %>% 
              as.ts() %>% 
              sparkline(
                width = "100%", 
                height = "100%", 
                refLineY = 0,
                chartRangeMin = min_y,
                chartRangeMax = max_y)
          })
        ))
  })
}

shinyApp(ui, server)