library(lubridate)
library(tidyverse)

obrigacoes <- read_rds("data/obrigacoes.rds")
pagamentos <- read_rds("data/pagamentos.rds")
lim_saque  <- read_rds("data/lim_saque.rds") 

# saldos diários por documento --------------------------------------------
saldos_diarios_por_documento <- lim_saque %>%
  group_by(
    ID_ANO_LANC,
    NO_DIA_COMPLETO,
    NO_UG,
    NO_ORGAO,
    NO_FONTE_RECURSO,
    ID_DOCUMENTO
  ) %>%
  summarise(
    NO_VINCULACAO_PAGAMENTO = first(NO_VINCULACAO_PAGAMENTO),
    vinculacoes_distintas = n_distinct(NO_VINCULACAO_PAGAMENTO),
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
    NO_FONTE_RECURSO,
    ID_DOCUMENTO
  ) %>%
  filter(
    # retira as datas com -09/00/YYYY se o YYYY for maior do que o ano da data mais antiga daquela NO_UG/NO_FONTE
    (NO_DIA_COMPLETO_dmy %in% min(NO_DIA_COMPLETO_dmy, na.rm = TRUE)) | !flag_saldo_anual
  ) %>%
  arrange(NO_DIA_COMPLETO_dmy) %>%
  mutate(
    saldo_diario_acumulado = cumsum(saldo_diario)
  ) %>%
  padr::pad(group = c("NO_UG", "NO_ORGAO", "NO_FONTE_RECURSO", "ID_DOCUMENTO"), by = "NO_DIA_COMPLETO_dmy") %>% 
  tidyr::fill(saldo_diario_acumulado) %>%
  mutate(
    paded = !is.na(saldo_diario),
    ID_ANO_LANC = year(NO_DIA_COMPLETO_dmy),
    saldo_diario = coalesce(saldo_diario, 0),
    flag_saldo_anual = coalesce(flag_saldo_anual, FALSE),
    NO_DIA_COMPLETO = if_else(is.na(NO_DIA_COMPLETO), format(NO_DIA_COMPLETO_dmy, "%d/%m/%Y"), NO_DIA_COMPLETO)
  ) %>%
  ungroup()

saveRDS(saldos_diarios_por_documento, file = "data/saldos_diarios_por_documento.rds")
saveRDS(saldos_diarios_por_documento, file = "apps/explorador_disponibilidades_liquidas_v2/saldos_diarios_por_documento.rds")




# pagamentos por documento ------------------------------------------------
pagamentos_por_documento <- pagamentos %>%
  group_by(
    NO_ORGAO_MAXI...13,
    NO_ORGAO...16,
    NO_FUNCAO_PT,
    NO_SUBFUNCAO_PT,
    NO_PROGRAMA_PT,
    NO_ACAO_PT,
    NO_GRUPO_DESPESA_NADE,
    NO_MOAP_NADE,
    NO_ELEMENTO_DESPESA_NADE,
    NO_IN_RESULTADO_EOF,
    SN_EXCECAO_DECRETO,
    NO_ORGAO...42,
    NO_DIA_COMPLETO,
    ID_DOCUMENTO
  ) %>%
  rename(
    NO_ORGAO_MAXIMO = NO_ORGAO_MAXI...13,
    NO_ORGAO = NO_ORGAO...16,
    NO_ORGAO_UO = NO_ORGAO...42
  ) %>%
  summarise(
    pagamento = sum(SALDORITEMINFORMAO)
  )

saveRDS(pagamentos_por_documento, file = "data/pagamentos_por_documento.rds")
saveRDS(pagamentos_por_documento, file = "apps/explorador_disponibilidades_liquidas_v2/pagamentos_por_documento.rds")



# vinculação de pagamentos ------------------------------------------------
vinculacao_de_pagamentos <- left_join(
  pagamentos_por_documento,
  saldos_diarios_por_documento %>% select(-paded, -flag_saldo_anual, -vinculacoes_distintas, -NO_DIA_COMPLETO_dmy, -saldo_diario_acumulado)
) %>%
  mutate(
    ID_ANO_LANC = str_sub(NO_DIA_COMPLETO, start = -4),
    pagamento_por_saldo = pagamento/saldo_diario,
    pagamento_abs = abs(pagamento),
    pagamento_positivo = pagamento > 0
  )


saveRDS(vinculacao_de_pagamentos, file = "data/vinculacao_de_pagamentos.rds")
saveRDS(vinculacao_de_pagamentos, file = "apps/explorador_disponibilidades_liquidas_v2/vinculacao_de_pagamentos.rds")








# 
# # sankey ------------------------------------------------------------------
# abrevia_palavras <- function(str) {
#   str %>%
#     str_replace_all("SUPERINTENDENCIA", "SUPT") %>%
#     str_replace_all("REGIONAL", "REG") %>%
#     str_replace_all("ADMINISTRACAO", "ADM") %>%
#     str_replace_all("DIRETORIA", "DIR") %>%
#     str_replace_all("COORDENACAO", "COORD") %>%
#     str_replace_all("NACIONAL", "NAC") %>%
#     str_replace_all("FINANCEIROS", "FIN") %>%
#     str_replace_all("PROGNOSTICOS", "PROG") %>%
#     str_replace_all("ESTADO", "EST") %>%
#     str_replace_all("POLITICAS", "POL") %>%
#     str_replace_all("RECURSOS", "REC") %>%
#     str_replace_all("ORDINARIOS", "ORD") %>%
#     str_replace_all("ARRECADADOS", "ARREC")
# }
# 
# library(ggalluvial)
# library(ggrepel)
# 
# data <- vinculacao_de_pagamentos %>%
#   ungroup %>%
#   filter(NO_DIA_COMPLETO == first(NO_DIA_COMPLETO), pagamento_positivo) %>%
#   group_by(
#     NO_FUNCAO_PT, 
#     NO_VINCULACAO_PAGAMENTO,
#     NO_FONTE_RECURSO
#   ) %>%
#   summarise(
#     pagamento = abs(sum(pagamento))
#   )
# 
# 
# 
# data %>%
#   ggplot(aes(
#     y = pagamento, 
#     axis1 = NO_FONTE_RECURSO,
#     axis2 = NO_VINCULACAO_PAGAMENTO,
#     axis3 = NO_FUNCAO_PT
#   )) +
#   stat_alluvium(width = 1/12, alpha = 0.5, aes(fill = NO_VINCULACAO_PAGAMENTO)) +
#   # scale_x_discrete(limits = c("NO_FUNCAO_PT", "NO_SUBFUNCAO_PT", "NO_PROGRAMA_PT", "NO_GRUPO_DESPESA_NADE", "NO_MOAP_NADE"), expand = c(0.05,0.05, 0.05, 0.05, 0.05)) +
#   stat_stratum(width = 1/12) +
#   geom_label_repel(stat = "stratum", infer.label = TRUE)



