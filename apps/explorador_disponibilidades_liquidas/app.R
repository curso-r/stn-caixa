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


grafico_linhas <- function(data, log = FALSE) {
  hc_data <- data %>%
    group_by(NO_DIA_COMPLETO, NO_UG) %>%
    summarise(
      valor = sum(valor)
    ) %>%
    ungroup() %>%
    arrange(NO_UG, NO_DIA_COMPLETO) 
  
  if(log) {
    hc_data <- hc_data %>% mutate(valor = sign(valor) * log1p(abs(valor)))
  }
  
  hc_data %>%
    highcharter::hchart(
      type = "line",
      highcharter::hcaes(x = NO_DIA_COMPLETO, y = valor, group = NO_UG)
    )
}

# disponibilidades_liquidas_diarias <- inner_join(
#   lim_saque %>%
#     group_by(
#       NO_DIA_COMPLETO,
#       NO_UG,
#       NO_ORGAO,
#       # NO_ITEM_INFORMACAO,
#       NO_FONTE_RECURSO
#     ) %>%
#     summarise(
#       saldo_diario = sum(SALDORITEMINFORMAO)
#     ),
#   obrigacoes %>%
#     rename(
#       NO_ORGAO = NO_ORGAO...16
#     ) %>%
#     group_by(
#       NO_DIA_COMPLETO,
#       NO_UG,
#       NO_ORGAO,
#       # NO_ITEM_INFORMACAO,
#       NO_FONTE_RECURSO
#     ) %>%
#     summarise(
#       obrigacoes_a_pagar = sum(SALDORITEMINFORMAO)
#     )
# ) %>%
#   mutate(
#     disponibilidade_liquida = saldo_diario - obrigacoes_a_pagar
#   ) %>%
#   filter(
#     !str_detect(NO_DIA_COMPLETO , "-09/00/")
#   ) %>%
#   ungroup %>%
#   mutate(
#     NO_DIA_COMPLETO = dmy(NO_DIA_COMPLETO)
#   ) %>%
#   padr::pad(group = c("NO_UG", "NO_ORGAO", "NO_FONTE_RECURSO")) %>%
#   mutate(
#     ano = year(NO_DIA_COMPLETO),
#     mes = month(NO_DIA_COMPLETO),
#     dia = day(NO_DIA_COMPLETO),
#     paded = !is.na(saldo_diario)
#   ) %>%
#   tidyr::fill(saldo_diario, obrigacoes_a_pagar, disponibilidade_liquida) 
# write_rds(disponibilidades_liquidas_diarias, path = "apps/explorador_disponibilidades_liquidas/disponibilidades_liquidas_diarias.rds")
disponibilidades_liquidas_diarias <- read_rds("disponibilidades_liquidas_diarias.rds")

sumario_por_ug <- disponibilidades_liquidas_diarias %>%
  filter(!paded) %>%
  group_by(NO_UG) %>%
  mutate(
    fontes_distintas = n_distinct(NO_FONTE_RECURSO)
  ) %>%
  gather(tipo_valor, valor, saldo_diario, obrigacoes_a_pagar, disponibilidade_liquida) %>%
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
    ),
    column(
      width = 2,
      selectInput("valor", "Valor: ", choices = c("saldo_diario", "obrigacoes_a_pagar", "disponibilidade_liquida"))
    ),
  ), 
  fluidRow(
    column(
      width = 4,
      switchInput("grafico1_log", "Escala log", value = TRUE, size = "mini")
    )
  ),
  
  # outputs
  fluidRow(
    column(
      width = 12,
      tabsetPanel(
        tabPanel(
          "Gráfico 1",
          plotOutput("grafico1")
        ),
        tabPanel(
          "Gráfico 2",
          highchartOutput("grafico2"),
        ),
        tabPanel(
          "Gráfico 3",
          plotOutput("grafico3"),
        ),
        tabPanel(
          "Gráfico 4",
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
        ),
        tabPanel(
          "Código R",
          includeMarkdown("codigo.Rmd")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  
  dados <- reactive({
    validate(
      need(input$ug, "ug faltando"),
      need(input$fonte, "fonte faltando")
    )
    
    disponibilidades_liquidas_diarias %>%
      filter(
        NO_UG %in% input$ug, 
        NO_FONTE_RECURSO %in% input$fonte
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
  
  output$grafico2 <- renderHighchart({
    grafico_linhas(dados(), log = input$grafico1_log)
  })
  
  output$grafico3 <- renderPlot({
    df <- dados() %>%
      group_by(dia, mes, ano, NO_DIA_COMPLETO, NO_UG) %>%
      summarise(
        valor = sum(valor)
      ) %>%
      ungroup() 
    
    if(input$grafico1_log) {
      df <- df %>% mutate(valor = sign(valor) * log1p(abs(valor)))
    }
    
    df %>%
      ggplot(aes(x = dmy(paste(dia, mes, "1900", sep = "-")), y = valor, colour = factor(ano))) +
      geom_line() +
      facet_grid(rows = vars(NO_UG))
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