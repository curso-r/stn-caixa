library(shiny)
library(tidyverse)
library(lubridate)

log_neg <- function(x) {
  sign(x) * log10(abs(x) + 1)
}

inv <- function(x) sign(x) * (10^abs(x) - 1)

ui <- fluidPage(
  fluidRow(
    plotly::plotlyOutput("dispersao")
  ),
  fluidRow(
    plotly::plotlyOutput("linhas") 
  ),
  fluidRow(
    reactable::reactableOutput("data")
  )
)

indicadores <- readRDS("../../data/indicadores.rds")
disponibilidade_liquida <- readRDS("../../data/disponibilidades_liquidas_diarias.rds")

server <- function(input, output, session) {
  
  output$dispersao <- plotly::renderPlotly({
    
    p <- indicadores %>% 
      ggplot(aes(y = "UG/FONTE", x = integral_sobre_media_dos_gastos, label = paste(NO_UG, NO_FONTE_RECURSO, sep = "/"))) +
      geom_jitter(size = 0.1) +
      labs(y = NULL) +
      scale_x_continuous(
        trans = scales::trans_new("log101p", log_neg, inv),
        breaks = c(-1, 0, 0.25, 0.5, 10^(0:8)),
        labels = scales::percent
      )
    
    
    p <- plotly::ggplotly(p)
    plotly::event_register(p, 'plotly_click')

    p
  })
  
  dt <- reactive({
    d <- plotly::event_data("plotly_click")
    
    print(d)
    
    if (is.null(d))
      return(NULL)
    
    indicadores[d$pointNumber + 1L,] %>% 
      ungroup() %>% 
      #select(NO_UG, NO_FONTE_RECURSO) %>% 
      left_join(disponibilidade_liquida, c("NO_UG", "NO_FONTE_RECURSO"))
  })
  
  output$linhas <- plotly::renderPlotly({
    
    
    p <- dt() %>% 
      ggplot(aes(x = NO_DIA_COMPLETO_dmy, y = disponibilidade_liquida, 
                 pgt = pagamento_diario, obg = obrigacoes_a_pagar_diario,
                 obg_ac = obrigacoes_a_pagar_diario_acumulado, saldo = saldo_diario_acumulado)) +
      geom_line() +
      scale_x_date(limits = dmy(c("01/01/2017", "31/12/2019")))
    
    plotly::ggplotly(p)
  })
  
  output$data <- reactable::renderReactable({
    dt() %>% 
      select(NO_UG, NO_FONTE_RECURSO, NO_DIA_COMPLETO_dmy, 
             saldo_diario_acumulado:disponibilidade_liquida, -paded, 
             soma_dos_gastos, integral, integral_sobre_media_dos_gastos) %>% 
      arrange(NO_DIA_COMPLETO_dmy) %>% 
      reactable::reactable(wrap = TRUE)
  })
  
}

shinyApp(ui, server)