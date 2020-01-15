# Quadro analítico histórico 




## Disponibilidades Líquidas

Para responder as questões (a) e (b) sobre disponibilidades líquidas das UGs, elaboramos:

- Gráficos das séries temporais das disponibilidades líquidas de cada UG e Fonte de Recurso.
- Gráficos das séries temporais das disponibilidades líquidas consolidadas por UG.

Aplicativo: [Explorador das séries temporais das disponibilidades líquidas](https://rseis.shinyapps.io/explorador_disponibilidades_liquidas)

- Indicador de disponibilidade líquida acumulante para as UGs.

### Indicador disponibilidade líquida acumulante por UG

**1) Disponibilidades Líquidas Acumulantes:** Indicador que apresenta valor alto quando uma UG apresenta disponibilidade líquida que apenas cresce com o passar do tempo para uma determinada fonte de recurso.

![(\#fig:unnamed-chunk-2)Disponibilidade líquida por fonte de recursos do CONSELHO ADMINISTRATIVO DE DEFESA ECONÔMICA. A fonte RECURSOS NÃO-FINANCEIROS DIRETAMENTE ARRECADADOS (linha verde) é um exemplo de disponibilidade líquida acumulante.](03-quadro-historico_files/figure-latex/unnamed-chunk-2-1.pdf) 

Definição do indicador: $P_1 + P_2$

em que 

$$
P_1 = \frac{1}{N}\sum I(y_i > y_{i - 1})
$$

e **para quando a disponibilidade diminui**

$$
P_2 = \frac{1}{N_{y_i < y_{i - 1}}}\sum I(|y_i -y_{i - 1}| < \sigma)
$$

Em outras palavras, o indicador aponta curvas crescentes ($P_1$) permitindo pequenas perturbações ($P_2$).

Abaixo estão as UGs com os maiores valores do indicador, e suas respectivas fontes de recursos:


\begin{tabular}{l|l|r}
\hline
UG & Fonte de Recursos & Indicador\\
\hline
CONSELHO ADMINISTRATIVO DE DEFESA ECONOMICA & RECURSOS NAO-FINANCEIROS DIRETAM. ARRECADADOS & 1.23\\
\hline
SUPERINTENDENCIA REG. POL. RODV. FEDERAL-BA & RECURSOS DIVERSOS & 1.20\\
\hline
FUNDO NACIONAL ANTIDROGAS & RECURSOS NAO-FINANCEIROS DIRETAM. ARRECADADOS & 1.19\\
\hline
SUPERINTENDENCIA REG. POL. RODV. FEDERAL-GO & RECURSOS DIVERSOS & 1.14\\
\hline
SUPERINTENDENCIA REG. POL. RODV. FEDERAL-SC & RECURSOS DIVERSOS & 1.11\\
\hline
DEPARTAMENTO PENITENCIARIO NACIONAL & RECURSOS NAO-FINANCEIROS DIRETAM. ARRECADADOS & 1.10\\
\hline
SUPERINTENDENCIA REG. POL. RODV. FEDERAL-RO & RECURSOS DIVERSOS & 1.10\\
\hline
SUPERINTENDENCIA REG. POL. RODV. FEDERAL-RO & RECURSOS DIVERSOS & 1.09\\
\hline
SUPERINTENDENCIA REG. POL. RODV. FEDERAL-PR & RECURSOS NAO-FINANCEIROS DIRETAM. ARRECADADOS & 1.07\\
\hline
\end{tabular}



## Classificações Orçamentárias e Financeiras

Destino das fontes de recursos e suas respectivas funções.

![](03-quadro-historico_files/figure-latex/unnamed-chunk-4-1.pdf)<!-- --> 

- Todas as fontes de recursos são repartidas entre **previdência social** e **segurança pública**;
- Porém, se a função for **INSS - EPU CUSTEIO**, o recurso é destinado a Previdência social.

## Comportamento do Caixa por Movimentação

- Gráficos das séries temporais dos saldos e obrigações de cada UG e Fonte de Recurso.
- Gráficos das séries temporais dos saldos e obrigações consolidados por UG.
- Gráfico dos tempos entre duas movimentações de grande porte por UG e por Órgão.

Aplicativo: [Explorador das séries temporais das disponibilidades líquidas](https://rseis.shinyapps.io/explorador_disponibilidades_liquidas)
