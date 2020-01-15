library(lubridate)
library(tidyverse)

obrigacoes <- read_rds("../data/obrigacoes.rds")
pagamentos <- read_rds("../data/pagamentos.rds")
lim_saque  <- read_rds("../data/lim_saque.rds") 


# saldos diários ----------------------------------------------------------
saldos_diarios <- lim_saque %>%
  group_by(
    ID_ANO_LANC,
    NO_DIA_COMPLETO,
    NO_UG,
    NO_ORGAO,
    NO_FONTE_RECURSO
  ) %>%
  summarise(
    saldo_diario = sum(SALDORITEMINFORMAO)
  ) %>%
  ungroup() %>%
  mutate(
    flag_saldo_anual = str_detect(NO_DIA_COMPLETO , "-09/00/"),
    NO_DIA_COMPLETO_dmy = dmy(if_else(!flag_saldo_anual, NO_DIA_COMPLETO, paste0("01/01/", ID_ANO_LANC)))
  ) %>%
  group_by(
    NO_UG,
    NO_ORGAO,
    NO_FONTE_RECURSO
  ) %>%
  filter(
    # retira as datas com -09/00/YYYY se o YYYY for maior do que o ano da data mais antiga daquela NO_UG/NO_FONTE
    (NO_DIA_COMPLETO_dmy %in% min(NO_DIA_COMPLETO_dmy, na.rm = TRUE)) | !flag_saldo_anual
  ) %>%
  arrange(NO_DIA_COMPLETO_dmy) %>%
  mutate(
    saldo_diario_acumulado = cumsum(saldo_diario)
  ) %>%
  padr::pad(group = c("NO_UG", "NO_ORGAO", "NO_FONTE_RECURSO"), by = "NO_DIA_COMPLETO_dmy") %>% 
  tidyr::fill(saldo_diario_acumulado) %>%
  mutate(
    paded = !is.na(saldo_diario),
    ID_ANO_LANC = year(NO_DIA_COMPLETO_dmy),
    saldo_diario = coalesce(saldo_diario, 0),
    flag_saldo_anual = coalesce(flag_saldo_anual, FALSE),
    NO_DIA_COMPLETO = if_else(is.na(NO_DIA_COMPLETO), format(NO_DIA_COMPLETO_dmy, "%d/%m/%Y"), NO_DIA_COMPLETO)
  ) %>%
  ungroup()

saveRDS(saldos_diarios, file = "../data/saldos_diarios.rds")

# obrigações a pagar diárias ----------------------------------------------
obrigacoes_a_pagar_diarias <- obrigacoes %>%
  rename(
    NO_ORGAO = NO_ORGAO...16
  ) %>%
  group_by(
    ID_ANO_LANC,
    NO_DIA_COMPLETO,
    NO_UG,
    NO_ORGAO,
    NO_FONTE_RECURSO
  ) %>%
  summarise(
    obrigacoes_a_pagar_diario = sum(SALDORITEMINFORMAO)
  ) %>%
  ungroup() %>%
  mutate(
    flag_saldo_anual = str_detect(NO_DIA_COMPLETO , "-09/00/"),
    NO_DIA_COMPLETO_dmy = dmy(if_else(!flag_saldo_anual, NO_DIA_COMPLETO, paste0("01/01/", ID_ANO_LANC)))
  ) %>%
  group_by(
    NO_UG,
    NO_ORGAO,
    NO_FONTE_RECURSO
  ) %>%
  filter(
    # retira as datas com -09/00/YYYY se o YYYY for maior do que o ano da data mais antiga daquela NO_UG/NO_FONTE
    (NO_DIA_COMPLETO_dmy %in% min(NO_DIA_COMPLETO_dmy, na.rm = TRUE)) | !flag_saldo_anual
  ) %>%
  arrange(NO_DIA_COMPLETO_dmy) %>%
  mutate(
    obrigacoes_a_pagar_diario_acumulado = cumsum(obrigacoes_a_pagar_diario)
  ) %>%
  padr::pad(group = c("NO_UG", "NO_ORGAO", "NO_FONTE_RECURSO"), by = "NO_DIA_COMPLETO_dmy") %>% 
  tidyr::fill(obrigacoes_a_pagar_diario_acumulado) %>%
  mutate(
    paded = !is.na(obrigacoes_a_pagar_diario),
    ID_ANO_LANC = year(NO_DIA_COMPLETO_dmy),
    obrigacoes_a_pagar_diario = coalesce(obrigacoes_a_pagar_diario, 0),
    flag_saldo_anual = coalesce(flag_saldo_anual, FALSE),
    NO_DIA_COMPLETO = if_else(is.na(NO_DIA_COMPLETO), format(NO_DIA_COMPLETO_dmy, "%d/%m/%Y"), NO_DIA_COMPLETO)
  ) %>%
  ungroup()


