import pandas as pd
import glob
import os
import matplotlib.pyplot as plt
import seaborn as sns

# Criar diretório para os resultados
output_dir = "./data_proffiling/icnf/results"
os.makedirs(output_dir, exist_ok=True)

# Carregar os dados
all_files = glob.glob("./data_proffiling/icnf/data/*.csv")
df = pd.concat((pd.read_csv(f, sep='|', encoding='UTF-8', low_memory=False) for f in all_files))
print(f"Total de registos carregados: {len(df)}")

# ====== LISTA DE COLUNAS PARA PROFILING ======
colunas_alvo = [
    'id', 'DISTRITO', 'CONCELHO', 'FREGUESIA', 'DATAALERTA', 'HORAALERTA',
    'DHINICIO', 'DHFIM', 'AREATOTAL', 'AREAMATO', 'AREAPOV', 'AREAAGRIC',
    'TIPO', 'CAUSA', 'TIPOCAUSA', 'CAUSAFAMILIA', 'FALSOALARME',
    'INCENDIO', 'QUEIMADA', 'TEMPERATURA', 'HUMIDADERELATIVA', 'FFMC', 'FWI', 'LAT', 'LON'
]

# Filtrar o DataFrame para as colunas de interesse
df_profile = df[colunas_alvo]

# ====== 1. ESTRUTURA DOS DADOS ======
with open(f"{output_dir}/01_estrutura.txt", 'w', encoding='utf-8') as f:
    f.write("=== ESTRUTURA DOS DADOS ===\n")
    f.write(f"Total de registos: {len(df_profile)}\n")
    f.write(f"Total de colunas: {len(df_profile.columns)}\n")
    f.write(f"\nColunas: {list(df_profile.columns)}\n")
    f.write(f"\nTipos de dados:\n{df_profile.dtypes}\n")

print("✓ Estrutura exportada para 01_estrutura.txt")

# ====== 2. VALORES NULOS ======
nulos_pct = (df_profile.isnull().sum() / len(df_profile)) * 100
nulos_df = pd.DataFrame({
    'Coluna': nulos_pct.index,
    'Percentagem_Nulos': nulos_pct.values,
    'Total_Nulos': df_profile.isnull().sum().values,
    'Total_Registos': len(df_profile)
}).sort_values('Percentagem_Nulos', ascending=False)

nulos_df.to_csv(f"{output_dir}/02_valores_nulos.csv", index=False, encoding='utf-8')
print("✓ Valores nulos exportados para 02_valores_nulos.csv")

# ====== 2.1 UNICIDADE (IDs e duplicados gerais) ======

unicidade_dir = f"{output_dir}"

# Duplicados baseados apenas no ID
duplicados_id = df_profile[df_profile['id'].duplicated(keep=False)]

with open(f"{unicidade_dir}/02_unicidade_ids.txt", 'w', encoding='utf-8') as f:
    f.write("=== ANÁLISE DE UNICIDADE — CAMPO ID ===\n\n")
    f.write(f"Total de registos: {len(df_profile)}\n")
    f.write(f"IDs únicos: {df_profile['id'].nunique()}\n")
    f.write(f"IDs duplicados: {len(df_profile) - df_profile['id'].nunique()}\n\n")

    if len(duplicados_id) > 0:
        f.write("IDs duplicados encontrados no dataset.\n")
        f.write("Lista de primeiros 20 duplicados:\n")
        f.write(duplicados_id.head(20).to_string())
        f.write("\n")
    else:
        f.write("Nenhum ID duplicado encontrado.\n")

# Exportar duplicados completos do ID
if len(duplicados_id) > 0:
    duplicados_id.to_csv(f"{unicidade_dir}/02_unicidade_ids_duplicados.csv",
                         index=False, encoding='utf-8')

# Duplicados considerando todas as colunas
duplicados_completos = df_profile[df_profile.duplicated(keep=False)]

