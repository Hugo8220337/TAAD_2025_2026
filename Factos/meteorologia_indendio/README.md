
# meteorologia_incendio.dbml — README

**Resumo**  
Este ficheiro DBML descreve o esquema dimensional usado para armazenar medições meteorológicas relacionadas com incêndios. Inclui duas abordagens: (1) uma *fact* de medições por `fire × date × location` (tempo-série) e (2) uma *dimensão/summary* agregada por incêndio (validação / resumo). O modelo suporta análises de evolução temporal, agregados por incêndio e correlações entre variáveis meteorológicas e severidade dos fogos.

---

## Perguntas que este dataset responde
- “Como evoluiu a temperatura durante o incêndio?”  
- “Qual o número médio de dias secos por incêndio?”  
- “Como se comportam as variáveis meteorológicas ao longo do tempo?”  
- “Que padrões meteorológicos antecedem incêndios de grande área?”  
- “Existe correlação entre rajadas máximas de vento e duração/área dos incêndios?”  
- “Como variam precipitação e temperatura por concelho/ano durante a época de incêndios?”

---

## Datasets de origem 
- **Open-Meteo API** — dados horários/diários de temperatura, humidade relativa, precipitação, vento.  
- **Copernicus** — reanálises para preencher lacunas ou obter dados de pressão/evapotranspiração.  
- **ICNF (fire perimeters)** — para mapear janelas temporais do incêndio (`t0`) e associar medições por proximidade/área.  

---

## Grain (granularidade)
- `fact_fire_meteorology`: 1 linha = (fire_id, observation_date, location) — medições temporais vinculadas ao fogo.  
- `dim_meteorology` (summary): 1 linha = 1 fire_id — agregados por incêndio (médias, somas, contagens de dias com evento).

---

## Principais dimensões / medidas
- **Dimensões**: `dim_fire`, `dim_time`, `dim_location`.  
- **Medidas (fact_fire_meteorology)**: `temp_max`, `temp_min`, `rh_max`, `rh_min`, `precip_sum`, `wind_max`, `gust_max`, `radiation`, `et0`, `precip_hours`.  
- **Medidas agregadas (dim_meteorology / summary)**: `mean_temp_max`, `mean_temp_min`, `precip_sum_mean`, `dry_day_sum`, `high_wind_sum`, `et0_mean`.

---

