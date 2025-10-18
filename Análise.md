# Motivações e Objetivos
1. Identificar as **áreas com mais risco de incêndios**
2. Identificar quais **épocas do ano acontece mais incêndios**
3. Identificar quais os **anos com mais incêndios** e mais graves
4. Prever como as **temperaturas** impactam os incêndios (tanto no número de incêndios, na gravidade e duração)
5. Observar como o **nível de vegetação** afeta os incêndios (tanto na ocorrência dos mesmos, na gravidade e na duração dos mesmos)
6. Observar como o **tipo de vegetação** impacta os incêndios
7. Como os **meios terrestres e aérios** afetam a duração e gravidade do incêndio

#  Identificar Questões Analíticas

## Objetivo 1 (ICNF)
- Quantidade de incêndios por **zona / distrito / concelho**
- Área ardida total por **zona / distrito / concelho**
- Percentagem da área total ardida em relação à área do distrito/concelho
- Número médio de ocorrências por km²
## Objetivo 2 (ICNF)
- Número de incêndios por **mês / estação / semana**
- Área ardida média por mês
- Distribuição sazonal dos incêndios (gráfico de calor por mês e região)
## Objetivo 3 (ICNF)
- Quantidade de incêndios por ano
- Área ardida total e média por incêndio por ano
- Tendência temporal (linha do tempo de evolução)
- Comparação de gravidade (pequenos, médios, grandes incêndios)
- Média de duração dos incêndios por ano
## Objetivo 4 (ICNF e Open-Meteo)
- Número de incêndios por faixa de temperatura média diária
- Área ardida total por faixa de temperatura máxima
- Média de área ardida por incêndio por faixa de temperatura
- Contagem de incêndios por combinação de temperatura e região
- Duração média dos incêndios por faixa de temperatura
- Índice de severidade de incêndios por faixa de temperatura
## Objetivo 5 (arranjar dataset para isto)
- Correlação entre NDVI (índice de vegetação) e ocorrência de incêndios
- NDVI médio nas áreas com e sem incêndios
- Evolução do NDVI antes e depois de um incêndio
- Percentagem de área ardida com NDVI elevado
## Objetivo 6 (arranjar dataset para isto)
- Número de incêndios por tipo de vegetação (floresta, mato, pastagem, etc..) (o tipo de árvores acho que é importante, porque eucaliptos são quase gasolina quando está muito quente)
- Área ardida média por tipo de vegetação
- Percentagem de incêndios florestais vs. agrícolas
- Tipos de vegetação mais recorrentes em incêndios graves

## Objetivo 7 (ANEPC - Proteção Civil)
- Tempo total de duração do incêndio por quantidade de meios terrestres mobilizados
- Área ardida final por quantidade de meios aéreos utilizados
- Tempo médio de extinção por tipo e quantidade de meios utilizados
- Área ardida por tempo de chegada dos primeiros meios (em faixas de minutos)
- Número de operacionais por hectare de área ardida
- Taxa de expansão do incêndio antes e depois da chegada dos meios aéreos
- Número de reacendimentos por tipo de combate utilizado
- Eficácia média de contenção por combinação de meios (terrestres e aéreos)

# Identificar Processos de Negócio
- Ocorrência de Incêndio
    - Registro de cada evento de incêndio, incluindo localização, duração, área ardida, causa
- Meteorologia Diária
    - Registro das condições meteorológicas diárias por região/localização
- Operações de Combate a Incêndios
    - Registro dos meios mobilizados, tempos de resposta e eficácia por incêndio
- Monotorização de Vegetação
    - Medições periódicas de índices de vegetação (NDVI) e classificação de tipos de vegetação

# Método dos 4 Passos

## Ocorrência de Incêncdio
- **Grão:** Uma linha (evento) representa um incêndio
- **Dimensões:** 
    - **What:** Tipo de incêndio (florestal, agrícula, urbano)
    - **Who:** Entidade responsável pelo registo (ICNF) 
    - **When:** Data e hora de início e extinsão
    - **Where:** Numa localização específica (município, concelho, distrito, cidade, coordenadas)
- **Medidas:**
    - Área ardida (hectares) - (elementar) (aditiva)
    - Duração do incêndio (horas) - (elementar) (aditiva)
    - Número de focos iniciais - (elementar) (aditiva)
    - Severidade do incêndio - (derivada) (não-aditiva)

## Meteorologia Diária
- **Grão:** Uma linha (evento) representa as condições meteorológicas de um dia numa localização
- **Dimensões:**
    - **What:** Tipo de condição meteorológica
    - **When:** Dia, Mês e Ano (data)
    - **Where:** Estação meteorológica (não é relevante para o estudo)
- **Dimensões:**
    - Temperatura média (ºC) - (elementar) (não-aditiva)
    - Temperatura máxima (ºC) - (elementar) (não aditiva)
    - Humidade relativa (%) - (elementar) (não-aditiva)
    - Velocidade do vento (km/h) - (elementar) (não-aditiva)
    - Precipitação (mm) - (elementar) (aditiva)
    - Índice de risco de incêndio (derivado) (não-aditivo)

## Operações de Combate a Incêndios
- **Grão:** Uma linha (evento) representa uma operação de combate num incêndio específico
- **Dimensões:**
    - **What:** Tipo de operação (primeira intervenção, combate prolongado, rescaldo)
    - **Who:** Entidades mobilizadas (bombeiros, proteção civil, etc...)
    - **When:** Data e hora da operação
    - **Where:** Localização da operação (município, concelho, distrito, cidade, coordenadas)
- **Medidas:**
    - Número de operacionais mobilizados - (elementar) (aditiva)
    - Número de veículos terrestres mobilizados - (elementar) (aditiva)
    - Número de meios aérios mobilizados - (elementar) (aditiva)
    - Tempo de resposta inicial (minutos) - (elementar) (não-aditiva)
    - Taxa de expansão do incêndio (ha/hora) - (derivada) (não-aditiva)
    - Eficácia da contenção (%) - (derivada) (não-aditiva)

## Monitorização de Vegetação
- **Grão:** Uma linha (evento) representa uma medição de vegetação numa área específica
- **Dimensões:**
    - **What:** Tipo de vegetação e classificação
    - **When:** Data da medição (dia, mês, ano)
    - **Where:** Área geográfica (município, concelho, distrito, cidade, coordenadas)
- **Medidas:**
    - Índice NVDI - (elementar) (não-aditiva)
    - Densidadede vegetação - (elementar) (não-aditiva)
    - Percentagem por tipo de vegetação - (derivada) (não-aditiva)
    - Índice de combustibilidade - (derivado) (não-aditivo)

---
**Tipos de Medida:**
    - **Elementar:** Medidas básicas capturadas diretamente dos dados brutos, sem cálculos adicionais
    - **Derivada:** Medidas calculadas a partir de outras medidas através de fórmulas ou algoritmos

**Propriedades de Agregação:**
    - **Aditivo:** Medidas que podem ser somadas de forma significativa ao longo de todas as dimensões (tempo, espaço, etc...)
    - **Não-Aditivo:** Medidas que não podem ser somadas de forma significativa em pelo menos uma dimensão. 