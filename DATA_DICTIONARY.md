# Dicionário de Dados — Ficheiros de Alertas (data/*.csv)

Este documento descreve cada atributo presente nos ficheiros pipe-separated em `data/` (ex.: `2001.csv`). Inclui: descrição, tipo provável, exemplos, e notas de parsing/qualidade. Também inclui um snippet Python para carregar os CSVs de forma robusta.

> Assunções importantes

# Dicionário de Dados — Ficheiros de Alertas (data/*.csv)

Este documento descreve os atributos presentes nos ficheiros `data/*.csv` (separador `|`). A versão reformatada organiza os campos por secções e apresenta uma tabela legível com: Campo | Descrição | Tipo | Exemplo | Notas.

> Assunções rápidas

- Separador: `|`  
- Datas: podem usar `DD/MM/YYYY` ou ISO (usar `dayfirst=True` quando apropriado)  
- Vírgula decimal: alguns campos podem usar `,` — o loader tenta detetar e corrigir  
- Coordenadas: preferir `LAT`/`LON` para mapeamento; `X`/`Y` provavelmente em sistema projetado (verificar EPSG)

---

## Identificação e localização

| Campo | Descrição | Tipo | Exemplo | Notas |
|---|---|---:|---|---|
| `id` | Identificador único do registo | string/integer | `12345` | Manter como string se houver zeros à esquerda |
| `DISTRITO` | Distrito administrativo | string | `Braga` | Padronizar capitalização |
| `CONCELHO` | Município | string | `Porto` | |
| `FREGUESIA` | Freguesia | string | `Bonfim` | |
| `LOCAL` | Descrição textual do local | string | `Pinhal perto de X` | Campo livre |
| `INE` | Código INE do município | string/integer | `0101` | Útil para junções com dados oficiais |

---

## Tempo / eventos

| Campo | Descrição | Tipo | Exemplo | Notas |
|---|---|---:|---|---|
| `DATAALERTA` | Data do alerta | date | `15/07/2001` | Use `dayfirst=True` se DD/MM/YYYY |
| `HORAALERTA` | Hora do alerta | time | `13:45` | |
| `DIA`, `MES`, `HORA` | Componentes separados (dia/mes/hora) | integer | `15`, `7`, `13` | Podem duplicar `DATAALERTA`/`HORAALERTA` |
| `DHINICIO`, `DHFIM` | Data/hora início e fim (combinados) | datetime | `15/07/2001 13:45` | Preferir se presentes |
| `DATAEXTINCAO`, `HORAEXTINCAO` | Data/hora de extinção | date/time | `16/07/2001`, `09:00` | |
| `DATA1INTERVENCAO`, `HORA1INTERVENCAO` | 1ª intervenção registada | date/time | `15/07/2001`, `14:05` | |
| `DURACAO` | Duração do evento (horas ou HH:MM) | numérico/string | `2.5` ou `02:30` | Confirmar unidade no ficheiro |

---

## Áreas e perímetros

| Campo | Descrição | Tipo | Exemplo | Notas |
|---|---|---:|---|---|
| `AREAPOV` | Área de zona povoada afetada | numérico (ha ou m²) | `0.5` | Verificar unidades por ordem de grandeza |
| `AREAMATO` | Área de mato/vegetação afetada | numérico (ha ou m²) | `12.3` | |
| `AREAAGRIC` | Área agrícola afetada | numérico (ha ou m²) | `2.4` | |
| `AREATOTAL` | Área total afetada | numérico (ha ou m²) | `15.2` | Pode corresponder à soma dos componentes |
| `PERIMETRO` | Perímetro (m) ou referência a geometria | numérico/string | `4500` ou `perimetro_123.shp` | Inspecionar tipo nos ficheiros |
| `AREAMANCHAMODFARSITE` | Área prevista pelo FARSITE | numérico (ha ou m²) | `10.5` | Modelo FARSITE |

---

## Flags / classificações rápidas

| Campo | Descrição | Tipo | Exemplo | Notas |
|---|---|---:|---|---|
| `TIPO` | Tipo de incidente (INCENDIO, QUEIMADA...) | string/categórico | `INCENDIO` | |
| `QUEIMADA` | Indica queimada controlada | boolean/categórico | `SIM`/`NAO` | Pode aparecer também como `QUEIMA` |
| `QUEIMA` | Flag semelhante a `QUEIMADA` | boolean | `SIM`/`NAO` | Comparar valores entre colunas |
| `FALSOALARME` | Alerta falso | boolean | `0`/`1` ou `SIM`/`NAO` | |
| `FOGACHO` | Indica fogacho/pequena queima | boolean | `SIM`/`NAO` | Termo local — verificar significado |
| `INCENDIO` | Indica ocorrência de incêndio | boolean | `SIM`/`NAO` | |
| `AGRICOLA` | Impacto/origem agrícola | boolean | `SIM`/`NAO` | |

---

## Causa e códigos operacionais

