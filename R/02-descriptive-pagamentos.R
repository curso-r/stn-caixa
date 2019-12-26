library(tidyverse)
library(data.table)
library(dtplyr)

pagamentos <- read_rds(path = "data/pagamentos.rds") 
pagamentos %>% filter(ID_DOCUMENTO == "200109000012019OB802321") %>% select(-starts_with("ID_"), - starts_with("CO_")) %>% View(title = "pagamentos")
