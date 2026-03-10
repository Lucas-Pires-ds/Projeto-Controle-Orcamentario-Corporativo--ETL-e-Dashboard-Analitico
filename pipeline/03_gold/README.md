# Camada Gold — Métricas Analíticas

## Responsabilidade

A camada Gold é responsável por **preparar dados para consumo analítico**, criando views especializadas com métricas pré-calculadas e prontas para uso no Power BI.

**Objetivo**: Reduzir lógica no BI e entregar bases otimizadas para análise de negócio.

---

## 🎯 Características

- 4 views independentes com responsabilidades bem definidas
- Métricas avançadas pré-calculadas (YTD, MoM, YoY, MTD)
- Proteção contra erros comuns (divisão por zero, nulos)
- Flags de anomalias e valores atípicos
- Referências históricas para análise MTD
- Cruzamento Orçado vs Realizado realizado no Power BI

---

## 📂 Estrutura de Arquivos
```
gold/
├── README.md (este arquivo)
└── sql/
    └── 07_Views_golds.sql
```

---

## 📊 Views Implementadas

### 🎯 vw_gold_orcamento

**Propósito**: Consolidação mensal do orçamento com métricas agregadas

**Granularidade**: Mensal por centro de custo e categoria

**Campos principais**:
- Dimensões: Ano, Mês, Centro de custo, Categoria
- **Data_de_orcamento** (último dia do mês via `EOMONTH` - para relacionamento no BI)
- Valor orçado mensal
- Orçado YTD (acumulado no ano)
- Peso relativo por centro de custo
- Peso relativo por categoria
- Média mensal histórica
- Flag de valor atípico
- Status do dado (confiável ou suspeito)

**Exemplo de uso**:
```sql
SELECT 
    Ano, Mes,
    Centro_de_custo,
    Categoria,
    Orcado_mensal,
    Orcado_YTD,
    Peso_centro_custo,
    Flag_valor_atipico_orcamento
FROM vw_gold_orcamento
WHERE Ano = 2024 AND Status_dado = 'Dado confiavel'
ORDER BY Orcado_mensal DESC
```

---

### 📈 vw_gold_realizado

**Propósito**: Consolidação mensal do realizado com métricas avançadas de análise temporal

**Granularidade**: Mensal por centro de custo e categoria

**Campos principais**:
- Dimensões: Ano, Mês, Centro de custo, Categoria
- **Data_realizacao** (último dia do mês via `EOMONTH` - para relacionamento no BI)
- Valor realizado mensal
- Realizado YTD (acumulado no ano)
- MoM absoluto e percentual (Month over Month)
- YoY absoluto e percentual (Year over Year)
- Média mensal histórica
- Peso relativo por centro de custo
- Peso relativo por categoria
- Flag de valor atípico
- Flag de centro de custo coringa

**Decisão técnica crítica**: 

Uso da `dim_calendario` como base temporal via `RIGHT JOIN`:
```sql
FROM BASE B  
RIGHT JOIN (
    SELECT DISTINCT ano, mes FROM dim_calendario
) CAL ON B.Ano = CAL.ano AND B.Mes = CAL.mes
```

**Justificativa**: Garante continuidade temporal mesmo em meses sem lançamentos. Sem isso, `LAG()` poderia comparar meses não consecutivos, corrompendo cálculos de MoM e YoY.

**Exemplo de uso**:
```sql
SELECT 
    Ano_mes,
    Centro_de_custo,
    Categoria,
    Realizado,
    [Realizado YTD],
    MoM_abs,
    MoM_perc,
    YoY_perc,
    Flag_valor_atipico_realizado
FROM vw_gold_realizado
WHERE Ano = 2024
  AND Flag_centro_custo_coringa = 'Nao'
ORDER BY Realizado DESC
```

---

### 📄 vw_gold_lancamentos

**Propósito**: Base transacional agregada diariamente, pronta para somatórios e visualizações no Power BI

**Granularidade**: **Diária** por centro de custo, categoria, fornecedor e campanha

**Decisão arquitetural crítica:**

A view anterior (`vw_gold_lancamentos`) foi **dividida em duas views especializadas**:

1. **`vw_gold_lancamentos`** → Agregação diária para análise de gastos realizados
2. **`vw_gold_referencia_mtd`** → Referências históricas para comparação MTD

**Motivação da separação:**