# obrigações a pagar diárias ----------------------------------------------
pagamentos_diarios <- pagamentos %>%
  rename(
    NO_ORGAO = NO_ORGAO...16
  ) %>%
  group_by(
    ID_ANO_LANC,
    NO_DIA_COMPLETO,
    NO_UG,
    NO_ORGAO,
    NO_FONTE_RECURSO
  ) %>%
  summarise(
    pagamento_diario = sum(SALDORITEMINFORMAO)
  ) %>%
  ungroup() %>%
  mutate(
    flag_saldo_anual = str_detect(NO_DIA_COMPLETO , "-09/00/"),
    NO_DIA_COMPLETO_dmy = dmy(if_else(!flag_saldo_anual, NO_DIA_COMPLETO, paste0("01/01/", ID_ANO_LANC)))
  ) %>%
  group_by(
    NO_UG,
    NO_ORGAO,
    NO_FONTE_RECURSO
  ) %>%
  filter(
    # retira as datas com -09/00/YYYY se o YYYY for maior do que o ano da data mais antiga daquela NO_UG/NO_FONTE
    (NO_DIA_COMPLETO_dmy %in% min(NO_DIA_COMPLETO_dmy, na.rm = TRUE)) | !flag_saldo_anual
  ) %>%
  arrange(NO_DIA_COMPLETO_dmy) %>%
  mutate(
    pagamento_diario_acumulado = cumsum(pagamento_diario)
  ) %>%
  padr::pad(group = c("NO_UG", "NO_ORGAO", "NO_FONTE_RECURSO"), by = "NO_DIA_COMPLETO_dmy") %>% 
  tidyr::fill(pagamento_diario_acumulado) %>%
  mutate(
    paded = !is.na(pagamento_diario),
    ID_ANO_LANC = year(NO_DIA_COMPLETO_dmy),
    pagamento_diario = coalesce(pagamento_diario, 0),
    flag_saldo_anual = coalesce(flag_saldo_anual, FALSE),
    NO_DIA_COMPLETO = if_else(is.na(NO_DIA_COMPLETO), format(NO_DIA_COMPLETO_dmy, "%d/%m/%Y"), NO_DIA_COMPLETO)
  ) %>%
  ungroup()


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
  tidyr::fill(obrigacoes_a_pagar_diario_acumulado) %>%
  mutate(
    obrigacoes_a_pagar_diario = coalesce(obrigacoes_a_pagar_diario, 0)
  ) %>%
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
  tidyr::fill(pagamento_diario_acumulado) %>%
  mutate(
    pagamento_diario = coalesce(pagamento_diario, 0)
  ) %>%
  arrange(NO_DIA_COMPLETO_dmy) %>%
  mutate(
    disponibilidade_liquida = saldo_diario_acumulado - obrigacoes_a_pagar_diario_acumulado
  )

saveRDS(disponibilidades_liquidas_diarias, file = "../data/disponibilidades_liquidas_diarias.rds")
saveRDS(disponibilidades_liquidas_diarias, file = "../apps/explorador_disponibilidades_liquidas_v2/disponibilidades_liquidas_diarias.rds")


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


# indicador de disponibilidade liquida positiva ---------------------------
indicadores <- disponibilidades_liquidas_diarias %>%
  group_by(
    ID_ANO_LANC,
    NO_UG,
    NO_ORGAO,
    NO_FONTE_RECURSO
  ) %>%
  summarise(
    proporcao_de_disponibilidade_liquida_negativa = mean(disponibilidade_liquida < 0),
    dias_no_periodo = n(),
    disponibilidade_estritamente_crescente = mean(diff(disponibilidade_liquida)  > 0) + mean(abs(diff(disponibilidade_liquida)[diff(disponibilidade_liquida) < 0]) < sd(disponibilidade_liquida)/100)
  ) %>%
  arrange(desc(disponibilidade_estritamente_crescente))

saveRDS(indicadores, file = "../apps/explorador_disponibilidades_liquidas/indicadores.rds")
saveRDS(indicadores, file = "../data/indicadores.rds")

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
