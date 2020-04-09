library(lubridate)
library(tidyverse)

mj_simplificado <- read_rds("data/mj_simplificado.rds")

# saldos diários ----------------------------------------------------------
saldos_diarios <- mj_simplificado %>%
  filter(NO_ITEM_INFORMACAO %in% "LIMITES DE SAQUE (OFSS, DIVIDA, BACEN E PREV)") %>%
  rename(saldo_diario = SALDORITEMINFORMAODIALANAMENT) %>%
  select(
    ID_ANO_LANC,            
    NO_DIA_COMPLETO,        
    NO_UG,                  
    NO_ORGAO,               
    NO_FONTE_RECURSO,       
    saldo_diario 
  ) %>%
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
  padr::pad(group = c("NO_UG", "NO_ORGAO", "NO_FONTE_RECURSO"), by = "NO_DIA_COMPLETO_dmy", break_above = 5) %>% 
  tidyr::fill(saldo_diario_acumulado) %>%
  mutate(
    paded = !is.na(saldo_diario),
    ID_ANO_LANC = year(NO_DIA_COMPLETO_dmy),
    saldo_diario = coalesce(saldo_diario, 0),
    flag_saldo_anual = coalesce(flag_saldo_anual, FALSE),
    NO_DIA_COMPLETO = if_else(is.na(NO_DIA_COMPLETO), format(NO_DIA_COMPLETO_dmy, "%d/%m/%Y"), NO_DIA_COMPLETO)
  ) %>%
  ungroup()

saveRDS(saldos_diarios, file = "data/saldos_diarios.rds")

# obrigações a pagar diárias ----------------------------------------------
obrigacoes_a_pagar_diarias <- mj_simplificado %>%
  filter(NO_ITEM_INFORMACAO %in% "VALORES LIQUIDADOS A PAGAR (EXERCICIO + RP)") %>%
  rename(obrigacoes_a_pagar_diario = SALDORITEMINFORMAODIALANAMENT) %>%
  select(
    ID_ANO_LANC,            
    NO_DIA_COMPLETO,        
    NO_UG,                  
    NO_ORGAO,               
    NO_FONTE_RECURSO,       
    obrigacoes_a_pagar_diario 
  ) %>%
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
  padr::pad(group = c("NO_UG", "NO_ORGAO", "NO_FONTE_RECURSO"), by = "NO_DIA_COMPLETO_dmy", break_above = 5) %>% 
  tidyr::fill(obrigacoes_a_pagar_diario_acumulado) %>%
  mutate(
    paded = !is.na(obrigacoes_a_pagar_diario),
    ID_ANO_LANC = year(NO_DIA_COMPLETO_dmy),
    obrigacoes_a_pagar_diario = coalesce(obrigacoes_a_pagar_diario, 0),
    flag_saldo_anual = coalesce(flag_saldo_anual, FALSE),
    NO_DIA_COMPLETO = if_else(is.na(NO_DIA_COMPLETO), format(NO_DIA_COMPLETO_dmy, "%d/%m/%Y"), NO_DIA_COMPLETO)
  ) %>%
  ungroup()

saveRDS(obrigacoes_a_pagar_diarias, file = "data/obrigacoes_a_pagar_diarias.rds")

# pagamentos diários ----------------------------------------------
pagamentos_diarios <- mj_simplificado %>%
  filter(NO_ITEM_INFORMACAO %in% "PAGAMENTOS TOTAIS (EXERCICIO E RAP)") %>%
  rename(pagamento_diario = SALDORITEMINFORMAODIALANAMENT) %>%
  select(
    ID_ANO_LANC,            
    NO_DIA_COMPLETO,        
    NO_UG,                  
    NO_ORGAO,               
    NO_FONTE_RECURSO,       
    pagamento_diario 
  ) %>%
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
  padr::pad(group = c("NO_UG", "NO_ORGAO", "NO_FONTE_RECURSO"), by = "NO_DIA_COMPLETO_dmy", break_above = 4) %>% 
  tidyr::fill(pagamento_diario_acumulado) %>%
  mutate(
    paded = !is.na(pagamento_diario),
    ID_ANO_LANC = year(NO_DIA_COMPLETO_dmy),
    pagamento_diario = coalesce(pagamento_diario, 0),
    flag_saldo_anual = coalesce(flag_saldo_anual, FALSE),
    NO_DIA_COMPLETO = if_else(is.na(NO_DIA_COMPLETO), format(NO_DIA_COMPLETO_dmy, "%d/%m/%Y"), NO_DIA_COMPLETO)
  ) %>%
  ungroup()

saveRDS(pagamentos_diarios, file = "data/pagamentos_diarios.rds")
