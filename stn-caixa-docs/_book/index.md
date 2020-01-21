--- 
title: "Documentação do projeto 'Execução Orçamentária e Financeira do Governo Federal' (\"Projeto Caixa\")"
author: "R6 Estatística e Treinamentos LTDA"
date: "2020-01-21"
site: bookdown::bookdown_site
output: 
  bookdown::gitbook:
    lib_dir: "book_assets"
documentclass: book
bibliography: [book.bib, packages.bib]
biblio-style: apalike
link-citations: yes
github-repo: curso-r/stn-caixa
description: "STN-Caixa"
header-includes:
  - \AtBeginDocument{\renewcommand{\chaptername}{Capítulo}}
---


# Introdução

O objetivo deste projeto é analisar o comportamento do caixa e das obrigações financeiras dos órgãos federais, com a finalidade de fornecer informações para a gestão da programação financeira por parte do Tesouro Nacional, além de identificar oportunidades de melhorias nesse processo, e possivelmente fundamentar a criação de indicadores para avaliação da gestão financeira das unidades do Governo Federal.

Elencamos aqui alguns aspectos importantes do projeto.

## Questões investigadas

De início, analisamos o perfil das despesas e receitas das unidades do Governo Federal, começando com os órgãos do Ministério da Justiça (que já possui um sistema de acompanhamento de despesas bem estruturado).

A análise procurou compatibilizar as informações orçamentárias com as informações financeiras. Chamamos de _classificadores orçamentários_: Função, Subfunção, Programa, Ação, Grupo de Despesa, Modalidade de Aplicação, Elemento de Despesa, Indicador de Resultado EOF, Indicador de Exceção Decreto. Como _classificadores financeiros_, nos referimos, essencialmente, à Vinculação de Pagamento.

A _Fonte de Recurso_ é um classificador comum a esses dois contextos, orçamentário e financeiro.

Com esse escopo em mente, em parceria com a equipe do GT-CEAD, as seguintes questões foram abordadas neste projeto:

a. Qual o comportamento do caixa e das obrigações a pagar (e da disponibilidade líquida) no período analisado^[Por órgão, por unidade e por fonte de recursos.]? 

b. Existem casos em que unidades de um mesmo órgão permanecem com disponibilidade líquida negativa, enquanto outras unidades desse mesmo órgão encontram-se com disponibilidade positiva? E se considerar a fonte de recursos, há casos em que o órgão passa por períodos com disponibilidade negativa em uma fonte enquanto há recursos disponíveis em outra fonte? E se considerar as duas situações conjuntamente^[Ou seja, uma unidade de um mesmo órgão fica com disponibilidade negativa em uma fonte, enquanto outra unidade desse mesmo órgão possui disponibilidade positiva nessa mesma fonte.]? 

c. Como as classificações orçamentárias se relacionam com as classificações financeiras? Especificamente, é possível identificar certos tipos de despesas que são sempre (ou frequentemente) pagas com recursos de determinadas vinculações? 

d. Caso seja possível a identificação mencionada em (c), as questões (a) e (b) seriam revisitadas para estimar a disponibilidade líquida para cada vinculação, considerando as classificações orçamentárias das obrigações. Nesse cenário, existem unidades com saldo total suficiente para cobrir todas as suas obrigações, porém com insuficiência em algumas vinculações?

e. Qual o comportamento do caixa das unidades em termos de movimentações?

f. Qual o intervalo entre duas operações^[Uma despesa alta seguida de um recebimento de recursos também alto.] de grande porte?

Para responder essas perguntas, utilizamos ferramentas descritivas e de modelagem preditiva, descritas nos Capítulos 3 e 4, respectivamente. 

## As bases de dados

<!-- Algumas ideias, a serem testadas: -->

<!-- * analisar as despesas pagas, pelos classificadores, pelo número da nota de empenho e pelo número do documento de pagamento; e relacionar documento de pagamento x nota de empenho x vinculação de pagamento pelo campo "inscrição" do documento de pagamento. -->

<!-- * analisar as despesas pagas, pelos classificadores, pelo número da nota de empenho e pelo número do documento de pagamento; e tentar compatibilizar com as informações dos pagamentos efetuados, por vinculação de pagamento e número do documento de pegamento. -->

<!-- * Mais simples: parecido com o anterior, a partir da tabela com as despesas pagas detalhadas pelos classificadores orçamentários, empenho e documento de pagamento, buscar a _vinculação de pagamento_ de uma tabela com toda a movimentação do limite de saque detalhada por documento. Assim, quando a movimentação do limite de saque for um pagamento, o documento correspondente, um documento de pagamento, pode ser usado como chave para relacionar as duas tabelas. -->

Para responder as questões levantadas no item anterior, os dados do SIAFI foram divididos em três bases de dados:

- 1. base de movimentações diárias do limite de saque;
- 2. base de pagamentos diários;
- 3. base de movimentações diárias nas obrigações a pagar.

Com as Tabelas 1 e 3, calculamos a _disponibilidade líquida diária_ a partir da subtração entre os saldos diários do caixa (Tabela 1) e as obrigações a pagar (Tabela 3), para cada unidade gestora ou órgão, e para cada fonte de recursos.

Com as Tabelas 1 e 2, relacionamos no contexto dos pagamentos, as informações orçamentrárias (Tabela 2) com os vínculos de pagamento (Tabela 1).

Finalmente com a Tabela 1, analisamos as movimentações para tipo de documento, obtendo um histórico das movimentações de cada órgão e cada Unidade Gestora.

Na primeira etapa do projeto, essas bases foram estudadas e validadas. Bases auxiliares também foram construídas para facilitar as análises subsequentes. A documentação dessa etapa se encontra no Capítulo 2.

## Análise descritiva

Dada a riqueza de informações e granularidade das bases de dados, todos os resultados descritivos foram construídos em uma aplicação online, que permite a manipulação das visualizações a partir de filtros e seletores.

O aplicativo pode ser acessado a partir do seguinte link: https://rseis.shinyapps.io/explorador_disponibilidades_liquidas_v2/

O código-fonte e manutenção do aplicativo foram repassados à equipe do GT-CEAD ao fim do projeto.

Um resumo dos principais resultados se encontra no Capítulo 3.

## Análise preditiva

Os modelos utilizados neste projeto consideraram os métodos em estado da arte dentro do contexto de modelagem preditiva, como florestas aleatórias, o algorítmo XGBoost e redes neurais.

A descrição dos modelos ajustados e seus resultados se encontram no Capítulo 4.

## Oficina de repasses e implementação dos produtos

A última etapa do projeto consistiu de uma oficina de repasses, realizada presencialmente no GT-CEAD, no Tesouro Nacional, em Brasília. Nessa oficina, foi discutida a teoria por trás dos métodos aplicados, tal como apresentada neste relatório. Também foram apresentados e explicados os scripts em linguagem de programação R utilizados para implementar os modelos.

