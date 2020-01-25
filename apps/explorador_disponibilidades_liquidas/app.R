library(shiny)
library(shinyWidgets)
library(lubridate)
library(highcharter)
library(shinydashboard)
library(reactable)
library(networkD3)
library(tidyverse)
theme_set(theme_minimal())

trinta_e_uns_de_dezembro <- tibble(
  NO_DIA_COMPLETO_dmy = as.Date(c("2017-12-31", "2018-12-31", "2019-12-31"))
)


abrevia_palavras <- function(str) {
  str %>%
    str_replace_all("SUPERINTENDENCIA", "SUPT") %>%
    str_replace_all("REGIONAL", "REG") %>%
    str_replace_all("ADMINISTRACAO", "ADM") %>%
    str_replace_all("DIRETORIA", "DIR") %>%
    str_replace_all("COORDENACAO", "COORD") %>%
    str_replace_all("NACIONAL", "NAC") %>%
    str_replace_all("FINANCEIROS", "FIN") %>%
    str_replace_all("PROGNOSTICOS", "PROG") %>%
    str_replace_all("ESTADO", "EST") %>%
    str_replace_all("POLITICAS", "POL") %>%
    str_replace_all("RECURSOS", "REC") %>%
    str_replace_all("ORDINARIOS", "ORD") %>%
    str_replace_all("ARRECADADOS", "ARREC")
}

grafico_linhas_fonte <- function(data, log = FALSE) {
  hc_data <- data %>%
    arrange(NO_UG, NO_DIA_COMPLETO_dmy) 
  
  if(log) {
    hc_data <- hc_data %>% mutate(valor = sign(valor) * log1p(abs(valor)))
  }
  
  hc_data %>%
    highcharter::hchart(
      type = "line",
      highcharter::hcaes(x = NO_DIA_COMPLETO_dmy, y = valor, group = NO_FONTE_RECURSO)
    )
}

grafico_linhas <- function(data, log = FALSE) {
  hc_data <- data %>%
    group_by(NO_DIA_COMPLETO_dmy, NO_UG) %>%
    summarise(
      valor = sum(valor)
    ) %>%
    ungroup() %>%
    arrange(NO_UG, NO_DIA_COMPLETO_dmy) 
  
  if(log) {
    hc_data <- hc_data %>% mutate(valor = sign(valor) * log1p(abs(valor)))
  }
  
  hc_data %>%
    highcharter::hchart(
      type = "line",
      highcharter::hcaes(x = NO_DIA_COMPLETO_dmy, y = valor, group = NO_UG)
    )
}

disponibilidades_liquidas_diarias <- read_rds("disponibilidades_liquidas_diarias.rds")
indicadores <- read_rds("indicadores.rds")

sumario_por_ug <- disponibilidades_liquidas_diarias %>%
  filter(!paded) %>%
  group_by(NO_UG) %>%
  mutate(
    fontes_distintas = n_distinct(NO_FONTE_RECURSO)
  ) %>%
  gather(tipo_valor, valor, saldo_diario, obrigacoes_a_pagar_diario, disponibilidade_liquida) %>%
  group_by(NO_UG, tipo_valor) %>%
  summarise(
    media = mean(valor),
    desvpad = sd(valor),
    fontes_distintas = first(fontes_distintas)
  ) %>%
  pivot_wider(values_from = c(media, desvpad), names_from = tipo_valor)

