# Introdução



## Primeiras Instruções do Tiago

A ideia deste projeto é analisar o comportamento do caixa e das obrigações financeiras dos órgãos federais, com a finalidade de fornecer informações para a gestão da programação financeira por parte do Tesouro Nacional, além de identificar oportunidades de melhorias nesse processo, e possivelmente fundamentar a criação de indicadores para avaliação da gestão financeira das unidades do Governo Federal.

Vamos elencar aqui alguns aspectos, ou componentes, importantes do projeto, sem uma ordem específica.

## É preciso de início conhecer o perfil das despesas e receitas orçamentárias desses órgãos.

Vamos começar com um perfil das despesas do Ministério da Justiça (que já tem um excelente sistema de acompanhamento das despesas).

**Tentar compatibilizar as informações orçamentárias (classificações como função, subfunção, ação, grupo de despesa, indicadores orçamentários etc.) com as informações financeiras (vinculação de pagamento, essencialmente).**

O que estamos chamando de _classificadores orçamentários_: Função, Subfunção, Programa, Ação, Grupo de Despesa, Modalidade de Aplicação, Elemento de Despesa, Indicador de Resultado EOF, Indicador de Exceção Decreto.

O que estamos chamando de _classificadores financeiros_: Vinculação de Pagamento, essencialmente.

A _fonte de recurso_ é um caso especial, é um classificador comum a esses dois contextos, orçamentário e financeiro.

## Como fazer isso diretamente a partir do Siafi?

Algumas ideias, a serem testadas:

* analisar as despesas pagas, pelos classificadores, pelo número da nota de empenho e pelo número do documento de pagamento; e relacionar documento de pagamento x nota de empenho x vinculação de pagamento pelo campo "inscrição" do documento de pagamento.

* analisar as despesas pagas, pelos classificadores, pelo número da nota de empenho e pelo número do documento de pagamento; e tentar compatibilizar com as informações dos pagamentos efetuados, por vinculação de pagamento e número do documento de pegamento.

* Mais simples: parecido com o anterior, a partir da tabela com as despesas pagas detalhadas pelos classificadores orçamentários, empenho e documento de pagamento, buscar a _vinculação de pagamento_ de uma tabela com toda a movimentação do limite de saque detalhada por documento. Assim, quando a movimentação do limite de saque for um pagamento, o documento correspondente, um documento de pagamento, pode ser usado como chave para relacionar as duas tabelas.

Teríamos então três extrações: uma para a movimentação no caixa e outras duas, semelhantes em termos de detalhamentos, para os pagamentos totais e para as obrigações a pagar. A relação dos campos está simplificada, e os campos **destacados** são aqueles que só aparecem na tabela 1, ou que só aparecem nas tabelas 2 e 3.

### Movimentações diárias do Limite de Saque (item de informação: "LIMITES DE SAQUE")

- Órgão Máximo
- Órgão
- UG
- **Vinculação de Pagamento**
- Fonte Detalhada
- Fonte (posições 3 e 4 da fonte detalhada -- exemplo: se a fonte detalhada é: `0100123456`, a fonte será `00`)
- Documento Lançamento [chave para fazer a junção com tabela (2)]
- Movimento / Valor Financeiro

### Pagamentos diários (item de informação: "PAGAMENTOS TOTAIS")

- Órgão Máximo
- Órgão
- UG
- Fonte Detalhada
- Fonte (posições 3 e 4 da fonte detalhada -- exemplo: se a fonte detalhada é: `0100123456`, a fonte será `00`)
- **Função**
- **Subfunção**
- **Programa**
- **Ação**
- **Grupo de Despesa**
- **Modalidade de Aplicação**
- **Elemento de Despesa**
- **Indicador de Resultado EOF** (indica se a despesa é primária ou financeira, entre outras coisas)
- **Indicador de Exceção Decreto**
- **Ano do Empenho**
- **Empenho**
- **Órgão Máximo da UO** (o "dono" original do orçamento, que pode ter sido em algum momento "descentralizado", isto é, transferido, para um óutro "Órgão Máximo" -- ou seja, se o Órgão Máximo da UO é diferente do Órgão Máximo, significa que a unidade está realizando uma despesa com orçamento de outro órgão)
- Documento Lançamento [chave para fazer a junção com tabela (1)]
- Movimento / Valor Financeiro

### Movimentações diárias em obrigações a pagar (item de informação: "VALORES LIQUIDADOS A PAGAR (EXERCICIO + RP)")

- Órgão Máximo
- Órgão
- UG
- Fonte Detalhada
- Fonte (posições 3 e 4 da fonte detalhada -- exemplo: se a fonte detalhada é: `0100123456`, a fonte será `00`)
- **Função**
- **Subfunção**
- **Programa**
- **Ação**
- **Grupo de Despesa**
- **Modalidade de Aplicação**
- **Elemento de Despesa**
- **Indicador de Resultado EOF** (indica se a despesa é primária ou financeira, entre outras coisas)
- **Indicador de Exceção Decreto**
- **Ano do Empenho**
- **Empenho**
- **Órgão Máximo da UO** (o "dono" original do orçamento, que pode ter sido em algum momento "descentralizado", isto é, transferido, para um óutro "Órgão Máximo" -- ou seja, se o Órgão Máximo da UO é diferente do Órgão Máximo, significa que a unidade está realizando uma despesa com orçamento de outro órgão)
- Documento Lançamento (acho que não será necessário)
- Movimento / Valor Financeiro

