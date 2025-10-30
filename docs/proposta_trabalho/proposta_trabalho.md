# Proposta de Trabalho

## Dataset

### ICNF
O principal dataset consiste numa versão reduzida dos dados recolhidos do repositório [icnf_fire_data](https://github.com/cityxdev/icnf_fire_data), que é um repositório no github que tem como objetivo filtrar os dados em xml para csv do site `https://fogos.icnf.pt/localizador/webserviceocorrencias.asp`, que contém um histórico detalhado sobre todas as ocorrências e alertas de incêndios desde 2001. No Entanto vão ser somente analisados os dados desde 2020 até 2025, removendo:
- falsos alarmes
- registos com coordenadas em falta
- incêndios com área ardida inferior a 5 hectares
- queimadas controladas
- ocorrências que não são classificadas como incêndios
- registos sem data/hora de início ou fim

O dataset do ano 2025 só irá ter dados até dados até 06/10/2025

### Meteorologia
Para além dos dados dos incêndios, foi realizado um script em python que vai à API do [open-meteo](https://open-meteo.com), onde, para cada ano serão criados dois ficheiros:
- `meteorology_[ano].csv` - contém os registos diários de meteorologia associados a cada incêndio (uma linha por dia e por `incident_id`)
- `summary_[ano].csv` - contém uma agregação por `incident_id` (intervalo de datas de incêndios, média das temperaturas, número de dias, e coordenadas)
    - os dados do icnf já contêm dados acerca da média das temperaturas, portanto este ficheiro sere como validação dos registos do ficheiro `meteorology_[ano].csv`, para que este se torne numa fonte de verdade.

### RSS Google News
Para complementar os dados principais, foi utilizada a API do Google News para extrair artigos noticiosos sobre incêndios florestais em Portugal. Os dados foram recolhidos através de: 
- Filtragem por idioma (português de Portugal)
- Seleção de artigos contendo termos-chave relacionados com incêndios
- Limitação ao período entre 2020 e 2025
- Extração de metadados como título, data, fonte e URL

Ainda não se sabe muito bem onde se irá utilizar estes dados, visto que ainda não se fez uma filtragem e análise mais profunda dos mesmos. No entanto visa-se que estes forneçam informação que não se conseguiu encontrar online, como: informações sobre meios aérios e terrestres.

### DECIR - Dispositivo Especial de Combate a Incêndios Rurais
Da DECIR encontrou-se pdfs da Diretiva Operacional Nacional nº 2 dos anos de 2020 a 2025, onde são disponibilizados dados sobre meios aéreos e meios terrestres a vários níveis utilizados durante o combate a incêndios desse ano.

Infelizmente, até à entrega do documento, ainda não se conseguiu extrair os dados dos  pdf's para um outro formato mais conveniente, visto que os mesmos são bastante irregulares na sua formatação.

### MODIS — MOD13Q1 (NDVI 16-day, 250 m)
coleção MOD13Q1 fornece o índice NDVI em composites de 16 dias a 250 m (escala 0.0001 no produto bruto). Para o nosso estudo vamos usar a colecção disponibilizada no Google Earth Engine (MODIS/006/MOD13Q1) e extrair, por evento ICNF, estatísticas zonais (média, contagem de pixels) em janelas pré e pós-incêndio. Serão tratados os anos 2020–2024; cada feição de incêndio receberá valores agregados (ndvi_pre_mean, ndvi_pre_count, ndvi_post_mean, …).

**Campos/uso:** NDVI (corrigido por escala), timestamp da cena, agregações por perímetro.

**Período / resolução:** 16 dias / 250 m; cobertura global contínua (usaremos 2020–2024 para Portugal continental).

**Tamanho (estimativa):** como usaremos o GEE para processar e exportar apenas estatísticas por perímetro, o dataset final exportado (CSV com uma linha por incêndio e colunas NDVI agregadas) terá tipicamente alguns MB a poucas dezenas de MB; o volume dos produtos raster brutos para Portugal 2020–2024 é consideravelmente maior (dependendo do formato, tipicamente algumas centenas de MB até ~a poucos GB se descarregares mosaicos 16-day para todo o território). Nota: o tamanho final depende do nível de descarregamento (imagens brutas vs. estatísticas agregadas).

### CORINE Land Cover (CLC 2018 / Copernicus)
**Descrição:** mapa de cobertura/uso do solo harmonizado à escala europeia (CORINE Land Cover 2018) — camada vetorial/raster com classes temáticas (florestas, matos, pastagens, agricultura, áreas urbanas, etc.). Usada para atribuir tipo de uso do solo a perímetros de incêndio e para amostragem pareada (áreas de controlo).
Campos/uso: código CLC (nível 3), descrição da classe, geometria polygonal; intercetion/overlay com perímetros ICNF para calcular área por classe.

**Período / resolução:** produto 2018 (resolução nominal ~100 m, MMU ≈ 25 ha para polígonos).

**Tamanho (estimativa):** ficheiro vetorial para Portugal continental descarregado em GeoPackage/GeoJSON tem tipicamente alguns MB a ~tens de MB; operações rasterizadas ou tiles para todo o país podem ocupar mais espaço, mas as tabelas resultantes (áreas por perímetro) são pequenas (MBs).

### INE
Extração de indicadores socioeconómicos do Instituto Nacional de Estatística (INE) a nível municipal (NUTS III) ou de freguesia. Estes dados (e.g., demografia, emprego por setor, valor da produção agrícola, turismo) serão correlacionados com a ocorrência de grandes incêndios para quantificar o impacto pós-evento e identificar vulnerabilidades socioeconómicas regionais.

## Objetivos
1. Identificar as **áreas com mais risco de incêndios**
2. Identificar quais **épocas do ano acontece mais incêndios**
3. Identificar quais os **anos com mais incêndios** e mais graves
4. Prever como as **temperaturas** impactam os incêndios (tanto no número de incêndios, na gravidade e duração)
5. Analisar como o **estado da vegetação** (NDVI) influencia a probabilidade de ocorrência, a gravidade e a evolução temporal dos incêndios em Portugal continental (2020–2024)
6. Avaliar o impacto do **tipo de vegetação** / uso do solo na ocorrência, extensão e gravidade dos incêndios, incluindo diferenças por classes (florestal, mato, pastagem, agrícola) 
7. Como os **meios terrestres e aéreos** afetam a duração e gravidade do incêndio
8. Como os fogos afetaram a freguesia onde os mesmos ocorreram

## Questões Analíticas

### Objetivo 1 (ICNF)
- Quantidade de incêndios por **zona / distrito / concelho**
- Área ardida total por **zona / distrito / concelho**
- Percentagem da área total ardida em relação à área do distrito/concelho
- Número médio de ocorrências por km²
### Objetivo 2 (ICNF)
- Número de incêndios por **mês / estação / semana**
- Área ardida média por mês
- Distribuição sazonal dos incêndios (gráfico de calor por mês e região)
### Objetivo 3 (ICNF)
- Quantidade de incêndios por ano
- Área ardida total e média por incêndio por ano
- Tendência temporal (linha do tempo de evolução)
- Comparação de gravidade (pequenos, médios, grandes incêndios)
- Média de duração dos incêndios por ano
### Objetivo 4 (ICNF e Open-Meteo)
- Número de incêndios por faixa de temperatura média diária
- Área ardida total por faixa de temperatura máxima
- Média de área ardida por incêndio por faixa de temperatura
- Contagem de incêndios por combinação de temperatura e região
- Duração média dos incêndios por faixa de temperatura
- Índice de severidade de incêndios por faixa de temperatura
### Objetivo 5 (CNF (perímetros) + MODIS MOD13Q1 + CORNIE)
- Avaliar a correlação entre NDVI pré-incêndio e a ocorrência de incêndio - ICNF (perímetros) + MODIS MOD13Q1 (NDVI, 250 m, 16 dias)
- Comparar o NDVI médio pré-incêndio em áreas que sofreram incêndio vs áreas de controlo - ICNF (perímetros) + MODIS MOD13Q1 + CORINE (uso do solo)
- Examinar a evolução temporal do NDVI alinhada pela data do incêndio (t0) - ICNF (perímetros & t0) + MODIS MOD13Q1 (séries nacionais) 
- Calcular a percentagem da área ardida que, antes do incêndio, apresentava NDVI elevado (thresholds a testar) - ICNF (perímetros) + MODIS MOD13Q1 
### Objetivo 6 (ICNNF + CORNIE)
-  Número de incêndios por classe de uso do solo / tipo de vegetação (ex.: florestas, mato, pastagens, agricultura) - ICNF (perímetros) + CORINE (mapa de classes)
- Área ardida média por classe de uso do solo - ICNF + CORINE
- Percentagem de incêndios em classes florestais vs classes agrícolas - ICNF + CORIN
- Classes de uso do solo mais frequentemente associadas a incêndios graves - ICNF (para métricas de severidade) + CORINE

### Objetivo 7 (DECIR)
- Tempo total de duração do incêndio por quantidade de meios terrestres mobilizados
- Área ardida final por quantidade de meios aéreos utilizados
- Tempo médio de extinção por tipo e quantidade de meios utilizados
- Área ardida por tempo de chegada dos primeiros meios (em faixas de minutos)
- Número de operacionais por hectare de área ardida
- Taxa de expansão do incêndio antes e depois da chegada dos meios aéreos
- Número de reacendimentos por tipo de combate utilizado
- Eficácia média de contenção por combinação de meios (terrestres e aéreos)

### Objetivo 8 (ICNF + INE)
- **Variação demográfica:** Comparar a evolução da população residente e da estrutura etária em freguesias afetadas por grandes incêndios com freguesias de controlo (não afetadas).
- **Impacto no emprego:** Analisar a variação do número de postos de trabalho, especialmente nos setores agrícola e florestal, nos anos seguintes ao incêndio.
- **Impacto no setor imobiliário e turismo:** Avaliar a evolução do valor mediano dos imóveis e do número de alojamentos turísticos em freguesias afetadas.
- **Análise da atividade económica:** Correlacionar a ocorrência de grandes incêndios com a variação do volume de negócios de empresas locais ou do rendimento familiar disponível.
- **Vulnerabilidade socioeconómica:** Identificar se freguesias com menor densidade populacional, maior envelhecimento ou maior dependência do setor primário sofrem impactos mais severos ou têm uma recuperação mais lenta.

## Identificação dos Processos de Negócio
- **Ocorrência de Incêndio**
    - Registro de cada evento de incêndio, incluindo localização, duração, área ardida, causa
- **Meteorologia Diária**
    - Registo das condições meteorológicas diárias por região/localização
- **Operações de Combate a Incêndios**
    - Registo dos meios mobilizados, tempos de resposta e eficácia por incêndio
- **Monitorização de Vegetação**
    - Medições periódicas de índices de vegetação (NDVI) e classificação de tipos de vegetação

## Método dos 4 Passos

### Ocorrência de Incêncdio
- **Grão:** Uma linha (evento) representa um incêndio
- **Dimensões:** 
    - **What:** Tipo de incêndio (florestal, agrícola, urbano)
    - **Who:** Entidade responsável pelo registo (ICNF) 
    - **When:** Data e hora de início e extinsão
    - **Where:** Numa localização específica (município, concelho, distrito, cidade, coordenadas)
- **Medidas:**
    - Área ardida (hectares) - (elementar) (aditiva)
    - Duração do incêndio (horas) - (elementar) (aditiva)
    - Número de focos iniciais - (elementar) (aditiva)
    - Severidade do incêndio - (derivada) (não-aditiva)

### Meteorologia Diária
- **Grão:** Uma linha (evento) representa as condições meteorológicas de um dia numa localização
- **Dimensões:**
    - **What:** Tipo de condição meteorológica
    - **When:** Dia, Mês e Ano (data)
    - **Where:** Estação meteorológica (não é relevante para o estudo)
- **Medidas:**
    - Temperatura média (ºC) - (elementar) (não-aditiva)
    - Temperatura máxima (ºC) - (elementar) (não aditiva)
    - Humidade relativa (%) - (elementar) (não-aditiva)
    - Velocidade do vento (km/h) - (elementar) (não-aditiva)
    - Precipitação (mm) - (elementar) (aditiva)
    - Índice de risco de incêndio (derivado) (não-aditivo)

### Operações de Combate a Incêndios
- **Grão:** Uma linha (evento) representa uma operação de combate num incêndio específico
- **Dimensões:**
    - **What:** Tipo de operação (primeira intervenção, combate prolongado, rescaldo)
    - **Who:** Entidades mobilizadas (bombeiros, proteção civil, etc...)
    - **When:** Data e hora da operação
    - **Where:** Localização da operação (município, concelho, distrito, cidade, coordenadas)
- **Medidas:**
    - Número de operacionais mobilizados - (elementar) (aditiva)
    - Número de veículos terrestres mobilizados - (elementar) (aditiva)
    - Número de meios aéreos mobilizados - (elementar) (aditiva)
    - Tempo de resposta inicial (minutos) - (elementar) (não-aditiva)
    - Taxa de expansão do incêndio (ha/hora) - (derivada) (não-aditiva)
    - Eficácia da contenção (%) - (derivada) (não-aditiva)

### Monitorização de Vegetação
- **Grão:** Uma linha (evento) representa uma medição de vegetação numa área específica
- **Dimensões:**
    - **What:** Tipo de vegetação e classificação
    - **When:** Data da medição (dia, mês, ano)
    - **Where:** Área geográfica (município, concelho, distrito, cidade, coordenadas)
- **Medidas:**
    - Índice NVDI - (elementar) (não-aditiva)
    - Densidade vegetação - (elementar) (não-aditiva)
    - Percentagem por tipo de vegetação - (derivada) (não-aditiva)
    - Índice de combustibilidade - (derivado) (não-aditivo)

## Participantes
- Diogo Pereira - 8200594
- Duarte Sampaio - 8190553
- Hugo Guimarães - 8220337
- Nuno Silva - 8180393