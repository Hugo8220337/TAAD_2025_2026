
# influencia_vegetacao.dbml — README

**Resumo**  
Este ficheiro DBML modela o *star schema* para analisar a influência da vegetação (NDVI e proxies) nos incêndios. O grão principal é **fire × time-window** (ex.: `pre_90`, `pre_30`, `post_90`). O objetivo é suportar análises que relacionem índices de vegetação com ocorrência, severidade e evolução dos incêndios.

---

## Perguntas que este facto responde (exemplos)
- Qual a correlação entre NDVI pré-incêndio e a ocorrência de incêndio (probabilidade / frequência)?  
- Qual o NDVI médio pré-incêndio em áreas ardidas vs. áreas de controlo (mesma classe CORINE)?  
- Como evolui o NDVI alinhado pela data do incêndio (`t0`) — recuperação ou perda de vegetação ao longo do tempo?  
- Que percentagem da área ardida tinha NDVI elevado antes do fogo (testar vários thresholds)?  
- Quais tipos/classes de uso do solo (CORINE) apresentam maior fração de área com NDVI alto antes de incêndios?  
- Há relação entre NDVI pré-incêndio e métricas de severidade (área ardida, duração)?

---

## Datasets usados (nomes & notas)
- **ICNF — fire perimeters / metadata** (fire polygons, `fire_id`, `t0`, area reported).  
- **MODIS MOD13Q1** (NDVI, 250 m, 16-dias) — principal fonte temporal nacional para séries longas.  
- **CORINE Land Cover** — classes de uso do solo para comparações/controlos.  
- **(Opcional) Meteorological summaries** Open-Meteo — usados como agregados por incêndio.

> Observação: as localizações exatas dos ficheiros (GPKG / GeoJSON / assets GEE) devem constar noutras pastas do repositório; o DBML descreve a modelação, não os ficheiros brutos.

---

## Grain (granularidade)
- `fact_fire_ndvi`: 1 linha = `fire_id` × `window` (ex.: `pre_90`, `pre_30`, `post_90`).  
- `fact_fire`: 1 linha = `fire_id` (agregado por incêndio).  
- `fact_fire_meteorology`: medições por `fire_id` × `date` × `location` (time-series).

---

## Principais dimensões e medidas (resumo)
- **Dimensions**: `dim_fire`, `dim_time`, `dim_location`, `dim_landcover`, `dim_sensor`, `dim_source`, `dim_cause`, `dim_species`, `dim_fire_type`.  
- **Key measures in the vegetation fact**: `ndvi_pre_mean`, `pct_area_ndvi_gt_thr`, `veg_density_mean`, `area_total_m2`, `mean_temp`, `precip_sum`.

---

