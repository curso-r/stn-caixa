# Os indicadores que vamos calcular estão relacionados à uma janela
# de tempo.
# Vamos usar 1 ano de histórico em geral.

library(tidyverse)

disponibilidades_liquidas_diarias <- read_rds("data/disponibilidades_liquidas_diarias.rds")
obrigacoes_a_pagar_diarias <- read_rds("data/obrigacoes_a_pagar_diarias.rds")

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

calcular_indices <- function(df) {
  df %>%
    summarise(
      integral_sobre_media_dos_gastos = calc_indicador_integral_sobre_media_dos_gastos(
        disponibilidade_liquida = disponibilidade_liquida, 
        pagamento_diario = pagamento_diario
      ),
      disponibilidade_estritamente_crescente = calc_disponibilidade_estritamente_crescente(
        disponibilidade_liquida = disponibilidade_liquida,
        dias_no_periodo = n(),
        NO_DIA_COMPLETO_dmy = NO_DIA_COMPLETO_dmy
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

saveRDS(indices_no_tempo_ug_fonte, "data/indices_no_tempo_ug_fonte.rds")
saveRDS(indices_no_tempo_ug, "data/indices_no_tempo_ug.rds")