# Os indicadores que vamos calcular estão relacionados à uma janela
# de tempo.
# Vamos usar 1 ano de histórico em geral.

disponibilidades_liquidas_diarias <- read_rds("data/disponibilidades_liquidas_diarias.rds")
obrigacoes_a_pagar_diarias <- read_rds("data/obrigacoes_a_pagar_diarias.rds")

calc_disponibilidade_estritamente_crescente <- function(disponibilidade_liquida, dias_no_periodo, NO_DIA_COMPLETO_dmy) {
  proporcao_de_disponibilidade_liquida_negativa <- mean(disponibilidade_liquida < 0)
  disponibilidade_mais_recente <- disponibilidade_liquida[which.max(NO_DIA_COMPLETO_dmy)]
  mean(diff(disponibilidade_liquida)  > 0) + 
    mean(abs(diff(disponibilidade_liquida)[diff(disponibilidade_liquida) < 0]) < (sd(disponibilidade_liquida) + 0.001)/100)
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

disponibilidades_liquidas_diarias %>%
  group_by(
    # ID_ANO_LANC,
    NO_UG,
    NO_ORGAO,
    NO_FONTE_RECURSO
  ) %>% 
  summarise(
    integral_sobre_media_dos_gastos = calc_indicador_integral_sobre_media_dos_gastos(
      disponibilidade_liquida = disponibilidade_liquida, 
      pagamento_diario = pagamento_diario
    ),
    disponibilidade_estritamente_crescente = calc_disponibilidade_estritamente_crescente(
      disponibilidade_liquida = disponibilidade_liquida,
      dias_no_periodo = n(),
      NO_DIA_COMPLETO_dmy = NO_DIA_COMPLETO_dmy
    )
  )
