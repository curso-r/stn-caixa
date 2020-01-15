# Validação e Compreensão dos Dados

## Introdução

A base de dados do SIAFI concentra as informações geradas pelo processo de execução orçamentária e programação financeira do Governo Federal. Este projeto tem como objetivo gerar conhecimento sobre o comportamento do caixa e das obrigações financeiras dos órgãos federais para fins de gestão da programação financeira por parte do Tesouro Nacional, além de identificar oportunidades de melhorias nesse processo e, possivelmente, fundamentar a criação de indicadores para avaliação da gestão financeira das unidades do Governo Federal.

Este é o primeiro dos quatro relatórios que irão compor o projeto e descreve o processo de conhecimento, ajuste e preparo das bases de dados para análises subsequentes.

## Questões elementares

Para nortear as análises das próximas etapas, nessa primeira fase de conhecimento do problema e da base, foram levantadas as seguintes questões:

a. Qual o comportamento do caixa e das obrigações a pagar (e da disponibilidade líquida) no período analisado^[Por órgão, por unidade e por fonte de recursos.]? 

b. Existem casos em que unidades de um mesmo órgão permanecem com disponibilidade líquida negativa, enquanto outras unidades desse mesmo órgão encontram-se com disponibilidade positiva? E se considerar a fonte de recursos, há casos em que o órgão passa por períodos com disponibilidade negativa em uma fonte enquanto há recursos disponíveis em outra fonte? E se considerar as duas situações conjuntamente^[Ou seja, uma unidade de um mesmo órgão fica com disponibilidade negativa em uma fonte, enquanto outra unidade desse mesmo órgão possui disponibilidade positiva nessa mesma fonte.]? 

c. Como as classificações orçamentárias se relacionam com as classificações financeiras? Especificamente, é possível identificar certos tipos de despesas que são sempre (ou frequentemente) pagas com recursos de determinadas vinculações? 

d. Caso seja possível a identificação mencionada em (c), as questões (a) e (b) seriam revisitadas para estimar a disponibilidade líquida para cada vinculação, considerando as classificações orçamentárias das obrigações. Nesse cenário, existem unidades com saldo total suficiente para cobrir todas as suas obrigações, porém com insuficiência em algumas vinculações?

e. Qual o comportamento do caixa das unidades em termos de movimentações?

f. Qual o intervalo entre duas operações^[Uma despesa alta seguida de um recebimento de recursos também alto.] de grande porte?

## Bases de dados levantadas para endereçar as questões

O perfil das despesas do **Ministério da Justiça** será utilizado como ponto de partida das análises descritivas e exploratórias. A escolha deste órgão foi em virtude do seu excelente sistema de acompanhamento das despesas.

Ao todo, três bases foram extraídas:

- `lim_saque` com as movimentações de limites de saque;
- `obrigacoes` com as movimentações de obrigações a pagar; e
- `pagamentos` com as movimentações de pagamentos;

A partir destas, outras três tabelas derivadas foram construídas. As descrições detalhadas estão na seção seguinte.

- `disponibilidades_liquidas_diarias` com as informações diárias de **saldo disponível** e **obrigações a pagar** de cada UG para cada fonte de recursos;

- `vinculacao_de_pagamentos` com informações diárias pareadas de **pagamentos**, **saldo disponível** e **vinculações de pagamentos** de cada documento;

- `lim_saque_por_tipo_de_documento` com as informações diárias de **saldo disponível** por tipo de documento (e.g. NS, OB, PF, etc.).

Verificou-se que as extrações **encontram-se prontas para análise** e com replicações em formatos `.rds` para serem leitas pelo software R. Abaixo estão listados os seus respectivos campos.

## Base 1: Movimentações diárias do Limite de Saque

**Filtro:** item de informação "LIMITES DE SAQUE".

**Campos:**

- Órgão Máximo
- Órgão
- UG
- **Vinculação de Pagamento**
- Fonte de Recursos Detalhada
- Fonte de Recursos
- Documento Lançamento
- Movimento / Valor Financeiro

## Base 2: Pagamentos diários

**Filtro:** item de informação "PAGAMENTOS TOTAIS".

**Campos:**

- Órgão Máximo
- Órgão
- UG
- Fonte de Recursos Detalhada
- Fonte de Recursos
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
- **Órgão Máximo da UO** 
- Documento Lançamento
- Movimento / Valor Financeiro

