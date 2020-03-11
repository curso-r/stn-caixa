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
