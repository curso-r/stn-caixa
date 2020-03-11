library(lubridate)
library(tidyverse)

saldos_diarios <- readRDS(file = "data/saldos_diarios.rds")
obrigacoes_a_pagar_diarias <- readRDS(file = "data/obrigacoes_a_pagar_diarias.rds")
pagamentos_diarios <- readRDS(file = "data/pagamentos_diarios.rds")

# disponibilidades líquidas diárias ---------------------------------------
disponibilidades_liquidas_diarias <- saldos_diarios %>%
  left_join(
    obrigacoes_a_pagar_diarias %>% 
      select(
        ID_ANO_LANC, 
        NO_DIA_COMPLETO, 
        NO_UG, NO_ORGAO, 
        NO_FONTE_RECURSO, 
        NO_DIA_COMPLETO_dmy, 
        obrigacoes_a_pagar_diario, 
        obrigacoes_a_pagar_diario_acumulado
      ),
    by = c("ID_ANO_LANC", "NO_DIA_COMPLETO", "NO_UG", "NO_ORGAO", "NO_FONTE_RECURSO", "NO_DIA_COMPLETO_dmy"),
    suffix = c("_saldos", "_obrigacoes")
  ) %>%
  dplyr::group_by(NO_UG, NO_ORGAO, NO_FONTE_RECURSO) %>%
  dplyr::arrange(NO_DIA_COMPLETO_dmy) %>%
  tidyr::fill(obrigacoes_a_pagar_diario_acumulado) %>%
  mutate(
    obrigacoes_a_pagar_diario_acumulado = coalesce(obrigacoes_a_pagar_diario_acumulado, 0),
    obrigacoes_a_pagar_diario = coalesce(obrigacoes_a_pagar_diario, 0)
  )%>%
  left_join(
    pagamentos_diarios %>% 
      select(
        ID_ANO_LANC, 
        NO_DIA_COMPLETO, 
        NO_UG, NO_ORGAO, 
        NO_FONTE_RECURSO, 
        NO_DIA_COMPLETO_dmy, 
        pagamento_diario, 
        pagamento_diario_acumulado
      ),
    by = c("ID_ANO_LANC", "NO_DIA_COMPLETO", "NO_UG", "NO_ORGAO", "NO_FONTE_RECURSO", "NO_DIA_COMPLETO_dmy"),
    suffix = c("", "_pagamentos")
  ) %>%
  dplyr::group_by(NO_UG, NO_ORGAO, NO_FONTE_RECURSO) %>%
  dplyr::arrange(NO_DIA_COMPLETO_dmy) %>%
  tidyr::fill(pagamento_diario_acumulado) %>%
  mutate(
    pagamento_diario_acumulado = coalesce(pagamento_diario_acumulado, 0),
    pagamento_diario = coalesce(pagamento_diario, 0)
  ) %>%
  mutate(
    disponibilidade_liquida = saldo_diario_acumulado - obrigacoes_a_pagar_diario_acumulado
  )

saveRDS(disponibilidades_liquidas_diarias, file = "data/disponibilidades_liquidas_diarias.rds")
saveRDS(disponibilidades_liquidas_diarias, file = "apps/explorador_disponibilidades_liquidas_v2/disponibilidades_liquidas_diarias.rds")


# disponibilidades líquidas diárias visão UG ------------------------------
disponibilidades_liquidas_diarias_visao_ug <- disponibilidades_liquidas_diarias %>%
  group_by(
    ID_ANO_LANC,
    NO_DIA_COMPLETO,
    NO_DIA_COMPLETO_dmy,
    NO_UG,
    NO_ORGAO
  ) %>%
  summarise(
    saldo_diario = sum(saldo_diario, na.rm = TRUE),
    saldo_diario_acumulado = sum(saldo_diario_acumulado, na.rm = TRUE),
    obrigacoes_a_pagar_diario = sum(obrigacoes_a_pagar_diario, na.rm = TRUE),
    obrigacoes_a_pagar_diario_acumulado = sum(obrigacoes_a_pagar_diario_acumulado, na.rm = TRUE),
    disponibilidade_liquida = sum(disponibilidade_liquida, na.rm = TRUE),
    pagamento_diario = sum(pagamento_diario),
    pagamento_diario_acumulado = sum(pagamento_diario_acumulado)
  )

saveRDS(disponibilidades_liquidas_diarias_visao_ug, file = "data/disponibilidades_liquidas_diarias_visao_ug.rds")
saveRDS(disponibilidades_liquidas_diarias_visao_ug, file = "apps/explorador_disponibilidades_liquidas_v2/disponibilidades_liquidas_diarias_visao_ug.rds")


##################
# checando se o 01/01/2018 bate com as contas de 2017 de uma certa NO_UG para uma certa fonte NO_FONTE
# set.seed(410)
# saldos_diarios_sorteado <- saldos_diarios %>% ungroup() %>% filter(ID_ANO_LANC %in% 2017) %>% sample_n(1) %>% select(NO_UG, NO_FONTE_RECURSO)
# 
# saldos_diarios %>%
#  inner_join(saldos_diarios_sorteado) %>%
#   filter(ID_ANO_LANC %in% 2017) %>%
#   select(NO_UG, NO_FONTE_RECURSO,ID_ANO_LANC, NO_DIA_COMPLETO_dmy, saldo_diario_acumulado, saldo_diario) %>%
#   arrange(NO_DIA_COMPLETO_dmy) %>%
#   View("2017")
# 
# saldos_diarios %>%
#   inner_join(saldos_diarios_sorteado) %>%
#   filter(ID_ANO_LANC %in% 2018) %>%
#   select(NO_UG, NO_FONTE_RECURSO,ID_ANO_LANC, NO_DIA_COMPLETO, NO_DIA_COMPLETO_dmy, saldo_diario_acumulado, saldo_diario) %>%
#   arrange(NO_DIA_COMPLETO_dmy) %>%
#   View("2018")