| Campo | Descrição | Tipo | Exemplo | Notas |
|---|---|---:|---|---|
| `CAUSA` | Causa descritiva (texto livre) | string | `Descarga elétrica` | |
| `TIPOCAUSA` | Classificação da causa | string/categórico | `ACIDENTAL` | Ex.: Natural / Humano / Criminoso |
| `CAUSAFAMILIA` | Família de causa (agrupamento) | string/categórico | `HUMANA` | |
| `NCCO` | Código do centro de coordenação (NCCO) | string/integer | `001` | |
| `NOMECCO` | Nome do centro de coordenação | string | `Centro Norte` | |
| `OPERADOR` | Operador que atendeu/gestor do alerta | string | `Operador X` | |
| `APS` | Ambíguo — possivelmente número de apoios/recursos | integer/string | `2` | Confirmar com documentação |

---

## Meteorologia e índices de perigo

| Campo | Descrição | Tipo | Exemplo | Notas |
|---|---|---:|---|---|
| `TEMPERATURA` | Temperatura (°C) | float | `30.2` | Cuidado com vírgula decimal |
| `HUMIDADERELATIVA` | Humidade relativa (%) | float | `30` | |
| `VENTOINTENSIDADE` | Velocidade do vento (m/s ou km/h) | float | `5` ou `50` | Inferir unidade pela ordem de grandeza |
| `VENTOINTENSIDADE_VETOR` | Velocidade vetorial do vento | float | `6.1` | |
| `VENTODIRECAO_VETOR` | Direção do vento (graus 0–360) | float | `180` | |
| `PRECEPITACAO` | Precipitação (mm) | float | `0.0` | |
| `FFMC`, `DMC`, `DC`, `ISI`, `BUI`, `FWI` | Componentes do sistema FWI (Canadian Fire Weather Index) | float | `85.3`, `10.2`, ... | Usados para avaliação de perigo |
| `DSR` | Daily Severity Rating | float | `3.4` | Derivado do FWI |
| `THC` | Ambíguo — possivelmente Total Heat Content | float/string | `...` | Confirmar no fornecedor |

---

## Coordenadas e topografia

| Campo | Descrição | Tipo | Exemplo | Notas |
|---|---|---:|---|---|
| `LAT`, `LON` | Latitude / Longitude (graus decimais, WGS84 esperado) | float | `41.1579`, `-8.6291` | Preferir para mapas |
| `X`, `Y` | Coordenadas projetadas (grid nacional) | float | `694345.12`, `414325.05` | Verificar EPSG antes de reprojetar |
| `ALTITUDEMEDIA` | Altitude média (m) | float | `350` | |
| `DECLIVEMEDIO` | Declive médio (° ou %) | float | `12` | Confirmar unidade |

---

## Modelos, ficheiros GIS e meta-ficheiros

| Campo | Descrição | Tipo | Exemplo | Notas |
|---|---|---:|---|---|
| `MODFARSITE` | Saída/flag do modelo FARSITE | string/numérico | `model_1` | FARSITE = modelo de propagação de incêndio |
| `AREASFICHEIROS_GNR`, `AREASFICHEIROS_GTF` | Área segundo ficheiros exportados (agências) | numérico/string | `...` | Podem ser áreas ou nomes de ficheiro |
| `FICHEIROIMAGEM_GNR` | Nome do ficheiro imagem gerado para GNR | string | `img_123.png` | |
| `AREASFICHEIROSHP_GTF`, `AREASFICHEIROSHPXML_GTF`, `AREASFICHEIRODBF_GTF`, `AREASFICHEIROPRJ_GTF`, `AREASFICHEIROSBN_GTF`, `AREASFICHEIROSBX_GTF`, `AREASFICHEIROSHX_GTF` | Campos relacionados a exportações GIS (SHP/DBF/PRJ/SHX...) | string/numérico | `...` | Verificar se são caminhos ou áreas |
| `AREASFICHEIROZIP_SAA` | ZIP gerado para o sistema SAA | string | `saa_2001.zip` | |

---

## Notas de parsing e qualidade de dados

- Leitura: usar `sep='|'` com `pandas.read_csv`.  
- Encoding: tentar `utf-8` e fallback para `latin-1` (ISO-8859-1).  
- Decimal: se aparecerem vírgulas decimais, usar `decimal=','` ou pré-processar substituindo `,` por `.` em campos numéricos.  
- Missing values: tokens comuns `"", "NA", "NULL", "-"` — passar em `na_values`.  
- Datas: preferir campos `DHINICIO`/`DHFIM` combinados; caso não existam, juntar `DATAALERTA` + `HORAALERTA`. Usa `dayfirst=True` para formatos `DD/MM/YYYY`. 
- Coordenadas: use `LAT`/`LON` para mapear; para `X`,`Y` detecte CRS e reprojete com `pyproj`/`geopandas` se necessário. 
- Unidades: deduzir por ordem de grandeza (ex.: áreas muito grandes → m²; valores tipicamente 0–1000 → hectares). Confirme com o fornecedor quando possível.

---

## Snippet Python (loader)