ui <- fluidPage(
  h1("Explorador - Disponibilidades Líquidas"),
  fluidRow(
    column(
      width = 4,
      shinyWidgets::pickerInput(
        "orgao",
        label = "ORGAO: ",
        width = "100%",
        multiple = TRUE,
        choices = unique(disponibilidades_liquidas_diarias$NO_ORGAO),
        selected = unique(indicadores$NO_ORGAO)[1:1],
        options = shinyWidgets::pickerOptions(
          actionsBox = TRUE, 
          deselectAllText = "Limpar seleção", 
          noneSelectedText = "Nenhum ORGAO selecionado", 
          noneResultsText = "Nenhum resultado encontrado",
          selectAllText = "Selecionar todos"
        )
      )
    ),
    column(
      width = 4,
      shinyWidgets::pickerInput(
        "ug",
        label = "UG: ",
        width = "100%",
        multiple = TRUE,
        choices = unique(disponibilidades_liquidas_diarias$NO_UG),
        selected = unique(indicadores$NO_UG)[1:1],
        options = shinyWidgets::pickerOptions(
          actionsBox = TRUE, 
          deselectAllText = "Limpar seleção", 
          noneSelectedText = "Nenhuma UG selecionada", 
          noneResultsText = "Nenhum resultado encontrado",
          selectAllText = "Selecionar todos"
        )
      )
    ),
    column(
      width = 4,
      shinyWidgets::pickerInput(
        "fonte",
        label = "FONTE DE RECURSOS: ",
        width = "100%",
        multiple = TRUE,
        choices = unique(disponibilidades_liquidas_diarias$NO_FONTE_RECURSO),
        selected = unique(disponibilidades_liquidas_diarias$NO_FONTE_RECURSO),
        options = shinyWidgets::pickerOptions(
          actionsBox = TRUE, 
          deselectAllText = "Limpar seleção", 
          noneSelectedText = "Nenhuma fonte selecionada", 
          noneResultsText = "Nenhum resultado encontrado",
          selectAllText = "Selecionar todos"
        )
      )
    ),
    
    column(
      width = 2,
      selectInput("valor", "Valor: ", choices = c("saldo_diario_acumulado", "obrigacoes_a_pagar_diario_acumulado", "disponibilidade_liquida"), selected = "disponibilidade_liquida")
    )
  ), 
  
  # outputs
  fluidRow(
    column(
      width = 12,
      tabsetPanel(
        tabPanel(
          "Por UG",
          plotly::plotlyOutput("grafico2", height = 700)
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  orgao <- debounce(reactive(input$orgao), 1000)
  ug <- debounce(reactive(input$ug), 1000)
  fonte <- debounce(reactive(input$fonte), 1000)
  
  observeEvent(orgao(), {
    
    df_filtrado <- disponibilidades_liquidas_diarias %>% filter(NO_ORGAO %in% orgao())
    shinyWidgets::updatePickerInput(
      session,
      "ug",
      choices = unique(df_filtrado$NO_UG)
    )
    
    shinyWidgets::updatePickerInput(
      session,
      "fonte",
      label = "FONTE DE RECURSOS: ",
      choices = unique(df_filtrado$NO_FONTE_RECURSO)
    )
  })
  
  dados <- reactive({
    validate(
      need(orgao(), "orgao faltando"),
      need(ug(), "ug faltando"),
      need(fonte(), "fonte faltando")
    )
    
    disponibilidades_liquidas_diarias %>%
      filter(
        NO_ORGAO %in% orgao(),
        NO_UG %in% ug(), 
        NO_FONTE_RECURSO %in% fonte()
      ) %>%
      rename(
        valor = !!sym(input$valor)
      )
  })
  
  
  output$grafico2 <- plotly::renderPlotly({
      
      p <- dados() %>%
        ungroup %>%
        mutate(
          valor = valor/1e6
        ) %>%
        ggplot(aes(y = valor, x = NO_DIA_COMPLETO_dmy)) +
        geom_line(aes(group = NO_UG), colour = "salmon", show.legend = FALSE) +
        facet_wrap(~NO_FONTE_RECURSO + NO_ORGAO, scales = "free_y") +
        geom_vline(data = trinta_e_uns_de_dezembro, aes(xintercept = NO_DIA_COMPLETO_dmy), colour = "purple", linetype = "dashed", size = 0.2) +
        scale_y_continuous(labels = scales::dollar_format(0.1, prefix = "", big.mark = ".", decimal.mark = ",", suffix = "")) +
        labs(x = "Data", y = "valor (milhões de reais)") +
        ylim(c(0, NA))
      
      plotly::ggplotly(p)
  })
  
}

shinyApp(ui, server)