## O que analisar?

Com **(1)** e **(3)** podemos obter os saldos diários do caixa (tabela **(1)**) e das obrigações a pagar (tabela **(3)**) -- e calcular a _disponibilidade líquida diária_, como sendo o saldo do caixa (item "LIMITES DE SAQUE") subtraído das obrigações a pagar (item "VALORES LIQUIDADOS A PAGAR (EXERCICIO + RP)")--, para cada unidade gestora ou órgão, e para cada fonte de recursos. Para isso sumarizaríamos os dados por DIA_LANC, UG, ORGAO, FONTE e ITEM_INFORMACAO. Essa seria a tabela **(i)**.

Com **(1)** e **(2)** poderíamos relacionar, no contexto dos pagamentos, as informações orçamentárias com as vinculações de pagamento, obtendo uma tabela **(ii)**. Partiríamos de **(2)** e faríamos um join com **(1)**, por "Documento de Lançamento", para trazer a "Vinculação de Pagamento" da tabela **(1)** (acho que seria interessante trazer também o campo de Movimento / Valor da tabela **(1)**, porque pode acontecer de um mesmo pagamento ter utilizado mais de uma _vinculação de pagamento_. Nesse caso, o valor mostrado na tabela **(2)** seria o valor consolidado, e precisaríamos do ).

Finalmente com **(1)**, podemos analisar as movimentações para tipo de documento, obtendo um histórico das movimentações de cada órgão e cada UG, a que chamaremos de **(iii)**.


## Questões iniciais a serem investigadas

a. Qual o comportamento do caixa e das obrigações a pagar (e da disponibilidade líquida) no período analisado? Por órgão? Por unidade? Por fonte? Por unidade e por fonte? (Tabela (i))

(semelhante ao que foi feito superficialmente [aqui](https://github.com/TesouroNacional/puddles-puddles), só que melhor, com mais rigor.)


a1. Há casos em que unidades de um mesmo órgão permanecem com disponibilidade líquida negativa, enquanto outras unidades desse mesmo órgão estão com disponibilidade positiva? E se levarmos em consideração a fonte de recursos, há casos em que o órgão passa por períodos com disponibilidade negativa numa fonte, enquanto há recursos disponíveis em outra fonte? E se levarmos em consideração as duas coisas (unidade + fonte: ou seja, uma unidade de um mesmo órgão fica com disponibilidade negativa numa fonte, enquanto outra unidade desse mesmo órgão possui disponibilidade positiva nessa mesma fonte?)

b. A partir de (ii), como as classificações orçamentárias se relacionam com as classificações financeiras? Especificamente, é possível identificar certos tipos de despesas que são sempre (ou frequentemente) pagas com recursos de determinadas vinculações? 

c. Se for possível a identificação mencionada em (b), então, poderíamos fazer uma versão de (i) em que os dados estariam detalhados também por _vinculação de pagamento_ e alguns _classificadores orçamentários_. Com o resultado de (b), poderíamos então refinar (a) e (a1), estimando a disponibilidade líquida para cada vinculação, considerando as classificações orçamentárias das obrigações. Por exemplo, a unidade pode ter saldo suficiente para cobrir todas as suas obrigações; mas, quando se analisam na prática que vinculações costumam pagar que obrigações (algo obtido de (b)), pode-se observar que na verdade há suficiência em algumas vinculações, mas insuficiência em outras.

d. Qual o comportamento do caixa das unidades, em termos de movimentações? Para isso, podemos considerar os seguintes tipos de movimentações (sete, por enquanto), de acordo com o sinal do valor da movimentação, e do tipo do documento de lançamento (posições 16 e 17 do campo `ID_DOCUMENTO`):

* Receitas próprias - movimentos positivos por RAs;
* Recebimentos de recursos financeiros - movimentos positivos por PFs;
* Anulações de pagamentos - movimentos positivos por DF, DR, GF, GP, GR ou OB;
* Ajustes contábeis - movimentos por NS;
* Pagamentos - movimentos negativos por DF, DR, GF, GP, GR ou OB;
* Ajustes na receita arrecadada (anulações, retificações etc.): movimentos negativos por RA; e
* Liberações de recursos para outros órgãos - movimentos negativos por PFs.

e. Provavelmente vamos observar grandes recebimentos de recursos financeiros seguidos por grandes despesas. Nesses casos, em geral, qual o intervalo entre essas duas operações?

## Inspirações

NatGeo immigrations. Pode ser interessante fazer algo semelhante para visualizar e comparar o saldo diário das unidades.

![](natgeo.jpg)

https://twitter.com/aLucasLopez/status/1153646875427385344?s=20

Para mostrar a composição das despesas, vamos usar um diagrama de bolhas em D3 semelhante [ao do Jim Vallandingham](https://vallandingham.me/bubble_charts_with_d3v4.html).
