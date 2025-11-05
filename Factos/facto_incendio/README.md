
# ocorrencia_incendio.dbml — README

**Resumo**  
Este DBML modela a *fact table* e dimensões relevantes para a análise de **ocorrências de incêndio** (registos do ICNF e derivados). Destina-se a responder questões sobre quando, onde e como os incêndios ocorrem, bem como estatísticas básicas de severidade (área, duração) e causas.

---

## Perguntas que este modelo responde (exemplos)
- Quantos incêndios ocorreram por ano / estação / concelho?  
- Qual a distribuição de área ardida (média, mediana, percentis) por município?  
- Quais as causas mais frequentes e como evoluem ao longo do tempo?  
- Qual a duração média dos incêndios por tipo (florestal vs agrícola)?  
- Existem picos de ocorrência concentrados em dias/semanas específicos?

---

## Datasets de origem (principais)
- **ICNF — perimeters & occurrence records** (polígonos, `fire_id`, datas, áreas, causas).  
- **Base administrativa (NUTS/municípios)** — para agregação por território.  
- **CORINE Land Cover** — (opcional) para caracterizar uso do solo associada a cada perímetro.  

> Nota: o ficheiro DBML descreve o modelo; os ficheiros brutos (GeoJSON / GPKG / CSV) devem estar em `data/` com licenças e origem documentadas.

---

## Grain (granularidade)
- `fact_fire` (ocorrencia): 1 linha = 1 incêndio (agregado por `fire_id`).  
- Dimensões típicas: `dim_fire` (metadata ICNF), `dim_time`, `dim_location`, `dim_cause`, `dim_fire_type`, `dim_landcover` (quando usado).

---

## Principais dimensões e medidas
- **Dimensões**: `dim_fire`, `dim_time`, `dim_location`, `dim_cause`, `dim_fire_type`.  
- **Medidas (fact)**: `area_total_m2`, `duration_hours`, `perimeter_m`, `is_severe` (se definido), `processing_date`.

---