A versão original misturava duas responsabilidades incompatíveis:
- Valores somáveis para análise de totais (necessário para gráficos e KPIs)
- Benchmarks históricos calculados por mediana (não somáveis)

**Problema identificado:**

Quando a view única era consumida no Power BI, as **medianas históricas eram somadas incorretamente** ao agregar múltiplos centros de custo ou categorias, gerando valores distorcidos.

**Solução:**

Separar as views permite que cada uma tenha **a granularidade correta para seu propósito**:
- `vw_gold_lancamentos` → valores agregados somáveis
- `vw_gold_referencia_mtd` → benchmarks não somáveis, usados apenas para referência visual

---

**Campos principais** (`vw_gold_lancamentos`):
- Dimensões: Ano, Mês, Dia, Data do lançamento
- Centro de custo, Categoria, Fornecedor, Campanha (IDs e nomes)
- **Total_do_dia**: Soma dos lançamentos do dia (agregado)
- **Gasto_MTD**: Acumulado mensal até a data
- Status de pagamento
- Flag de centro de custo coringa

**Características técnicas:**
- Agregação diária através da CTE `FACT_DIARIA`
- Enriquecimento dimensional completo via LEFT JOINs
- Cálculo de MTD via window function ordenada por data
- Proteção contra divisão por zero (`NULLIF`)
- **Granularidade ideal para somatórios no Power BI**

**Estrutura SQL simplificada:**
```sql
WITH FACT_DIARIA AS (
    SELECT
        data_lancamento,
        id_centro_custo,
        id_categoria,
        id_fornecedor,
        id_campanha,
        SUM(valor) AS 'total_do_dia'
    FROM fact_lancamentos
    GROUP BY 
        data_lancamento,
        id_centro_custo,
        id_categoria,
        id_fornecedor,
        id_campanha
)
SELECT
    YEAR(data_lancamento) AS 'Ano',
    MONTH(data_lancamento) AS 'Mes',
    DAY(data_lancamento) AS 'Dia',
    data_lancamento,
    -- Dimensões enriquecidas
    CC.id_cc AS 'id_centro_de_custo',
    CC.nome_cc AS 'centro_de_custo',
    -- ... outras dimensões
    total_do_dia,
    SUM(total_do_dia) OVER(...) AS 'gasto_MTD'
FROM FACT_DIARIA FD
LEFT JOIN dim_centro_custo CC ON ...
```

**Exemplo de uso**:
```sql
SELECT 
    Data_lancamento,
    Centro_de_custo,
    Categoria,
    Total_do_dia,
    Gasto_MTD
FROM vw_gold_lancamentos
WHERE Ano = 2024 AND Mes = 11
ORDER BY Data_lancamento DESC
```

**Uso no Power BI:**
```dax
Total Realizado MTD = SUM(vw_gold_lancamentos[Gasto_MTD])
Total Gasto Diário = SUM(vw_gold_lancamentos[Total_do_dia])
```

---

### 📊 vw_gold_referencia_mtd

**Propósito**: Fornecer referências históricas de comportamento de gastos para análise comparativa MTD

**Granularidade**: **Dia do mês** por centro de custo e categoria

**Motivação da criação:**

Esta view foi separada da `vw_gold_lancamentos` para resolver um problema fundamental:

> **Métricas estatísticas de referência (mediana) não podem ser somadas.**

No Power BI, ao filtrar múltiplos centros de custo ou categorias, a engine tentava somar as medianas históricas, resultando em valores sem significado estatístico.

**Solução arquitetural:**

Criar uma view dedicada onde:
- Cada linha representa **um dia do mês** (1 a 31)
- Métricas são calculadas **apenas para referência visual**
- **Não deve ser usada em somatórios ou agregações no BI**
- Relacionamento com outras tabelas é **apenas para filtros contextuais**

---

**Campos principais**:
- **dia**: Dia do mês (1 a 31)
- **id_centro_custo**: Identificador do centro de custo
- **id_categoria**: Identificador da categoria
- **peso_do_dia**: Percentual acumulado esperado até este dia (mediana histórica)
- **valor_mediano_dia**: Valor mediano de gasto MTD até este dia (mediana histórica em R$)

**Lógica de construção:**

A view implementa o processo descrito no relatório técnico MTD:

1. **Agregação diária** (CTE `FACT_DIARIA`)
2. **Calendário completo** com CROSS JOIN (CTE `BASE_CALENDARIO`)
3. **Cálculo de métricas mensais** (CTE `METRICAS`):
   - `gasto_MTD`: Acumulado até cada dia
   - `total_do_mes`: Total do mês completo
