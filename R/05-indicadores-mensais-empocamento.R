# Os indicadores que vamos calcular estão relacionados à uma janela
# de tempo.
# Vamos usar 1 ano de histórico em geral.

# Para simplificar a análise vamos calcular o índice apenas para aquelas combinacoes UG/FOnte
# que possuem pelo menos 365 dias de histórico.

library(tidyverse)

disponibilidades_liquidas_diarias <- read_rds("data/disponibilidades_liquidas_diarias.rds")

disponibilidades_liquidas_diarias <- disponibilidades_liquidas_diarias %>% 
  group_by(NO_UG, NO_FONTE_RECURSO) %>% 
  filter(n() >= 365) %>% 
  ungroup()

calc_disponibilidade_estritamente_crescente <- function(disponibilidade_liquida, dias_no_periodo, NO_DIA_COMPLETO_dmy) {
  proporcao_de_disponibilidade_liquida_negativa <- mean(disponibilidade_liquida < 0)
  disponibilidade_mais_recente <- disponibilidade_liquida[which.max(NO_DIA_COMPLETO_dmy)]
  p1 <- mean(diff(disponibilidade_liquida)  > 0)
  p2 <- mean(abs(diff(disponibilidade_liquida)[diff(disponibilidade_liquida) < 0]) < (sd(disponibilidade_liquida) + 0.001)/100) 
  ifelse(is.nan(p1), 0, p1) + ifelse(is.nan(p2), 0, p2)
}

calc_indicador_integral_sobre_media_dos_gastos <- function(disponibilidade_liquida, pagamento_diario) {
  integral <- mean(disponibilidade_liquida)
  soma_dos_gastos <- sum(pagamento_diario)
  soma_dos_gastos <- if_else(abs(soma_dos_gastos) < 1, 1, soma_dos_gastos)
  integral/soma_dos_gastos
}

calc_indicador_valor_nominal <- function(disponibilidade_liquida) {
  mean(disponibilidade_liquida)
}

calc_indicador_valor_nominal_conservador <- function(disponibilidade_liquida, pagamentos_diarios) {
  mean(disponibilidade_liquida) - mean(pagamentos_diarios)*30
}

calc_indicador_tempo <- function(disponibilidades_liquida) {
  sum(disponibilidades_liquida > 0)/length(disponibilidades_liquida)
}

calc_iadl <- function(disponibilidade_liquida, lag_disponibilidade_liquida) {
  
  disp_positiva <- trunc(disponibilidade_liquida[disponibilidade_liquida>0])
  
  if (length(disp_positiva) == 0)
    disp_positiva <- 0
  
  disp_positiva_media <- mean(disp_positiva)
  
  dif <- disponibilidade_liquida - lag_disponibilidade_liquida
  # dif < 0 significa débito.
  # sempre vai ter pelo menos 1 NA.
  debitos <- sum(abs(dif[dif < 0]), na.rm = TRUE)
  # numero menor que 1 fica ruim pq pode explodir tudo
  debitos <- ifelse(debitos < 1, 1, debitos)
  
  disp_positiva_media/debitos
}

calc_dlp <- function(disponibilidade_liquida) {
  dlp <- disponibilidade_liquida[disponibilidade_liquida > 0]
  if (length(dlp) == 0)
    return(0)
  
  mean(dlp)
}

calc_ipdl <- function(disponibilidade_liquida, lag_disponibilidade_liquida) {
  
  disponibilidade_liquida <- trunc(disponibilidade_liquida)
  dif <- disponibilidade_liquida - lag_disponibilidade_liquida
  # dif < 0 significa débito.
  # sempre vai ter pelo menos 1 NA.
  debitos <- mean(abs(dif[dif < 0]), na.rm = TRUE)
  debitos <- ifelse(is.nan(debitos) || debitos < 0, 0, debitos)
  
  mean(disponibilidade_liquida -  debitos*0.5 > 0)
}

calcular_indices <- function(df) {
  
  df %>%
    summarise(
      n = n(),
      integral_sobre_media_dos_gastos = calc_indicador_integral_sobre_media_dos_gastos(
        disponibilidade_liquida = disponibilidade_liquida, 
        pagamento_diario = pagamento_diario
      ),
      disponibilidade_estritamente_crescente = calc_disponibilidade_estritamente_crescente(
        disponibilidade_liquida = disponibilidade_liquida,
        dias_no_periodo = n(),
        NO_DIA_COMPLETO_dmy = NO_DIA_COMPLETO_dmy
      ),
      iadl = calc_iadl(
        disponibilidade_liquida,
        lag(disponibilidade_liquida, 1, order_by = NO_DIA_COMPLETO_dmy)
      ),
      dlp = calc_dlp(disponibilidade_liquida = disponibilidade_liquida),
      ipdl = calc_ipdl(
        disponibilidade_liquida,
        lag(disponibilidade_liquida, 1, order_by = NO_DIA_COMPLETO_dmy)
      ),
      valor_nominal = calc_indicador_valor_nominal(disponibilidade_liquida),
      valor_nominal_conservador = calc_indicador_valor_nominal_conservador(disponibilidade_liquida, pagamento_diario),
      indicador_tempo = calc_indicador_tempo(disponibilidade_liquida)
    )
}

indices_no_tempo_ug_fonte <- slider::slide_dfr(
  sort(unique(disponibilidades_liquidas_diarias$NO_DIA_COMPLETO_dmy)),
  ~disponibilidades_liquidas_diarias %>% 
    filter(NO_DIA_COMPLETO_dmy %in% .x) %>% 
    group_by(
      NO_UG,
      NO_ORGAO,
      NO_FONTE_RECURSO
    ) %>% 
    calcular_indices() %>% 
    mutate(dia = tail(.x, 1)),
  .before = 365,
  .complete = TRUE,
  .step = 1
)

indices_no_tempo_ug <- slider::slide_dfr(
  sort(unique(disponibilidades_liquidas_diarias$NO_DIA_COMPLETO_dmy)),
  ~disponibilidades_liquidas_diarias %>% 
    filter(NO_DIA_COMPLETO_dmy %in% .x) %>% 
    group_by(
      NO_UG,
      NO_ORGAO
    ) %>% 
    calcular_indices() %>% 
    mutate(dia = tail(.x, 1)),
  .before = 365,
  .complete = TRUE,
  .step = 1
)

indices_ug_fonte <- indices_no_tempo_ug_fonte %>% 
  filter(n > 365) %>% 
  group_by(NO_UG, NO_FONTE_RECURSO) %>% 
  filter(dia == max(dia))

indices_ug <- indices_no_tempo_ug %>% 
  filter(n > 365) %>% 
  group_by(NO_UG) %>% 
  filter(dia == max(dia))
  

saveRDS(ungroup(indices_no_tempo_ug_fonte), "data/indices_no_tempo_ug_fonte.rds")
saveRDS(ungroup(indices_no_tempo_ug), "data/indices_no_tempo_ug.rds")
saveRDS(ungroup(indices_ug), "data/indices_ug.rds")
saveRDS(ungroup(indices_ug_fonte), "data/indices_ug_fonte.rds")
