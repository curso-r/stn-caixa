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
    disponibilidade_estritamente_crescente = mean(diff(disponibilidade_liquida)  > 0) + mean(abs(diff(disponibilidade_liquida)[diff(disponibilidade_liquida) < 0]) < sd(disponibilidade_liquida)/100),
    integral = sum(disponibilidade_liquida),
    soma_dos_gastos = sum(pagamento_diario),
    soma_dos_gastos = if_else(abs(soma_dos_gastos) < 10, 10, soma_dos_gastos),
    integral_sobre_media_dos_gastos = integral/soma_dos_gastos
  ) %>%
  arrange(desc(integral_sobre_media_dos_gastos))

saveRDS(indicadores, file = "apps/explorador_disponibilidades_liquidas/indicadores.rds")
saveRDS(indicadores, file = "data/indicadores.rds")


# graficos ----------------------------------------------------------------
##
disponibilidades_liquidas_diarias %>%
  filter(
    NO_ORGAO == "DEPARTAMENTO DE POLICIA RODOVIARIA FEDERAL/MJ",
    NO_FONTE_RECURSO == "TX/MUL.P/PODER DE POLICIA E MUL.PROV.PROC.JUD"
  ) %>%
  ggplot(aes(x = NO_DIA_COMPLETO_dmy, y = disponibilidade_liquida, colour = NO_UG)) +
  geom_line()

##
orgaos_sorteados <- indicadores  %>%
  ungroup %>%
  distinct(NO_ORGAO) %>%
  sample_n(1) 

##
log_neg <- function(x) {
  sign(x) * log1p(abs(x))
}

##
indicadores  %>%
  ungroup %>%
  filter(
    NO_ORGAO %in% orgaos_sorteados$NO_ORGAO
  ) %>%
  mutate(
    integral_sobre_media_dos_gastos_log = sign(integral_sobre_media_dos_gastos) * log1p(abs(integral_sobre_media_dos_gastos))
  ) %>%
  ggplot(aes(x = integral_sobre_media_dos_gastos_log, y = NO_FONTE_RECURSO, colour = NO_FONTE_RECURSO)) +
  geom_jitter(aes(size = log_neg(integral))) +
  geom_hline(yintercept = 0, colour = "red") +
  labs(title = orgaos_sorteados$NO_ORGAO, subtitle = orgaos_sorteados$NO_FONTE_RECURSO) +
  geom_vline(xintercept = 0, colour = "red")
  
  