library(tidyverse)
library(data.table)

obrigacoes <- read_rds("data/obrigacoes.rds")

# exemplos de documentos
obrigacoes %>% count(ID_DOCUMENTO, sort = TRUE)

obrigacoes %>% filter(ID_DOCUMENTO == "200109000012019OB802321") %>% select(-starts_with("ID_"), - starts_with("CO_")) %>% View(title = "obrigacoes")
obrigacoes %>% filter(ID_DOCUMENTO == "194035192082019NS002882") %>% select(-starts_with("ID_"), - starts_with("CO_")) %>% View
obrigacoes %>% filter(ID_DOCUMENTO == "194035192082019NS000415") %>% select(-starts_with("ID_"), - starts_with("CO_")) %>% View
obrigacoes %>% filter(ID_DOCUMENTO == "200325000012019NS000379") %>% select(-starts_with("ID_"), - starts_with("CO_")) %>% View
obrigacoes %>% filter(ID_DOCUMENTO == "200006000012018OB800266") %>% select(-starts_with("ID_"), - starts_with("CO_")) %>% View
obrigacoes %>% filter(ID_DOCUMENTO == "194048192082018NS000094") %>% select(-starts_with("ID_"), - starts_with("CO_")) %>% View

# tem ID_DOCUMENTO_CCOR estranho (com valores -7)
obrigacoes %>% 
  mutate(tem_ne = str_detect(ID_DOCUMENTO_CCOR, "NE")) %>% 
  filter(!tem_ne)

obrigacoes %>% count(ID_DOCUMENTO_CCOR, sort = TRUE)


# valor acumulado dos saldos 
# obrigacoes a pagar negativa está associada com pagamentos feitos (avaliar pagamentos vs obrigacoes)
# nao consegue fazer o pagamento por conta de cotas para as fontes.
# cenário ruim: ug não consegue pagar. (problema de alocação)
# a alocação seria feita entre UGs para a mesma fonte. (mesmo órgão é vantagem na burocracia)






pagamentos <- read_rds(path = "data/pagamentos.rds") 
pagamentos %>% filter(ID_DOCUMENTO == "200109000012019OB802321") %>% select(-starts_with("ID_"), - starts_with("CO_")) %>% View(title = "pagamentos")

