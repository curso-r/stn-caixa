library(shiny)
library(tidyverse)
library(sparkline)
library(reactable)
library(highcharter)
library(magrittr)
library(shinyjs)
library(shinycssloaders)
participantes <- c("athos", "barba", "lucas", "tiago", "william", "renata", "daniel")
ts_das_disponibilidades_liquidas <- readRDS("ts_das_disponibilidades_liquidas.rds")

# -- NÃO RODAR DE NOVO -- CRIAÇÃO INICIAL DA TABELA DE ANOTACOES -- NÃO RODAR DE NOVO -----------------------------------
# set.seed(1)
# library(magrittr)
# participantes <- tibble(
#   participante = c("athos", "barba","daniel", "tiago",  "william", "lucas", "renata"),
#   ids = list(1:856, 151:500, 301:600, 451:800, 551:856, c(1:250, 701:856), sample.int(856, 300))
# )
# ts_das_disponibilidades_liquidas <- readRDS(file = "data/ts_das_disponibilidades_liquidas.rds")
# anotacoes <- ts_das_disponibilidades_liquidas %>%
#   select(id) %>%
#   mutate(rotulo_atual = "(Não rotulado)")
# saveRDS(anotacoes, file = "apps/app_para_rotular_as_series_temporais_das_disponibilidades_liquidas/anotacoes.rds")
# participantes %$% walk2(participante, ids, ~saveRDS(anotacoes %>% slice(.y), file = glue::glue("apps/app_para_rotular_as_series_temporais_das_disponibilidades_liquidas/anotacoes_{.x}.rds")))
# saveRDS(anotacoes, file = "data/anotacoes.rds")
# participantes %$% walk2(participante, ids, ~saveRDS(anotacoes %>% slice(.y), file = glue::glue("data/anotacoes_{.x}.rds")))
# write_csv(anotacoes, path = "data/anotacoes.csv")
# participantes %$% walk2(participante, ids, ~write_csv(anotacoes %>% slice(.y), path = glue::glue("data/anotacoes_{.x}.csv")))
# write_csv(anotacoes, path = "apps/app_para_rotular_as_series_temporais_das_disponibilidades_liquidas/anotacoes.csv")
# participantes %$% walk2(participante, ids, ~write_csv(anotacoes %>% slice(.y), path = glue::glue("apps/app_para_rotular_as_series_temporais_das_disponibilidades_liquidas/anotacoes_{.x}.csv")))


ui <- fluidPage(
  h1("App para rotular as curvas como 'empoçamento', 'saudável', etc."),
  selectInput("anotador", "Escolha um anotador:", choices = c("", participantes), selected = ""),
  conditionalPanel(
    condition = "input.anotador != ''",
    tabsetPanel(
      
      tabPanel(
        "Rotulador",
        fluidRow(
          column(
            width = 4,
            reactable::reactableOutput("tabela"),
            downloadButton("download", "Baixar anotações")
          ),
          
          column(
            width = 8,
            highchartOutput("grafico"),
            selectizeInput("rotulo", "Rótulo", choices = c("Não sei", "Empoçamento estagnado", 
                                                           "Empoçamento crescente", "Empoçamento decrescente", 
                                                           "Saudável", "Saldo negativo", "Outro", "Rever dados", "(Não rotulado)"),
                           options = list(create = TRUE))
            
          )
        )
      )
    )
  )
)


server <- function(input, output, session) {
  anotacoes <- reactiveVal()
  id_selecionado <- reactiveVal()
  atualizou <- reactiveVal(0)
  
  # se algo mudar, tudo tem que atualizar
  observe({
    input$rotulo
    input$selected_row
    atualizou(runif(1))
  })
  
  observeEvent(input$anotador, {
    arq <- paste0("anotacoes_", input$anotador, ".csv")
    if(file.exists(arq)) {
      anot <- read_csv(file = arq) %>% 
        mutate(rotulo_atual = ifelse(is.na(rotulo_atual), "(Não rotulado)", rotulo_atual))
      
      anotacoes(anot)
    }
  })
  
  observeEvent(input$selected_row, {
    id <- anotacoes() %>% slice(input$selected_row)
    id_selecionado(id$id)
  })
  
  dados <- reactive({
    validate(
      need(input$anotador, "anotador faltando"),
      need(input$anotador != "", "anotador faltando")
    )
    ts_das_disponibilidades_liquidas %>%
      inner_join(anotacoes(), by = "id") %>%
      mutate(rotulo_atual = if_else(is.na(rotulo_atual), "(Não rotulado)", rotulo_atual))
  })
  
  output$tabela <- reactable::renderReactable({
    aff <- atualizou()
    dados() %>% 
      select(
        id,
        rotulo_atual
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
        rowStyle = reactable::JS("function(a, b) {if(a.row.rotulo_atual != '(Não rotulado)') return {backgroundColor: '#8cff57'}}"),
        columns = list(
          rotulo_atual = colDef(html = TRUE, align = "center")
        )
      )
  })
  
  # when rotule changed
  observeEvent(atualizou(), {
    anotacao_nova <- anotacoes()
    if(!is.null(anotacao_nova)) {
      anotacao_nova[input$selected_row, "rotulo_atual"] <- input$rotulo
      anotacoes(anotacao_nova)
      save(anotacoes())
    }
  })
  
  # save
  save <- function(anotacoes) {
    if(nrow(anotacoes) > 0) {
      arq <- paste0("anotacoes_", input$anotador, ".csv")
      write_csv(anotacoes, path = arq)
    }
  }
  
  output$grafico <- renderHighchart({
    validate(
      need(id_selecionado(), "linha não selecionada.")
    )
    ts <- ts_das_disponibilidades_liquidas %>%
      filter(id %in% id_selecionado()) %$%
      serie_temporal_random_crop[[1]] %$% xts::xts(round(disponibilidade_liquida, 8), NO_DIA_COMPLETO_dmy)
    highchart(type = "stock") %>%
      hc_add_series(ts, type = "area") %>%
      hc_plotOptions(area = list(fillOpaticy = 0.3))
  })
  
  
  output$debug <- renderPrint({
    aff <- satualizou()
    a <- reactiveValuesToList(input)
    a
  })
  
  output$download <- downloadHandler(
    filename = function() {
      paste('anotacoes-', Sys.Date(), '.csv', sep='')
    },
    content = function(con) {
      lista_anotacoes <- purrr::map(participantes, ~read_csv(file = paste0("anotacoes_", .x, ".csv")) %>% mutate(rotulo_atual = ifelse(is.na(rotulo_atual), "(Não rotulado)", rotulo_atual)) %>% set_names(c("id", .x)))
      
      lista_anotacoes <- purrr::reduce(lista_anotacoes, ~full_join(.x, .y, by = "id"), .init = ts_das_disponibilidades_liquidas) %>% 
        mutate_at(vars(participantes), ~coalesce(., "(Não rotulado)")) %>% 
        select(-serie_temporal_random_crop, -serie_temporal)
      readr::write_csv(lista_anotacoes, con)
    }
  )
}

shinyApp(ui, server)