4. **Normalização** (CTE `FINAL`):
   - `perc_gasto_mes = gasto_MTD / total_do_mes`
   - Aplicação do **corte histórico** (`WHERE data_lancamento < '2024-11-01'`)
5. **Cálculo das medianas** (SELECT final):
   - Mediana do percentual acumulado → `peso_do_dia`
   - Mediana do valor MTD → `valor_mediano_dia`

**Estrutura SQL simplificada:**
```sql
WITH FACT_DIARIA AS (
    -- Agregação diária
),
LISTA_CC_CAT AS (
    -- Lista de combinações CC + CAT
),
BASE_CALENDARIO AS (
    -- Calendário completo via CROSS JOIN
),
HISTORICO AS (
    -- Join calendário + fatos
),
METRICAS AS (
    -- Cálculo de MTD e total_do_mes
),
FINAL AS (
    -- Normalização percentual + corte histórico
    SELECT *,
        gasto_MTD / NULLIF(total_do_mes,0) AS 'perc_gasto_mes'
    FROM METRICAS
    WHERE data_lancamento < DATEFROMPARTS(2024, 11, 1)
)
SELECT DISTINCT
    dia,
    id_centro_custo,
    id_categoria,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY perc_gasto_mes) 
        OVER(PARTITION BY dia, id_centro_custo, id_categoria) AS 'peso_do_dia',
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gasto_MTD) 
        OVER(PARTITION BY dia, id_centro_custo, id_categoria) AS 'valor_mediano_dia'
FROM FINAL
```

**Decisões estatísticas:**

- **Uso de mediana (PERCENTILE_CONT 0.5)**: Robusta contra outliers de valor absoluto
- **Normalização prévia**: Elimina impacto de meses grandes vs pequenos
- **Corte histórico aplicado após métricas**: Evita inflação artificial de zeros

**Exemplo de uso** (apenas para referência visual):
```sql
SELECT 
    dia,
    Centro_de_custo,
    Categoria,
    peso_do_dia,
    valor_mediano_dia
FROM vw_gold_referencia_mtd
WHERE id_centro_custo = 5 
  AND id_categoria = 10
ORDER BY dia
```

**Uso no Power BI** (medida DAX):
```dax
Orçado Ideal MTD = 
VAR DiaAtual = DAY(MAX(dim_calendario[data]))
VAR PesoHistorico = 
    CALCULATE(
        MAX(vw_gold_referencia_mtd[peso_do_dia]),
        vw_gold_referencia_mtd[dia] = DiaAtual
    )
VAR OrcamentoMensal = SUM(vw_gold_orcamento[Orcado_mensal])
RETURN OrcamentoMensal * PesoHistorico
```

**IMPORTANTE — Restrições de uso:**

❌ **NÃO usar** `SUM(vw_gold_referencia_mtd[valor_mediano_dia])` — sem significado estatístico  
❌ **NÃO usar** para cálculos de totais ou agregações  
✅ **Usar** apenas para linhas de referência em gráficos  
✅ **Usar** para cálculo de orçado ideal via contexto de filtro

---

## 🎯 Decisões de Arquitetura

### Separação em 4 Views Independentes

A camada Gold foi dividida em views especializadas (Orçamento, Realizado, Lançamentos e Referência MTD) ao invés de uma view consolidada.

**Justificativa**:

- Cada view tem responsabilidade única e clara
- Evita redundância de dados pré-calculados
- Facilita manutenção (mudanças em uma view não afetam outras)
- Permite consumo flexível no Power BI (analista decide como cruzar)
- **Separação de métricas somáveis vs não-somáveis**

**Custo aceito**: Power BI precisa relacionar as views. Esse custo é baixo e compensa pela clareza organizacional e correção técnica.

### Cruzamento Orçado vs Realizado no Power BI

O cruzamento entre orçamento e realizado não é feito na camada Gold.

**Justificativa**:

- Diferentes análises podem requerer cruzamentos diferentes
- Evita criar dados pré-agregados que podem não ser usados
- Mantém separação de responsabilidades (SQL prepara, BI analisa)
- Regras de cruzamento podem mudar sem reprocessar dados

**Implementação no Power BI**: Relacionamentos entre tabelas via campos de granularidade comum (Ano, Mês, Centro de custo, Categoria).

### Separação de Lançamentos em Duas Views

