import json
import os
from model import *


def analyze_title(title: str):
    prompt = f"""
    Analisa o seguinte título de notícia e devolve um objeto JSON com:
    - keywords: lista de 3 a 6 palavras-chave
    - entities: entidades nomeadas (pessoas, locais, organizações)
    - sentiment: tom geral (positivo, negativo, neutro)
    - risk_score: número entre 0 e 10 representando a urgência (10 - Emergencia/Alto risco e 1 - Seguro/Sem Risco)

    Título: "{title}"

    Responde apenas em JSON, sem texto adicional.
    """
    return model_generate(prompt, stream=False)


def news_analysis():
    input_path = "dataset.json"
    output_path = "output_partial.json"
    final_path = "output.json"

    # Load full dataset
    with open(input_path, "r", encoding="utf-8") as f:
        noticias = json.load(f)

    processed = []
    if os.path.exists(output_path):
        with open(output_path, "r", encoding="utf-8") as f:
            try:
                processed = json.load(f)
            except json.JSONDecodeError:
                processed = []

    processed_links = {n["link"] for n in processed if "link" in n}
    total = len(noticias)
    processed_count = len(processed)

    for i, noticia in enumerate(noticias, start=1):
        if noticia.get("link") in processed_links:
            continue

        titulo = noticia["titulo"]
        print(f"🔍 ({i}/{total}) Analisando: {titulo}")

        try:
            resposta = analyze_title(titulo)
            dados = json.loads(resposta)
            noticia.update(dados)
            processed.append(noticia)

            # incremental save
            with open(output_path, "w", encoding="utf-8") as f:
                json.dump(processed, f, indent=2, ensure_ascii=False)

        except Exception as e:
            print(f"⚠️ Erro em '{titulo}': {e}")
            # optional: save current progress even on error
            exit()

    os.rename(output_path, final_path)
    print(f"🎉 Análise completa! Resultado salvo em {final_path}")





if __name__ == "__main__":
    news_analysis()