with open(f"{unicidade_dir}/02_unicidade_registos.txt", 'w', encoding='utf-8') as f:
    f.write("=== ANÁLISE DE DUPLICADOS — REGISTOS COMPLETOS ===\n\n")
    f.write(f"Total de registos duplicados completos: {len(duplicados_completos)}\n\n")

    if len(duplicados_completos) > 0:
        f.write("Primeiros 20 duplicados completos:\n")
        f.write(duplicados_completos.head(20).to_string())
        f.write("\n")
    else:
        f.write("Nenhum registo completamente duplicado encontrado.\n")

if len(duplicados_completos) > 0:
    duplicados_completos.to_csv(f"{unicidade_dir}/02_unicidade_registos_completos.csv",
                                index=False, encoding='utf-8')

print("✓ Unicidade verificada para IDs e registos completos.")

# ====== 3. ANÁLISE CATEGÓRICAS ======
categoricas = ['DISTRITO', 'CONCELHO', 'FREGUESIA', 'TIPO', 'CAUSA', 'TIPOCAUSA', 'CAUSAFAMILIA']

with open(f"{output_dir}/03_categoricas_resumo.txt", 'w', encoding='utf-8') as f:
    f.write("=== ANÁLISE DE COLUNAS CATEGÓRICAS ===\n\n")
    
    for col in categoricas:
        if col in df_profile.columns:
            f.write(f"\n{'='*60}\n")
            f.write(f"COLUNA: {col}\n")
            f.write(f"{'='*60}\n")
            f.write(f"Valores únicos: {df_profile[col].nunique()}\n")
            f.write(f"Valores nulos: {df_profile[col].isnull().sum()} ({(df_profile[col].isnull().sum()/len(df_profile)*100):.2f}%)\n\n")
            f.write("Top 20 valores mais frequentes:\n")
            f.write(df_profile[col].value_counts().head(20).to_string())
            f.write("\n\n")
            
            # Exportar contagem completa para CSV individual
            df_profile[col].value_counts().to_csv(
                f"{output_dir}/03_categorica_{col}.csv", 
                header=['Contagem'], 
                encoding='utf-8'
            )

print("✓ Análise categóricas exportada para 03_categoricas_*.txt e .csv")

# ====== 3.1 GRÁFICOS DE BARRAS PARA CATEGÓRICAS ======
categoricas_graficos = ['DISTRITO', 'FREGUESIA', 'TIPO', 'TIPOCAUSA']

for col in categoricas_graficos:
    if col in df_profile.columns:
        # Top 20 valores mais frequentes
        top_values = df_profile[col].value_counts().head(20)
        
        plt.figure(figsize=(12, 8))
        top_values.plot(kind='barh', color='steelblue', edgecolor='black')
        plt.title(f'Top 20 - {col}', fontsize=16, fontweight='bold', pad=20)
        plt.xlabel('Frequência', fontsize=12)
        plt.ylabel(col, fontsize=12)
        plt.grid(True, alpha=0.3, axis='x')
        plt.tight_layout()
        plt.savefig(f"{output_dir}/03_grafico_{col}.png", dpi=300, bbox_inches='tight')
        plt.close()
        
        print(f"✓ Gráfico de barras exportado para 03_grafico_{col}.png")

# ====== 4. ANÁLISE NUMÉRICAS ======
numericas = ['AREATOTAL', 'AREAMATO', 'AREAPOV', 'AREAAGRIC', 
             'TEMPERATURA', 'HUMIDADERELATIVA', 'FFMC', 'FWI', 'LAT', 'LON']

# Garantir que são numéricas
df_numericas = df_profile[numericas].apply(pd.to_numeric, errors='coerce')

# Estatísticas descritivas completas
stats = df_numericas.describe(percentiles=[.01, .05, .1, .25, .5, .75, .9, .95, .99])
stats.to_csv(f"{output_dir}/04_numericas_estatisticas.csv", encoding='utf-8')

