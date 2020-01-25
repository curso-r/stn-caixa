library(tidyverse)
library(trelliscopejs)

trinta_e_uns_de_dezembro <- tibble(
  NO_DIA_COMPLETO_dmy = as.Date(c("2017-12-31", "2018-12-31", "2019-12-31"))
)


disponibilidades_liquidas_diarias <- read_rds("data/disponibilidades_liquidas_diarias.rds")
obrigacoes_a_pagar_diarias <- read_rds("data/obrigacoes_a_pagar_diarias.rds")
indicadores <- read_rds("data/indicadores.rds")

# indicador de disponibilidade liquida ---------------------------
indicadores <- disponibilidades_liquidas_diarias %>%
  group_by(
    # ID_ANO_LANC,
    NO_UG,
    NO_ORGAO,
    NO_FONTE_RECURSO
  ) %>%
  summarise(
    proporcao_de_disponibilidade_liquida_negativa = mean(disponibilidade_liquida < 0),
    dias_no_periodo = n(),
    disponibilidade_mais_recente = disponibilidade_liquida[which(NO_DIA_COMPLETO_dmy == max(NO_DIA_COMPLETO_dmy))][1],
    disponibilidade_estritamente_crescente = mean(diff(disponibilidade_liquida)  > 0) + mean(abs(diff(disponibilidade_liquida)[diff(disponibilidade_liquida) < 0]) < (sd(disponibilidade_liquida) + 0.001)/100),
    disponibilidade_liquida_cte  = sd(disponibilidade_liquida) <= 0.00000001,
    integral = sum(disponibilidade_liquida),
    soma_dos_gastos = sum(pagamento_diario),
    soma_dos_gastos = if_else(abs(soma_dos_gastos) < 10, 10, soma_dos_gastos),
    integral_sobre_media_dos_gastos = integral/soma_dos_gastos
  ) %>%
  arrange(desc(integral_sobre_media_dos_gastos))

saveRDS(indicadores, file = "apps/explorador_disponibilidades_liquidas/indicadores.rds")
saveRDS(indicadores, file = "data/indicadores.rds")

# ts_das_disponibilidades_liquidas (series temporais nested para o grafico de sparklines) ------
ts_das_disponibilidades_liquidas <- disponibilidades_liquidas_diarias %>%
  group_by(
    # ID_ANO_LANC,
    NO_UG,
    NO_ORGAO,
    NO_FONTE_RECURSO
  ) %>%
  nest_legacy(.key = "serie_temporal") %>%
  left_join(
    indicadores
  )

saveRDS(ts_das_disponibilidades_liquidas, file = "data/ts_das_disponibilidades_liquidas.rds")


# Um gráfico ----------------------------------------------------------------
disponibilidades_liquidas_diarias %>%
  filter(
    str_detect(NO_ORGAO, "EPARTAMENTO DE POLICIA RODOVIARIA FEDERAL/MJ"),
    str_detect(NO_UG, "COORDENACAO-GERAL DE PLA") ,
    str_detect(NO_FONTE_RECURSO, "RECURSOS DIVERSOS")
  ) %>%
  ggplot(aes(x = NO_DIA_COMPLETO_dmy, y = disponibilidade_liquida)) +
  geom_line(aes(colour = NO_FONTE_RECURSO, group = NO_UG))



View(disponibilidades_liquidas_diarias)

View(disponibilidades_liquidas_diarias %>%
       filter(
         str_detect(NO_ORGAO, "EPARTAMENTO DE POLICIA RODOVIARIA FEDERAL/MJ"),
         str_detect(NO_UG, "COORDENACAO-GERAL DE PLA") ,
         str_detect(NO_FONTE_RECURSO, "RECURSOS DIVERSOS")
       ))




# gráfico -----------------------------------------------------------------
##
orgaos_sorteados <- indicadores  %>%
  arrange(desc(disponibilidade_estritamente_crescente)) %>%
  ungroup %>%
  distinct(NO_ORGAO, NO_FONTE_RECURSO) %>%
  head(3) 

##
log_neg <- function(x) {
  sign(x) * log1p(abs(x))
}

# visao FONTE ---------------------------------------------------------------
## sumarios
ind <- indicadores  %>%
  ungroup %>%
  filter(
    NO_ORGAO %in% orgaos_sorteados$NO_ORGAO
  ) %>%
  mutate(
    integral_sobre_media_dos_gastos_log = sign(integral_sobre_media_dos_gastos) * log1p(abs(integral_sobre_media_dos_gastos))
  ) %>%
  ggplot(aes(x = integral_sobre_media_dos_gastos_log, y = NO_FONTE_RECURSO, colour = NO_FONTE_RECURSO)) +
  geom_point(size = 4, alpha = 0.5, show.legend = FALSE) +
  geom_hline(yintercept = 0, colour = "red") +
  geom_vline(xintercept = 0, colour = "red") +
  theme_minimal()

plotly::ggplotly(ind) %>% plotly::hide_legend()

## series
ts <- disponibilidades_liquidas_diarias  %>%
  ungroup %>%
  semi_join(orgaos_sorteados) %>%
  ggplot(aes(y = disponibilidade_liquida, x = NO_DIA_COMPLETO_dmy)) +
  geom_line(aes(group = NO_UG, colour = NO_FONTE_RECURSO), show.legend = FALSE) +
  facet_wrap(~NO_FONTE_RECURSO + NO_ORGAO, scales = "free_y", ncol = 4) +
  geom_vline(data = trinta_e_uns_de_dezembro, aes(xintercept = NO_DIA_COMPLETO_dmy), colour = "purple", linetype = "dashed", size = 0.2) +
  theme_minimal()

