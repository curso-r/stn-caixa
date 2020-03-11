library(shiny)
library(shinydashboard)
library(shinyjs)
library(tidyverse)
library(lubridate)

indices_ug_fonte <- readRDS("indices_ug_fonte.rds")
disponibilidades_liquidas_diarias <- read_rds("disponibilidades_liquidas_diarias.rds")

ui <- dashboardPage(
  dashboardHeader(title = "Explorador de Índices"),
  dashboardSidebar(
    selectInput(inputId = "x", label = "Ordenar por:", choices = c("IADL", "IPDL", "DLP"), selected = "IADL"),
    selectInput(inputId = "tam", label = "Tamanho por:", choices = c("IADL", "IPDL", "DLP"), selected = "IPDL")
  ),
  dashboardBody(
    shinyjs::useShinyjs(),
    fluidRow(
      shinydashboard::box(
        title = "Combinações UG/Fonte",
        width = 12,
        "Cada UG/Fonte está sendo representada no gráfico abaixo.",
        "Clique em um ponto para visualizar a disponibilidade líquida.",
        "Os pontos estão estão ordenados da esquerda para direita de acordo com o indicador selecionado.",
        "O tamanho dos pontos está relacionado ao indicador selecionado.",
        r2d3::d3Output("d3")
      )
    ),
    fluidRow(
      shinydashboard::box(
        title = "Ug/Fonte",
        width = 12,
        fluidRow(
          infoBoxOutput("iadl"),
          infoBoxOutput("ipdl"),
          infoBoxOutput("dlp")
        ),
        plotOutput("g_disponibilidade")
      )
    )
  )
)

server <- function(input, output, session) {
  
  output$d3 <- r2d3::renderD3({
    
    data <- indices_ug_fonte %>% 
      transmute(
        IPDL = ipdl, 
        IADL = ifelse(iadl>1, 1, iadl), 
        DLP = dlp,
        IPDL_rank = percent_rank(ipdl), 
        IADL_rank = percent_rank(ifelse(iadl>1, 1, iadl)), 
        DLP_rank = percent_rank(dlp),
        NO_UG, 
        NO_FONTE_RECURSO
      )
    
    shinyjs::runjs("svg.selectAll('circle').remove();")
    
    r2d3::r2d3(data, "x.js", d3_version =  "3", 
               options = list(x = input$x, tam = input$tam))
    
    #shinyjs::runjs("force.call()")
    
  })
  
  ug_fonte <- reactive({
    
    indices_ug_fonte %>% 
      filter(
        NO_UG == isolate(input$ug),
        NO_FONTE_RECURSO == req(input$fonte)
      )
      
  })
  
  d_liquida <- reactive({
    ug_fonte() %>% 
      left_join(
        disponibilidades_liquidas_diarias,
        by = c("NO_UG", "NO_ORGAO", "NO_FONTE_RECURSO")
      ) %>% 
      filter(
        NO_DIA_COMPLETO_dmy <= dia,
        NO_DIA_COMPLETO_dmy >= dia - days(365)
      ) %>% 
      ungroup()
  })
  
  output$g_disponibilidade <- renderPlot({
    
    d_liquida() %>% 
      ggplot(aes(x = NO_DIA_COMPLETO_dmy, y = disponibilidade_liquida)) +
      geom_line() +
      geom_area(alpha = 0.1) +
      facet_wrap(~NO_UG + NO_FONTE_RECURSO, scales = "free") +
      scale_y_continuous(labels = scales::label_number()) +
      labs(
        y = "Disponibilidade Líquida (R$)",
        x = "Data"
      ) +
      theme_bw() +
      expand_limits(y = 0)
    
  })
  
  output$iadl <- renderInfoBox({
    infoBox("IADL", value = scales::label_number(0.00001)(ug_fonte()$iadl))
  })
  
  output$ipdl <- renderInfoBox({
    infoBox("IPDL", value = scales::label_number(0.00001)(ug_fonte()$ipdl))
  })
  
  output$dlp <- renderInfoBox({
    infoBox("DLP", value = scales::label_number()(ug_fonte()$dlp))
  })
  
  
}

shinyApp(ui, server)