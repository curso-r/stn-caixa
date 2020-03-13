library(tidymodels)
library(tidyverse)

modelo <- read_rds("data/modelo.rds")
ts_das_disponibilidades_liquidas_com_indicadores <- read_rds("data/ts_das_disponibilidades_liquidas_com_indicadores.rds")
rotulos <- read_rds("data/rotulos.rds")

# base com scores
ts_das_disponibilidades_liquidas_com_indicadores_final <- ts_das_disponibilidades_liquidas_com_indicadores %>%
  mutate(
    n = map_dbl(serie_temporal, nrow),
    indicadores = map(serie_temporal_random_crop, calcular_indices)
  ) %>% 
  select(id, NO_UG, NO_ORGAO, NO_FONTE_RECURSO, serie_temporal, serie_temporal_random_crop, indicadores) %>%
  unnest(indicadores) %>%
  left_join(
    rotulos,
    by = "id"
  ) %>%
  mutate(
    suspeita_de_empocamento = predict(modelo, ., type = "prob")$.pred_Empoçamento
  )

write_rds(ts_das_disponibilidades_liquidas_com_indicadores_final, "data/ts_das_disponibilidades_liquidas_com_indicadores_final.rds")
write_rds(ts_das_disponibilidades_liquidas_com_indicadores_final, "apps/explorador_disponibilidade_liquidas_v3/ts_das_disponibilidades_liquidas_com_indicadores_final.rds")