# Informação adicional sobre numéricas
with open(f"{output_dir}/04_numericas_detalhes.txt", 'w', encoding='utf-8') as f:
    f.write("=== ANÁLISE DETALHADA DE COLUNAS NUMÉRICAS ===\n\n")
    
    for col in numericas:
        if col in df_numericas.columns:
            f.write(f"\n{'='*60}\n")
            f.write(f"COLUNA: {col}\n")
            f.write(f"{'='*60}\n")
            serie = df_numericas[col]
            f.write(f"Valores válidos: {serie.notna().sum()}\n")
            f.write(f"Valores nulos: {serie.isna().sum()}\n")
            f.write(f"Média: {serie.mean():.4f}\n")
            f.write(f"Mediana: {serie.median():.4f}\n")
            f.write(f"Desvio padrão: {serie.std():.4f}\n")
            f.write(f"Mínimo: {serie.min():.4f}\n")
            f.write(f"Máximo: {serie.max():.4f}\n")
            f.write(f"Percentil 1%: {serie.quantile(0.01):.4f}\n")
            f.write(f"Percentil 99%: {serie.quantile(0.99):.4f}\n")
            f.write("\n")

print("✓ Análise numéricas exportada para 04_numericas_*.csv e .txt")

# ====== 5. ANÁLISE DE DATAS (BONUS) ======
colunas_data = ['DATAALERTA', 'DHINICIO', 'DHFIM', 'HORAALERTA']
with open(f"{output_dir}/05_datas_analise.txt", 'w', encoding='utf-8') as f:
    f.write("=== ANÁLISE DE COLUNAS DE DATA/HORA ===\n\n")
    
    for col in colunas_data:
        if col in df_profile.columns:
            f.write(f"\n{'='*60}\n")
            f.write(f"COLUNA: {col}\n")
            f.write(f"{'='*60}\n")
            f.write(f"Valores únicos: {df_profile[col].nunique()}\n")
            f.write(f"Valores nulos: {df_profile[col].isnull().sum()}\n")
            f.write(f"\nPrimeiros 5 valores:\n{df_profile[col].head().to_string()}\n")
            f.write(f"\nÚltimos 5 valores:\n{df_profile[col].tail().to_string()}\n")
            f.write("\n")

print("✓ Análise de datas exportada para 05_datas_analise.txt")

# ====== 6. CORRELAÇÕES (CSV + IMAGEM) ======
correlacoes = df_numericas.corr()

# Criar heatmap da matriz de correlações
plt.figure(figsize=(12, 10))
sns.heatmap(
    correlacoes, 
    annot=True,           # Mostrar valores nas células
    fmt='.2f',            # Formato dos números
    cmap='coolwarm',      # Paleta de cores
    center=0,             # Centrar cores no zero
    square=True,          # Células quadradas
    linewidths=0.5,       # Linhas entre células
    cbar_kws={'shrink': 0.8}  # Tamanho da barra de cores
)
plt.title('Matriz de Correlações - Variáveis Numéricas', fontsize=16, pad=20)
plt.tight_layout()
plt.savefig(f"{output_dir}/06_correlacoes.png", dpi=300, bbox_inches='tight')
plt.close()

print("✓ Matriz de correlações exportada para 06_correlacoes.csv e 06_correlacoes.png")

# ====== 7. BOXPLOTS ======
# Boxplot individual para cada variável (com escala original)
fig, axes = plt.subplots(5, 2, figsize=(14, 18))
axes = axes.flatten()

for idx, col in enumerate(numericas):
    if col in df_numericas.columns:
        ax = axes[idx]
        df_numericas[col].dropna().plot(kind='box', ax=ax, vert=False)
        ax.set_title(f'{col}', fontsize=12, fontweight='bold')
        ax.set_xlabel('Valor')
        ax.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig(f"{output_dir}/07_boxplots_individuais.png", dpi=300, bbox_inches='tight')
plt.close()