**Decisão crítica**: Separar valores transacionais (somáveis) de benchmarks estatísticos (não-somáveis).

**Problema resolvido**:

Na arquitetura anterior, a view única causava:
- ❌ Somatórios incorretos de medianas no Power BI
- ❌ Valores distorcidos ao aplicar filtros de múltiplos CCs/categorias
- ❌ Confusão entre granularidades (transação vs referência)

**Arquitetura atual**:

- ✅ `vw_gold_lancamentos` → Granularidade diária, valores somáveis
- ✅ `vw_gold_referencia_mtd` → Granularidade dia do mês, benchmarks de referência
- ✅ Uso correto de cada view no Power BI conforme propósito

---

## 📊 Métricas Calculadas

### YTD (Year-to-Date)

Acumulado do início do ano até o mês corrente:
```sql
SUM(valor) OVER (
    PARTITION BY Ano, ID_centro_de_custo, ID_categoria 
    ORDER BY Mes
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

**Partição**: Por ano, centro de custo e categoria  
**Ordenação**: Por mês  
**Janela**: Do início do ano até o mês atual

---

### MoM (Month over Month)

Comparação com o mês anterior (absoluto e percentual):
```sql
-- Valor do mês anterior
LAG(Realizado, 1) OVER (
    PARTITION BY ID_Centro_de_custo, ID_Categoria 
    ORDER BY Ano, Mes
)

-- MoM Absoluto
Realizado - valor_mes_anterior

-- MoM Percentual
Realizado / NULLIF(valor_mes_anterior, 0) - 1
```

**Uso do LAG**: Busca o valor 1 mês antes na partição  
**NULLIF**: Protege contra divisão por zero  
**Retorno**: Percentual de crescimento/queda

---

### YoY (Year over Year)

Comparação com o mesmo mês do ano anterior:
```sql
-- Valor do mesmo mês no ano anterior
LAG(Realizado, 12) OVER (
    PARTITION BY ID_Centro_de_custo, ID_Categoria 
    ORDER BY Ano, Mes
)

-- YoY Absoluto
Realizado - valor_mesmo_mes_ano_anterior