plotly::ggplotly(ts) %>% plotly::hide_legend()












# visao UG ---------------------------------------------------------------
## sumarios
ind <- indicadores  %>%
  ungroup %>%
  filter(
    NO_ORGAO %in% orgaos_sorteados$NO_ORGAO
  ) %>%
  mutate(
    integral_sobre_media_dos_gastos_log = sign(integral_sobre_media_dos_gastos) * log1p(abs(integral_sobre_media_dos_gastos))
  ) %>%
  ggplot(aes(x = integral_sobre_media_dos_gastos_log, y = NO_UG, colour = NO_FONTE_RECURSO)) +
  # geom_jitter(aes(size = log_neg(integral))) +
  geom_point(size = 4, alpha = 0.5, show.legend = FALSE) +
  geom_hline(yintercept = 0, colour = "red") +
  geom_vline(xintercept = 0, colour = "red") +
  theme_minimal()

plotly::ggplotly(ind) %>% plotly::hide_legend()


## series
ts <- disponibilidades_liquidas_diarias  %>%
  ungroup %>%
  filter(
    NO_ORGAO %in% orgaos_sorteados$NO_ORGAO
  ) %>%
  filter(
    NO_UG %in% sample(unique(NO_UG), 2)
  ) %>%
  ggplot(aes(y = disponibilidade_liquida, x = NO_DIA_COMPLETO_dmy)) +
  geom_line(aes(group = NO_FONTE_RECURSO, colour = NO_FONTE_RECURSO)) +
  facet_wrap(~NO_UG, scales = "free_y", ncol = 4) +
  geom_vline(data = trinta_e_uns_de_dezembro, aes(xintercept = NO_DIA_COMPLETO_dmy), colour = "purple", linetype = "dashed", size = 0.2) +
  theme_minimal()

plotly::ggplotly(ts) %>% plotly::hide_legend()























###
fonte = "RECURSOS FINANCEIROS DIRETAMENTE ARRECADADOS"
orgao = "MINISTERIO DA JUSTICA E SEGURANCA PUBLICA"

disponibilidades_liquidas_diarias %>%
  filter(
    NO_FONTE_RECURSO %in% fonte,
    NO_ORGAO %in% orgao
  ) %>%
  ggplot(aes(x = NO_DIA_COMPLETO_dmy, y = disponibilidade_liquida)) +
  geom_line() +
  facet_wrap(~NO_UG, scale = "free_y")


###
fonte = "RECURSOS FINANCEIROS DIRETAMENTE ARRECADADOS"
orgao = "MINISTERIO DA JUSTICA E SEGURANCA PUBLICA"

disponibilidades_liquidas_diarias %>%
  filter(
    NO_FONTE_RECURSO %in% fonte,
    NO_ORGAO %in% orgao
  ) %>%
  ggplot(aes(x = NO_DIA_COMPLETO_dmy, y = disponibilidade_liquida, colour = NO_UG)) +
  geom_line() +
  geom_vline(data = trinta_e_uns_de_dezembro, aes(xintercept = NO_DIA_COMPLETO_dmy), colour = "purple", linetype = "dashed", size = 0.2) +
  facet_wrap(~NO_UG, scale = "free_y")


### Um gráfico por fonte. Cada curva é uma UG
indicadores %>% 
  ungroup %>%
  arrange(desc(disponibilidade_estritamente_crescente)) %>%
  distinct(NO_FONTE_RECURSO, NO_ORGAO) %>%
  head(1) %>%
  right_join(
    disponibilidades_liquidas_diarias
  ) %>%
  ggplot(aes(x = NO_DIA_COMPLETO_dmy, y = disponibilidade_liquida, colour = NO_UG)) +
  geom_line(show.legend = FALSE) +
  geom_vline(data = trinta_e_uns_de_dezembro, aes(xintercept = NO_DIA_COMPLETO_dmy), colour = "purple", linetype = "dashed", size = 0.2) +
  facet_trelliscope(~ NO_FONTE_RECURSO + NO_ORGAO, scale = "free_y", nrow = 1, ncol = 3)




### Um gráfico por fonte e UG
indicadores %>% 
  ungroup %>%
  arrange(desc(disponibilidade_estritamente_crescente)) %>%
  distinct(NO_FONTE_RECURSO, NO_ORGAO) %>%
  head(1) %>%
  right_join(
    disponibilidades_liquidas_diarias
  ) %>%
  group_by(NO_FONTE_RECURSO, NO_UG, NO_ORGAO) %>%
  filter(n() > 10) %>%
  ggplot(aes(x = NO_DIA_COMPLETO_dmy, y = disponibilidade_liquida, colour = NO_UG)) +
  geom_line(show.legend = FALSE) +
  geom_vline(data = trinta_e_uns_de_dezembro, aes(xintercept = NO_DIA_COMPLETO_dmy), colour = "purple", linetype = "dashed", size = 0.2) +
  facet_trelliscope(~ NO_FONTE_RECURSO + NO_UG + NO_ORGAO, scale = "free_y", nrow = 2, ncol = 3, path = "html")
