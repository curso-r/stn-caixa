library(shiny)
library(shinyWidgets)
library(lubridate)
library(highcharter)
library(shinydashboard)
library(reactable)
library(networkD3)
library(tidyverse)
theme_set(theme_minimal())

sankey <- function(data, valores_positivos) {
  if(valores_positivos) {
    data = data %>% filter(valor > 0)
  } else {
    data = data %>% filter(valor < 0)
  }
  data = data %>%
    group_by(NO_FONTE_RECURSO, NO_UG) %>%
    summarise(
      valor = sum(abs(valor))
    ) %>%
    ungroup() %>%
    mutate(
      NO_FONTE_RECURSO = abrevia_palavras(NO_FONTE_RECURSO),
      NO_UG = abrevia_palavras(NO_UG),
      NO_FONTE_RECURSO_id = as.numeric(as.factor(NO_FONTE_RECURSO)) - 1,
      NO_UG_id = as.numeric(as.factor(NO_UG)) + max(NO_FONTE_RECURSO_id)
    )
  data_node = data.frame(node = data %>% select(NO_FONTE_RECURSO, NO_UG) %>% map(~sort(unique(.x))) %>% reduce(c))
  networkD3::sankeyNetwork(Links = data %>% mutate(), Nodes = data_node, Source = 'NO_FONTE_RECURSO_id',
                           Target = 'NO_UG_id', Value = 'valor', NodeID = 'node',
                           units = 'BRL')
}

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
      width = 5,
      shinyWidgets::pickerInput(
        "ug",
        label = "UG: ",
        width = "100%",
        multiple = TRUE,
        choices = unique(disponibilidades_liquidas_diarias$NO_UG),
        selected = unique(indicadores$NO_UG)[1:16],
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
    ),
    column(
      width = 2,
      selectInput("valor", "Valor: ", choices = c("saldo_diario_acumulado", "obrigacoes_a_pagar_diario_acumulado", "disponibilidade_liquida"))
    )
  ), 
  fluidRow(
    column(
      width = 4,
      switchInput("grafico1_log", "Escala log", value = FALSE, size = "mini")
    )
  ),
  
  # outputs
  fluidRow(
    column(
      width = 12,
      tabsetPanel(
        tabPanel(
          "Densidades",
          plotOutput("grafico1")
        ),
        tabPanel(
          "Por UG",
          uiOutput("grafico2")
        ),
        tabPanel(
          "Por Fonte e UG",
          uiOutput("grafico3")
        ),
        tabPanel(
          "Relação Fontes e UGs",
          box(title = "valores positivos", sankeyNetworkOutput("grafico4")),
          box(title = "valores negativos", sankeyNetworkOutput("grafico5"))
        ),
        tabPanel(
          "Sumário por UG",
          reactableOutput("tabela1")
        ),
        tabPanel(
          "Dados",
          downloadButton('downloadData', 'Download CSV'),
          reactableOutput("dados")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  
  
  ug <- debounce(reactive(input$ug), 1000)
  fonte <- debounce(reactive(input$fonte), 1000)
  
  dados <- reactive({
    validate(
      need(ug(), "ug faltando"),
      need(fonte(), "fonte faltando")
    )
    
    disponibilidades_liquidas_diarias %>%
      filter(
        NO_UG %in% ug(), 
        NO_FONTE_RECURSO %in% fonte()
      ) %>%
      rename(
        valor = !!sym(input$valor)
      )
  })
  
  
  output$grafico1 <- renderPlot({
    df <- dados() %>% filter(!paded)
    if(input$grafico1_log) {
      df <- df %>% mutate(valor = sign(valor) * log1p(abs(valor)))
    }
    
    p <- ggplot(df) +
      geom_density(aes(x = valor, colour = NO_UG))
    
    
    p
  })
  
  output$grafico2 <- renderUI({
    fluidPage(
      grafico_linhas(dados(), log = input$grafico1_log)
    )
  })
  
  output$grafico3 <- renderUI({
    validate(
      need(dados(), "dado faltando")
    )
    
    df <- dados()
    if(input$grafico1_log) {
      df <- df %>% mutate(valor = sign(valor) * log1p(abs(valor)))
    }
    
    tabpanels <- df %>%
      group_by(NO_UG) %>%
      dplyr::group_nest() %>%
      mutate(
        hc = purrr::map2(NO_UG, data, ~{
            grafico_linhas_fonte(.y %>% mutate(NO_UG = .x) %>% arrange(NO_DIA_COMPLETO_dmy), log = input$grafico1_log)
        }),
        panel = purrr::map2(NO_UG, hc, ~{
          tabPanel(
            title = .x,
            .y
          )
        })
      )
    
    do.call(tabsetPanel, tabpanels$panel)
    
  })
  
  observe({
    updateSelectInput(session, "ug_grafico4", choices = unique(dados()$NO_UG))
  })
  
  output$grafico4 <- renderSankeyNetwork({
    dados() %>% sankey(valores_positivos = TRUE)
  })
  
  output$grafico5 <- renderSankeyNetwork({
    dados() %>% sankey(valores_positivos = FALSE)
  })
  
  output$tabela1 <- renderReactable({
    sumario_por_ug %>% mutate_if(is.numeric, round) %>% reactable()
  })
  
  
  output$dados <- renderReactable({
    disponibilidades_liquidas_diarias %>% sample_n(1000) %>% reactable()
  })
  
  output$downloadData <- downloadHandler(
    filename = "disponibilidades_liquidas_diarias.csv",
    content = function(con) {
      write.csv(disponibilidades_liquidas_diarias, con)
    }
  )
}

shinyApp(ui, server)