-- YoY Percentual  
Realizado / NULLIF(valor_mesmo_mes_ano_anterior, 0) - 1
```

**Uso do LAG(12)**: Busca o valor 12 meses antes  
**Importância da continuidade temporal**: dim_calendario garante que LAG(12) sempre pega o mesmo mês do ano anterior

---

### MTD (Month-to-Date)

Acumulado diário dentro do mês corrente:
```sql
SUM(total_do_dia) OVER(
    PARTITION BY ano, mes, id_centro_custo, id_categoria, id_fornecedor, id_campanha
    ORDER BY data_lancamento
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

**Partição**: Por mês e combinação de dimensões  
**Ordenação**: Por data de lançamento  
**Janela**: Do início do mês até a linha atual

**Uso**: Permite acompanhar evolução diária de gastos dentro do período mensal.

---

### Referências Históricas MTD

**Peso do Dia (Percentual Normalizado)**:
```sql
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY perc_gasto_mes) 
    OVER(PARTITION BY dia, id_centro_custo, id_categoria)
```

**Onde**: `perc_gasto_mes = gasto_MTD / total_do_mes`

**Interpretação**: Para o dia X, qual é o percentual mediano do mês que costuma estar gasto até este dia.

---

**Valor Mediano do Dia (Referência Absoluta)**:
```sql
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY gasto_MTD) 
    OVER(PARTITION BY dia, id_centro_custo, id_categoria)
```

**Interpretação**: Para o dia X, qual é o valor mediano (R$) de gasto MTD até este dia em meses anteriores.

---

### Pesos Relativos

Percentual que cada linha representa do total do mês:
```sql
-- Peso do centro de custo
SUM(Realizado) OVER(
    PARTITION BY ID_Centro_de_custo, Ano, Mes
) 
/ 
NULLIF(SUM(Realizado) OVER (PARTITION BY Ano, Mes), 0)

-- Peso da categoria
SUM(Realizado) OVER(
    PARTITION BY ID_Categoria, Ano, Mes
) 
/ 
NULLIF(SUM(Realizado) OVER (PARTITION BY Ano, Mes), 0)
```

**Numerador**: Total do centro/categoria no mês  
**Denominador**: Total geral do mês  
**Resultado**: Concentração percentual de gastos

---

### Flags de Anomalia

Identifica valores que desviam significativamente da média:
```sql
CASE 
    WHEN Realizado > 2 * AVG(NULLIF(Realizado, 0)) OVER (...) 
    THEN 'Valor_acima_do_normal'
    
    WHEN Realizado < 0.5 * AVG(NULLIF(Realizado, 0)) OVER (...) 
    THEN 'Valor_abaixo_do_normal'
    
    ELSE 'Valor_normal'
END
```

**Critério**: Valores 2x acima ou 50% abaixo da média histórica  
**Partição**: Por ano, centro de custo e categoria  
**Uso**: Alertas visuais no dashboard

---

## ⚠️ Proteções Implementadas

### Divisão por Zero

Todas as divisões utilizam `NULLIF` para evitar erros:
```sql
valor / NULLIF(total, 0)  -- Retorna NULL se total = 0
```

**Alternativa ao CASE**: Mais conciso que `CASE WHEN total = 0 THEN NULL ELSE valor/total END`

### Valores Nulos em Window Functions

Uso de `NULLIF` para excluir zeros de médias:
```sql
AVG(NULLIF(valor, 0)) OVER (...)  -- Ignora zeros no cálculo da média
```

### Continuidade Temporal

`dim_calendario` garante que todos os meses apareçam via `RIGHT JOIN`:
```sql
FROM BASE B
RIGHT JOIN (SELECT DISTINCT ano, mes FROM dim_calendario) CAL
    ON B.Ano = CAL.ano AND B.Mes = CAL.mes
```

**Efeito**: Meses sem lançamentos aparecem com `NULL` (tratado como 0 no BI)  
**Importância**: LAG(1) e LAG(12) sempre comparam meses consecutivos/equivalentes

### Corte Histórico Correto

Aplicado **após** o cálculo das métricas mensais (CTE `FINAL`):
```sql
WHERE data_lancamento < DATEFROMPARTS(2024, 11, 1)
```

**Justificativa**: Evita que meses futuros apareçam com zero artificial, distorcendo as medianas históricas.

---

## 📌 Resultado Final

As views Gold entregam:

- ✅ Métricas prontas para consumo no Power BI
- ✅ Cálculos complexos resolvidos na camada de dados
- ✅ Proteções contra erros comuns (divisão por zero, nulos)
- ✅ Flags de qualidade e anomalias
- ✅ Rastreabilidade mantida (flags de centro de custo coringa)
- ✅ **Separação correta entre valores somáveis e benchmarks estatísticos**

**Métricas disponíveis**:
- 2 métricas básicas (Orçado, Realizado)
- 2 acumulados (YTD para orçado e realizado)
- 4 comparativos temporais (MoM abs/%, YoY abs/%)
- 4 pesos relativos (centro de custo e categoria, para orçado e realizado)
- 2 médias históricas
- 2 flags de anomalia
- 2 referências históricas MTD (peso do dia, valor mediano)
- 1 métrica MTD (gasto acumulado diário)

**Total**: 19+ métricas pré-calculadas

---

## 🔄 Evolução da Arquitetura

### v1.0 → v2.0: Separação da View de Lançamentos

**Problema identificado:**

Na versão inicial, `vw_gold_lancamentos` continha:
- Valores transacionais diários (somáveis)
- Mediana histórica MTD (não-somável)

Ao consumir no Power BI, as medianas eram **somadas incorretamente** ao agregar múltiplos centros de custo.

**Solução implementada:**

Criação de `vw_gold_referencia_mtd` como view independente:
- Granularidade: dia do mês (1-31)
- Propósito: apenas referência visual
- Uso: linha de comparação em gráficos, cálculo de orçado ideal

**Impacto:**

- ✅ Métricas corretas no Power BI
- ✅ Arquitetura mais clara e manutenível
- ✅ Cada view com responsabilidade única

---

## 📖 Próxima Etapa

As views Gold são consumidas no **Power BI**, onde:

- Relacionamentos entre views são criados no modelo de dados
- `vw_gold_lancamentos` → usada para somatórios e KPIs
- `vw_gold_referencia_mtd` → usada para linhas de referência e cálculo de orçado ideal
- Cruzamento Orçado vs Realizado é realizado via relacionamentos ou medidas DAX
- Visualizações e KPIs são construídos sobre esta base confiável
- Filtros e slicers permitem análise interativa

📖 **[Documentação dos Dashboards](../../dashboards/)**

---
