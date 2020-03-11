library(shiny)
library(tidyverse)
library(sparkline)
library(reactable)
library(highcharter)
library(shinyWidgets)
library(shinydashboard)
library(magrittr)
library(shinyjs)
library(shinycssloaders)
ts_das_disponibilidades_liquidas_com_indicadores_final <- readRDS("ts_das_disponibilidades_liquidas_com_indicadores_final.rds") %>% filter(n > 300)
indicadores_disponiveis <- c(
  "integral_sobre_media_dos_gastos",
  "disponibilidade_estritamente_crescente",
  "iadl",
  "valor_nominal",
  "valor_nominal_conservador",
  "indicador_tempo",
  "suspeita_de_empocamento"
)

ui <- fluidPage(
  useShinydashboard(),
  tags$script(src = "logneg.js"),
  h1("Explorador de Disponibilidades Líquidas"),
  tabsetPanel(
    tabPanel(
      "Painel principal",
      fluidRow(
        column(
          width = 8,
          reactable::reactableOutput("tabela"),
          highchartOutput("st")
        ),
        column(
          width = 4,
          highchartOutput("dispersao", height = 320),
          fluidRow(
            column(
              offset = 1,
              width = 4,
              shiny::selectizeInput(
                "indice_x", 
                "Eixo X", 
                choices = indicadores_disponiveis,
                selected = indicadores_disponiveis[1]
              )
            ),
            column(
              width = 1,
              checkboxInput("type_x", "log", value = FALSE)
            ),
            column(
              width = 4,
              shiny::selectizeInput(
                "indice_y", 
                "Eixo Y", 
                choices = indicadores_disponiveis,
                selected = indicadores_disponiveis[2]
              )
            ),
            column(
              width = 1,
              checkboxInput("type_y", "log", value = FALSE)
            )
          ),
          reactable::reactableOutput("info")
        )
      )
    ),
    tabPanel(
      "debug",
      verbatimTextOutput("debug")
    )
  )
)


server <- function(input, output, session) {
  anotacoes <- reactiveVal()
  id_selecionado <- reactiveVal()
  atualizou <- reactiveVal(0)
  
  # se algo mudar, tudo tem que atualizar
  observe({
    input$selected_row
    atualizou(runif(1))
    input$dispersao_click$x
  })
  
  observeEvent(input$selected_row, {
    id <- dados() %>% slice(input$selected_row)
    id_selecionado(id$id)
  })
  
  observeEvent(input$dispersao_click, {
    id <- dados() %>%
      dplyr::mutate(
        x := !!rlang::sym(input$indice_x),
        y := !!rlang::sym(input$indice_y)
      ) %>% 
      filter(near(x, input$dispersao_click$x, .Machine$double.eps^0.3), near(y, input$dispersao_click$y, .Machine$double.eps^0.3)) %>%
      slice(1)
    id_selecionado(id$id)
  })
  
  dados <- reactive({
    ts_das_disponibilidades_liquidas_com_indicadores_final
  })
  
  output$tabela <- reactable::renderReactable({
    aff <- atualizou()
    dados() %>% 
      select(
        NO_UG,
        NO_ORGAO,
        NO_FONTE_RECURSO,
        integral_sobre_media_dos_gastos,
        disponibilidade_estritamente_crescente,
        iadl,
        valor_nominal,
        valor_nominal_conservador,
        indicador_tempo,
        suspeita_de_empocamento
      ) %>%
      reactable::reactable(
        selectionId = "selected_row",
        resizable = TRUE,
        showPageSizeOptions = TRUE,
        onClick = "select",
        highlight = TRUE,
        compact = TRUE,
        selection = "single",
        filterable = TRUE,
        wrap = FALSE,
        defaultColDef = colDef(format = colFormat(digits = 3)),
        defaultPageSize = 10,
        rowStyle = reactable::JS("function(a, b) {if(a.row.NO_UG != '(Não rotulado)') return {backgroundColor: '#ccddff'}}"),
        columns = list(
          NO_UG = colDef(html = TRUE, align = "center")
        )
      )
  })
  
  output$st <- renderHighchart({
    validate(
      need(id_selecionado(), "linha não selecionada.")
    )
    ts <- dados() %>%
      filter(id %in% id_selecionado()) %$%
      serie_temporal_random_crop[[1]] %$% xts::xts(round(disponibilidade_liquida, 8), NO_DIA_COMPLETO_dmy)
    highchart(type = "stock") %>%
      hc_add_series(ts, type = "area") %>%
      hc_plotOptions(area = list(fillOpaticy = 0.3))
  })
  
  output$dispersao <- renderHighchart({
    dados() %>%
      dplyr::mutate(
        x := !!rlang::sym(input$indice_x),
        y := !!rlang::sym(input$indice_y)
      ) %>%
      select(x, y) %>%
      highcharter::hchart(
        type = "scatter",
        highcharter::hcaes(x = x, y =  y)
      ) %>%
      hc_add_event_point(event = "click") %>% 
      hc_yAxis(type = ifelse(input$type_y, "logarithmic", "linear"),
               allowNegativeLog = TRUE) %>% 
      hc_xAxis(type = ifelse(input$type_x, "logarithmic", "linear"),
               allowNegativeLog = TRUE)
  })
  
  output$info <- reactable::renderReactable({
    validate(
      need(id_selecionado(), "linha não selecionada.")
    )
    aff <- atualizou()
    dados() %>%
      filter(id %in% id_selecionado()) %>% 
      select(
        NO_UG,
        NO_ORGAO,
        NO_FONTE_RECURSO,
        integral_sobre_media_dos_gastos,
        disponibilidade_estritamente_crescente,
        iadl,
        valor_nominal,
        valor_nominal_conservador,
        indicador_tempo,
        suspeita_de_empocamento
      ) %>%
      gather("variável", "valor", everything()) %>%
      reactable::reactable(
        resizable = TRUE,
        showPageSizeOptions = FALSE,
        highlight = TRUE,
        compact = TRUE,
        wrap = FALSE,
        defaultColDef = colDef(format = colFormat(digits = 3)),
        defaultPageSize = 10,
        rowStyle = reactable::JS("function(a, b) {if(a.row.valor != '(Não rotulado)') return {backgroundColor: '#ccddff'}}")
      )
  })
  
  output$debug <- renderPrint({
    aff <- atualizou()
    a <- reactiveValuesToList(input)
    a
  })
}

shinyApp(ui, server)