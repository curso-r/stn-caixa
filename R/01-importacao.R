library(tidyverse)

# dados zipados em
# https://drive.google.com/drive/folders/1hFUtZmFCVXgUvouvsy3ppO2i09UANr1u

unzip("data-raw/MJ_1_Mov_Lim_Saque.zip", exdir = "data-raw")
lim_saque <- data.table::fread("data-raw/MJ_1_Mov_Lim_Saque.csv") %>% as_tibble(.name_repair = "unique")
write_rds(lim_saque, path = "data/lim_saque.rds")
rm(lim_saque)
fs::file_delete("data-raw/MJ_1_Mov_Lim_Saque.csv")

unzip("data-raw/MJ_2_Mov_Pagamentos.zip", exdir = "data-raw")
pagamentos <- data.table::fread("data-raw/MJ_2_Mov_Pagamentos.csv") %>% as_tibble(.name_repair = "unique")
write_rds(pagamentos, "data/pagamentos.rds")
rm(pagamentos)
fs::file_delete("data-raw/MJ_2_Mov_Pagamentos.csv")

unzip("data-raw/MJ_3_Mov_Obrigacoes.zip", exdir = "data-raw")
obrigacoes <- data.table::fread("data-raw/MJ_3_Mov_Obrigacoes.csv") %>% as_tibble(.name_repair = "unique")
write_rds(obrigacoes, "data/obrigacoes.rds")
rm(obrigacoes)
fs::file_delete("data-raw/MJ_3_Mov_Obrigacoes.csv")


vars <- c(
  "ID_ANO_LANC"                 ,  "ID_MES_LANC"             ,      "ID_DIA_LANC"            ,      "NO_DIA_COMPLETO"       ,       
  "ID_ITEM_INFORMACAO"          ,  "NO_ITEM_INFORMACAO"      ,      "CO_ITEM_INFORMACAO"     ,      "ID_FONTE_RECURSO"      ,       
  "CO_FONTE_RECURSO"            ,  "NO_FONTE_RECURSO"        ,      "ID_ORGAO_MAXI"          ,      "CO_ORGAO_MAXI"         ,       
  "NO_ORGAO_MAXI"              ,   "ID_ORGAO_UG"            ,       "CO_ORGAO"              ,       "NO_ORGAO"             ,        
  "ID_UG"                      ,   "CO_UG"                  ,       "NO_UG"                 ,       "SALDORITEMINFORMAODIALANAMENT"
)

obrigacoes <- read_rds("data/obrigacoes.rds") %>% 
  rename(
    SALDORITEMINFORMAODIALANAMENT = SALDORITEMINFORMAO,
    ID_ORGAO_MAXI = ID_ORGAO_MAXI...11,
    CO_ORGAO_MAXI = CO_ORGAO_MAXI...12, 
    NO_ORGAO_MAXI = NO_ORGAO_MAXI...13,
    CO_ORGAO = CO_ORGAO...15,
    NO_ORGAO = NO_ORGAO...16
  ) %>%
  select(vars) %>%
  group_by_at(
    vars(-SALDORITEMINFORMAODIALANAMENT)
  ) %>%
  summarise(
    SALDORITEMINFORMAODIALANAMENT = sum(SALDORITEMINFORMAODIALANAMENT)
    #obrigacoes_a_pagar_diario = sum(SALDORITEMINFORMAO)
  ) %>%
  ungroup()

pagamentos <- read_rds("data/pagamentos.rds") %>% 
  rename(
    SALDORITEMINFORMAODIALANAMENT = SALDORITEMINFORMAO,
    ID_ORGAO_MAXI = ID_ORGAO_MAXI...11,
    CO_ORGAO_MAXI = CO_ORGAO_MAXI...12, 
    NO_ORGAO_MAXI = NO_ORGAO_MAXI...13,
    CO_ORGAO = CO_ORGAO...15,
    NO_ORGAO = NO_ORGAO...16
  ) %>%
  select(vars) %>%
  group_by_at(
    vars(-SALDORITEMINFORMAODIALANAMENT)
  ) %>%
  summarise(
    SALDORITEMINFORMAODIALANAMENT = sum(SALDORITEMINFORMAODIALANAMENT)
    #obrigacoes_a_pagar_diario = sum(SALDORITEMINFORMAO)
  ) %>%
  ungroup()

lim_saque  <- read_rds("data/lim_saque.rds") %>% 
  rename(SALDORITEMINFORMAODIALANAMENT = SALDORITEMINFORMAO) %>% 
  select(vars) %>%
  group_by_at(
    vars(-SALDORITEMINFORMAODIALANAMENT)
  ) %>%
  summarise(
    SALDORITEMINFORMAODIALANAMENT = sum(SALDORITEMINFORMAODIALANAMENT)
    # saldo_diario = sum(SALDORITEMINFORMAODIALANAMENT)
  ) %>%
  ungroup()

mj_simplificado <- bind_rows(
  obrigacoes,
  pagamentos,
  lim_saque
)

write_rds(mj_simplificado, "data/mj_simplificado.rds")