## Base 3: Movimentações diárias em obrigações a pagar 

**Filtro:** item de informação "VALORES LIQUIDADOS A PAGAR (EXERCICIO + RP)".

**Campos:**

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
- **Órgão Máximo da UO** 
- Movimento / Valor Financeiro

## Tabelas Derivadas

### Disponibilidades líquidas Diárias

- Informações diárias de **saldo disponível** e **obrigações a pagar** de cada UG para cada fonte de recursos. 

- Útil para as questões **a**, **c** e **e**.

- Cruzamento entre as bases `lim_saque` e `obrigacoes` pelas chaves `NO_DIA_COMPLETO`, `NO_FONTE_RECURSO` e `NO_UG`.

- Observações: 352.037

- Campos: 11

```
* NO_DIA_COMPLETO         `<date> 2017-08-22, 2017-08-23, 2017-08-24, 2017-08…`
* NO_UG                   `<chr> "ACADEMIA NACIONAL DA POLICIA RODOV. FEDERAL…`
* NO_ORGAO                `<chr> "DEPARTAMENTO DE POLICIA RODOVIARIA FEDERAL/…`
* NO_FONTE_RECURSO        `<chr> "RECEITAS DE CONCURSOS DE PROGNOSTICOS", "RE…`
* saldo_diario            `<dbl> -2779.98, -5654.96, -7356.26, -5601.60, -560…`
* obrigacoes_a_pagar      `<dbl> 0.000000e+00, 0.000000e+00, 0.000000e+00, 0.…`
* disponibilidade_liquida `<dbl> -2779.98, -5654.96, -7356.26, -5601.60, -560…`
* ano                     `<dbl> 2017, 2017, 2017, 2017, 2017, 2017, 2017, 20…`
* mes                     `<dbl> 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9,…`
* dia                     `<int> 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 1, 2…`
* paded                   `<lgl> TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE, …`
```

### Vinculação de Pagamentos

- Informações diárias pareadas de **pagamentos**, **saldo disponível** e **vinculações de pagamentos** de cada documento.

- Útil para as questões **b**, **c** e **e**.

- Cruzamento entre as bases `lim_saque` e `pagamentos` pelas chaves `NO_DIA_COMPLETO` e `ID_DOCUMENTO`.

- Observações: 1.005.187

- Campos: 7

```
* NO_DIA_COMPLETO         `<chr> "01/02/2017", "01/02/2017", "01/02/2017", "0…`
* ID_DOCUMENTO            `<chr> "194003192082017OB800016", "194003192082017O…`
* pagamento               `<dbl> 20.79, 724.21, 8000.00, 76.95, -15188.99, -9…`
* NO_VINCULACAO_PAGAMENTO `<chr> "CUSTEIO/INVESTIMENTO - RESUL.PRIM = 2", "CU…`
* vinculacoes_distintas   `<int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…`
* saldo_diario            `<dbl> -20.79, -724.21, -8000.00, -76.95, 15188.99,…`
* pagamento_por_saldo     `<dbl> -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, …`
```

### Limimtes de Saque Por Tipo De Documento

- Informações diárias de **saldo disponível** por tipo de documento. Os tipos de documentos são: `DF`, `DR`, `GF`, `GP`, `GR`, `NL`, `NS`, `OB`, `PF` e `RA`.

- Útil para a questão **d**.

- Derivada da base `lim_saque`.

- Observações: 254.667

- Campos: 7

```
* tipo_de_documento  `<chr> "DF", "DF", "DF", "DF", "DF", "DF", "DF", "DF", "…`
* NO_DIA_COMPLETO    `<chr> "01/02/2017", "01/02/2017", "01/02/2017", "01/02/…`
* NO_UG              `<chr> "COORD. REG. NOROESTE DO MATO GROSSO/MT", "COORDE…`
* NO_ORGAO           `<chr> "FUNDACAO NACIONAL DO INDIO", "DEPARTAMENTO DE PO…`
* NO_ITEM_INFORMACAO `<chr> "LIMITES DE SAQUE (OFSS, DIVIDA, BACEN E PREV)", …`
* NO_FONTE_RECURSO   `<chr> "RECURSOS ORDINARIOS", "RECURSOS ORDINARIOS", "TX…`
* saldo_diario       `<dbl> -35.47, -2089.65, -3644.19, -12.01, -14.94, -31.3…`
```


