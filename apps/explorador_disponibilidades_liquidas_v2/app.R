library(shiny)
library(shinyWidgets)
library(lubridate)
library(highcharter)
library(shinydashboard)
library(reactable)
library(networkD3)
library(tidyverse)
theme_set(theme_minimal())


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

grafico_linhas_ug <- function(data, log = FALSE) {
  hc_data <- data %>%
    ungroup() %>%
    arrange(NO_UG, NO_DIA_COMPLETO_dmy) 
  
  if(log) {
    hc_data <- hc_data %>% mutate(disponibilidade_liquida = sign(disponibilidade_liquida) * log1p(abs(disponibilidade_liquida)))
  }
  
  hc_data %>%
    mutate(
      grupo = paste(NO_UG)
    ) %>%
    highcharter::hchart(
      type = "line",
      highcharter::hcaes(x = NO_DIA_COMPLETO_dmy, y = disponibilidade_liquida, group = grupo)
    )
}

grafico_linhas_ug_fonte <- function(data, log = FALSE) {
  hc_data <- data %>%
    ungroup() %>%
    arrange(NO_UG, NO_DIA_COMPLETO_dmy) 
  
  if(log) {
    hc_data <- hc_data %>% mutate(disponibilidade_liquida = sign(disponibilidade_liquida) * log1p(abs(disponibilidade_liquida)))
  }
  
  hc_data %>%
    mutate(
      grupo = paste(NO_UG, NO_FONTE_RECURSO)
    ) %>%
    highcharter::hchart(
      type = "line",
      highcharter::hcaes(x = NO_DIA_COMPLETO_dmy, y = disponibilidade_liquida, group = grupo)
    )
}

disponibilidades_liquidas_diarias <- read_rds("disponibilidades_liquidas_diarias.rds")
disponibilidades_liquidas_diarias_visao_ug <- read_rds("disponibilidades_liquidas_diarias_visao_ug.rds")

ui <- navbarPage(
  "Explorador - Disponibilidades Líquidas",
  tabPanel(
    "Série temporal",
    fluidRow(
      column(
        width = 5,
        shinyWidgets::pickerInput(
          "ug",
          label = "UG: ",
          width = "100%",
          multiple = TRUE,
          choices = unique(disponibilidades_liquidas_diarias$NO_UG),
          selected = unique(disponibilidades_liquidas_diarias$NO_UG)[c(1, 10)],
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
        width = 5,
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
      )
    ),
    fluidRow(
      column(
        width = 12,
        h1("Por Fonte e UG"),
        highchartOutput("grafico_ug_fonte", height = 620)
      )
    ),
    fluidRow(
      column(
        width = 12,
        h1("Por UG"),
        highchartOutput("grafico_ug")
      )
    )
  )
)

server <- function(input, output, session) {
  
  dados_ug_fonte <- reactive({
    validate(
      need(input$ug, "ug faltando"),
      need(input$fonte, "fonte faltando")
    )
    
    disponibilidades_liquidas_diarias %>%
      filter(
        NO_UG %in% input$ug, 
        NO_FONTE_RECURSO %in% input$fonte
      )
  })
  
  dados_ug <- reactive({
    validate(
      need(input$ug, "ug faltando")
    )
    
    disponibilidades_liquidas_diarias_visao_ug %>%
      filter(
        NO_UG %in% input$ug
      )
  })
  
  output$grafico_ug_fonte <- renderHighchart({
    grafico_linhas_ug_fonte(dados_ug_fonte(), log = FALSE)
  })
  
  output$grafico_ug <- renderHighchart({
    grafico_linhas_ug(dados_ug(), log = FALSE)
  })
}

shinyApp(ui, server)