print("✓ Boxplots individuais exportados para 07_boxplots_individuais.png")

# Boxplot comparativo (dados normalizados para melhor visualização)
from sklearn.preprocessing import StandardScaler

df_scaled = pd.DataFrame(
    StandardScaler().fit_transform(df_numericas.dropna()),
    columns=df_numericas.columns
)

plt.figure(figsize=(14, 8))
df_scaled.boxplot(rot=45, figsize=(14, 8))
plt.title('Boxplots Comparativos - Variáveis Normalizadas', fontsize=16, pad=20)
plt.ylabel('Valores Normalizados (Z-score)')
plt.xlabel('Variáveis')
plt.grid(True, alpha=0.3, axis='y')
plt.tight_layout()
plt.savefig(f"{output_dir}/07_boxplots_comparativo.png", dpi=300, bbox_inches='tight')
plt.close()

print("✓ Boxplot comparativo exportado para 07_boxplots_comparativo.png")

# Estatísticas sobre outliers
with open(f"{output_dir}/07_outliers_analise.txt", 'w', encoding='utf-8') as f:
    f.write("=== ANÁLISE DE OUTLIERS (Método IQR) ===\n\n")
    
    for col in numericas:
        if col in df_numericas.columns:
            serie = df_numericas[col].dropna()
            Q1 = serie.quantile(0.25)
            Q3 = serie.quantile(0.75)
            IQR = Q3 - Q1
            limite_inferior = Q1 - 1.5 * IQR
            limite_superior = Q3 + 1.5 * IQR
            
            outliers = serie[(serie < limite_inferior) | (serie > limite_superior)]
            pct_outliers = (len(outliers) / len(serie)) * 100
            
            f.write(f"\n{'='*60}\n")
            f.write(f"COLUNA: {col}\n")
            f.write(f"{'='*60}\n")
            f.write(f"Q1 (25%): {Q1:.4f}\n")
            f.write(f"Q3 (75%): {Q3:.4f}\n")
            f.write(f"IQR: {IQR:.4f}\n")
            f.write(f"Limite inferior: {limite_inferior:.4f}\n")
            f.write(f"Limite superior: {limite_superior:.4f}\n")
            f.write(f"Número de outliers: {len(outliers)} ({pct_outliers:.2f}%)\n")
            if len(outliers) > 0:
                f.write(f"Outliers mínimo: {outliers.min():.4f}\n")
                f.write(f"Outliers máximo: {outliers.max():.4f}\n")
            f.write("\n")

print("✓ Análise de outliers exportada para 07_outliers_analise.txt")

# ====== 8. RESUMO GERAL ======
with open(f"{output_dir}/00_resumo_geral.txt", 'w', encoding='utf-8') as f:
    f.write("=== RESUMO GERAL DO PROFILING ===\n\n")
    f.write(f"Data de execução: {pd.Timestamp.now()}\n")
    f.write(f"Total de registos: {len(df_profile)}\n")
    f.write(f"Total de colunas analisadas: {len(colunas_alvo)}\n\n")
    f.write("Ficheiros gerados:\n")
    f.write("  - 01_estrutura.txt: Informação sobre estrutura dos dados\n")
    f.write("  - 02_valores_nulos.csv: Percentagem de nulos por coluna\n")
    f.write("  - 03_categoricas_*.txt/.csv: Análise de variáveis categóricas\n")
    f.write("  - 04_numericas_*.csv/.txt: Estatísticas de variáveis numéricas\n")
    f.write("  - 05_datas_analise.txt: Análise de colunas de data/hora\n")
    f.write("  - 06_correlacoes.csv/.png: Matriz de correlações (CSV e imagem)\n")

print("✓ Resumo geral exportado para 00_resumo_geral.txt")

print(f"\n{'='*60}")
print("✓✓✓ PROFILING COMPLETO! ✓✓✓")
print(f"Todos os resultados foram exportados para: {output_dir}/")
print(f"{'='*60}")