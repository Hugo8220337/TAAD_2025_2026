import feedparser, json, os, calendar
from datetime import datetime
from urllib.parse import quote_plus


queries = ["incêndios", "mudanças climáticas", "seca", "proteção civil"]

ano_inicio = 2020
mes_inicio = 1

ano_fim = datetime.today().year
mes_fim = datetime.today().month

base_dir = "Files"
os.makedirs(base_dir, exist_ok=True)

meses_pt = [
    "janeiro", "fevereiro", "março", "abril", "maio", "junho",
    "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"
]

def get_rss_url(termo, data_inicio, data_fim, extra_params=None):
    query = f"{termo} after:{data_inicio} before:{data_fim}"
    params = {
        "q": query,
        "hl": "pt-PT",
        "gl": "PT",
        "ceid": "PT:pt",
        "location": "Portugal"
    }
    if extra_params:
        params.update(extra_params)
    url = "https://news.google.com/rss/search?" + "&".join(f"{k}={quote_plus(str(v))}" for k, v in params.items())
    return url


ano = ano_inicio
mes = mes_inicio


for termo in queries:
    pasta_termo = os.path.join(base_dir, termo.replace(" ", "_"))
    os.makedirs(pasta_termo, exist_ok=True)
    ano = ano_inicio
    mes = mes_inicio
    while (ano < ano_fim) or (ano == ano_fim and mes <= mes_fim):
        primeiro_dia = datetime(ano, mes, 1)
        ultimo_dia = datetime(ano, mes, calendar.monthrange(ano, mes)[1])
        data_inicio_str = primeiro_dia.strftime("%Y-%m-%d")
        data_fim_str = ultimo_dia.strftime("%Y-%m-%d")
        rss_url = get_rss_url(termo, data_inicio_str, data_fim_str)
        feed = feedparser.parse(rss_url)
        noticias = []
        for entry in feed.entries:
            noticias.append({
                "titulo": entry.title,
                "link": entry.link,
                "data_publicacao": entry.published,
                "fonte": entry.source.title if "source" in entry else None
            })
        pasta_ano = os.path.join(pasta_termo, str(ano))
        os.makedirs(pasta_ano, exist_ok=True)
        nome_ficheiro = f"{meses_pt[mes-1]}{ano}.json"
        caminho_completo = os.path.join(pasta_ano, nome_ficheiro)
        with open(caminho_completo, "w", encoding="utf-8") as f:
            json.dump(noticias, f, ensure_ascii=False, indent=4)
        print(f"{termo} | {ano} | {meses_pt[mes-1]}: {len(noticias)} notícias guardadas")
        if mes == 12:
            mes = 1
            ano += 1
        else:
            mes += 1