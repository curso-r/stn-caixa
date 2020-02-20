# Índices de empoçamento



No capítulo anterior identificamos o que é empoçamento e quais são os seus principais tipos. Neste capítulo vamos apresentar e avaliar indicadores que permitem:

1. **Quantificar** o empoçamento
1. **Classificar** quanto ao tipo de empoçamento

Os índices desenvolvidos pretendem capturar as principais características da série de disponibilidade líquida que caracterizam algum tipo de empoçamento.

Os índices foram calculados por janelas de 1 ano, isto é, para cada data disponível no banco de dados foram considerados dados dos 365 dias anteriores para o cálculo do índice. Calcular os índices desta forma permite:

1. **Comparar** o índice de UG/Fontes que não possuem o mesmo histórico
1. **Avalliar** a evolução dos indicadores com o tempo

Para os casos em que queremos avaliar as UG's/FONTE sem observar o efeito do tempo consideramos a média do índice em todos os instantes do tempo em que foi calculado.

Também é importante notar que algumas UG/FONTE possuem histórico pequeno para ser analisado de formar estatística, e por isso, foram excluidas das análises a seguir. Para decidir quais seriam analisadas fizemos gráfico a seguir que mostra a quantidade de UG's para cada quantidade de dias com hisórico.

<img src="04-indices_files/figure-html/unnamed-chunk-2-1.png" width="672" />

Como boa parte das UG/Fonte possuem todo o histórico, optamos por pegar apenas aquelas que possuem pelo menos 1 ano de histórico, de forma a obter estimativas mais robustas. Com a exclusão de algumas combinações passamos de 856 para 601 combinações de UG e Fonte de recurso.

## Índice acumulação de disponibilidade líquida

Esse índice representa o quanto o valor de disponibilidade líquida positiva foi maior em média do que total de débitos em 1 ano. Em outras palavras, podemos dizer que quando este índice é próximo de 0 significa que sua disponibilidade líquida média sempre foi muito menor do que os seus pagamentos. Quando ele é próximo de 1, indica que a disponibilidade líquida média foi sempre parecida com todos os gastos de 1 ano.

### Cálculo

O cálculo do índice é descrito da seguinte maneira:

$$IADL_i = \frac{\hat{dl_i}}{\hat{d_i}}$$
Em que $dl_i$ é a disponibilidade líquida no dia $i$ e $d_i$ é o débito no dia $i$ 

$$\hat{dl_i} = \frac{1}{365}\sum_{i=1}^{365}dl_{-i}$$

$$\hat{d_i} = \sum_{i=1}^{365} d_{-i}$$

### Distribuição

Uma vez que o índice é calculado em janelas de 1 ano, quando mostrarmos a distribuição por UG, iremos avaliar apenas o valor do índice no último dia em que foi possível calculá-lo para aquela combinação UG/Fonte. Isso pode não ser exatamente o último dia de histórico da base de dados pois uma combinação UG/Fonte pode parar de existir ao longo do tempo.

Note que estamos avaliando a combinação UG/FONTE o que totaliza 601 no banco de dados analisado.

#### IADL maior do que 1

Em primeiro lugar avaliamos aquelas combinações UG e Fonte que possuem  IADL mairo do que 1. O índice ser maior do que 1 significa que a disponibilidade líquida média diária foi maior do que tudo que foi gasto durante o ano inteiro. Em geral, quando o IADL é maior do que 1, é por que nenhuma despesa aconteceu durante ano e aquela combinação possuia disponibilidade líquida positiva.


iadl > 1      n
---------  ----
não         566
sim          35

No gráfico abaixo é possível visualizar as 10 combinações com maiores valores do IADL.

<img src="04-indices_files/figure-html/unnamed-chunk-4-1.png" width="672" />

Veja que esses casos são os mais clássicos de empoçamento pois existe disponibilidade líquida positiva e nenhum gasto. Esses são casos anteriormente chamamos de *empoçamento total*.

Esses podem não ser os casos interessantes de empoçamento mas, nas próximas análises vamos combinar este índice com a disponibilidade líquida média diária para poder encontrar empoçamentos com valores mais altos.

#### Distribuição do IADL

No gráfico abaixo podemos visualizar um historama da distribuição do IADL.
Cada barra mostra a quantidade de combinações UG e Fonte que possuem aquele valor do IADL.
Podemos verificar que a maioria das combinações possui valor do IADL muito ptóximo de 0.

<img src="04-indices_files/figure-html/unnamed-chunk-5-1.png" width="672" />

#### IADL próximo de zero

Vamos observar agora alguns exemplos de combinações que possuem IADL bem próximo de zero. 
Lembre-se que próximo de zero significa que não há empoçamento.

<img src="04-indices_files/figure-html/unnamed-chunk-6-1.png" width="672" />

Mais uma vez esses podem não ser os casos mais interessantes de empoçamento, pois, são aqueles em que a disponibilidade líquida é negativa durante todo período. No entanto, isso mostra que o indicador consegue capturar quando não existe empoçamento.

#### Mais exemplos

O gráfico a seguir mostra exemplos de combinações UG/Fonte que estão próximas
de cada quantil da distribuição do IADL. Podemos verificar por esse gráfico que o IADL parece ser uma medida razoável para quantificar o empoçamento.

<img src="04-indices_files/figure-html/unnamed-chunk-7-1.png" width="672" />
Com as análises anteriores mostramos que o IADL parece ser uma medida razoável para quantificar o empoçamento. A seguir vamos apresentar um indicador que será útil para a classificação do tipo de empoçamento.









