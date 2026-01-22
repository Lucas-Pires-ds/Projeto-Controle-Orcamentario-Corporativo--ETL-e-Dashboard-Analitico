# Dashboard — Visualização e Analytics

## Responsabilidade

A camada de Dashboard é responsável por **consumir as views Gold e transformar dados analíticos em visualizações acionáveis** para tomada de decisão.

**Objetivo**: Entregar análise executiva do desempenho orçamentário e acompanhamento operacional preventivo do mês corrente.

---

## 🎯 Características

- Consumo direto das views Gold sem transformações adicionais
- Separação entre visões executiva (mensal) e operacional (intra-mês)
- Sistema de alertas preventivos baseado em mediana histórica
- Navegação intuitiva entre contextos analíticos
- Cálculos complexos resolvidos no SQL, BI foca em visualização

---

## 📂 Estrutura de Arquivos
```
dashboard/
├── README.md (este arquivo)
└── controle_orcamentario.pbix
```

---

## 🏗️ Arquitetura do Dashboard

### Decisão: Arquivo Único com Múltiplas Páginas

Estrutura adotada: **um único arquivo PBIX** com navegação interna entre páginas.

**Justificativa:**
- Facilita versionamento (um único arquivo)
- Evita duplicação do modelo semântico
- Garante consistência de métricas entre visões
- Navegação por páginas resolve separação de contextos

---

## 📊 Estrutura de Páginas

### 1. Home
- Apresentação do dashboard
- Contexto do projeto
- Menu de navegação

### 2. Executivo — Orçado vs Realizado
- Análise mensal consolidada
- Comparação planejado vs executado
- Identificação de desvios

### 3. Executivo — Comparações Temporais
- Análise de crescimento (MoM, YoY)
- Tendências temporais
- Identificação de variações

### 4. Operacional — Acompanhamento Intra-mês
- Monitoramento diário do consumo
- Sistema de alertas preventivos
- Matriz de risco orçamentário

---

## 🧭 Sistema de Navegação

### Menu Lateral (Fixo)
- 🏠 Home
- 📊 Executivo — Orçado vs Realizado
- 📈 Executivo — Comparações Temporais
- 🛠️ Operacional — Acompanhamento Intra-mês

### Filtros Contextuais

**Páginas Executivas:**
- Período (ano/mês)
- Centro de custo
- Categoria

**Página Operacional:**
- Centro de custo
- Categoria
- Período: fixo no mês corrente

---

## 📈 Dashboard Executivo — Orçado vs Realizado

### Objetivo
Avaliar desempenho orçamentário mensal consolidado.

### Perguntas Respondidas
1. O gasto total está dentro do planejamento?
2. Quais meses apresentaram maior desvio?
3. Quais áreas são responsáveis pelos estouros?

### Visual Central
Gráfico de linha dupla: Orçado vs Realizado ao longo dos meses.

### KPIs (Cards)
- Total Orçado
- Total Realizado
- Desvio Absoluto (R$)
- Desvio Percentual (%)

Padrão dos cards: valor principal (contexto filtrado) + valor secundário (ano completo).

### Visuais de Apoio
- Maiores desvios por centro de custo
- Maiores desvios por categoria

---

## 📈 Dashboard Executivo — Comparações Temporais

### Objetivo
Analisar crescimento e variação de gastos ao longo do tempo.

### Perguntas Respondidas
1. O gasto atual é maior que o mesmo período do ano passado?
2. Qual a tendência de crescimento mês a mês?
3. Quais áreas tiveram maior aumento de custo?

### Visual Central
Gráfico de colunas agrupadas: ano atual vs ano anterior.

### KPIs (Cards)
- MoM Absoluto (R$)
- MoM Percentual (%)
- YoY Absoluto (R$)
- YoY Percentual (%)

### Visuais de Apoio
- Centros de custo com maior crescimento YoY
- Categorias com maior crescimento YoY

---

## 🛠️ Dashboard Operacional — Acompanhamento Intra-mês

### Objetivo
Monitoramento diário preventivo do consumo orçamentário, identificando desvios antes do fechamento.

### Perguntas Respondidas
1. No ritmo atual, vamos terminar o mês acima ou abaixo do orçamento?
2. O gasto acumulado está condizente com o comportamento histórico?
3. Quais categorias já consumiram mais de 80% do orçamento?

### Visual Central — Consumo Acumulado

Gráfico de linha com três referências simultâneas:

1. **Realizado Acumulado (MTD)**: Gasto real até hoje
2. **Orçado Ideal Acumulado**: Distribuição linear do orçamento mensal (calculado em DAX)
3. **Mediana Histórica**: Benchmark baseado no comportamento típico de meses anteriores

**Interpretação:**
- Linha acima da mediana → Ritmo elevado
- Entre mediana e orçado → Dentro do esperado
- Abaixo da mediana → Ritmo baixo

### KPIs Operacionais
- Orçamento Mensal
- Realizado Até Hoje
- % Orçamento Consumido
- % Mês Decorrido

### Matriz de Risco Orçamentário

Tabela destacando centros de custo e categorias por nível de risco:

- 🟢 **< 80%**: Baixo risco
- 🟡 **80% – 100%**: Atenção
- 🔴 **> 100%**: Estouro confirmado

---

## 🚨 Sistema de Alertas Preventivos

### Como Funciona

O gasto acumulado até hoje (MTD) é comparado com a **mediana histórica** dos gastos até o mesmo dia em meses anteriores.

**Exemplo:** Se hoje é dia 15 e o gasto já representa 120% da mediana do dia 15, indica ritmo acima do padrão.

### Semáforo de Risco

| Status | Condição | Interpretação |
|--------|----------|---------------|
| 🟢 Abaixo | MTD ≤ 80% da mediana | Ritmo inferior ao histórico |
| 🟡 Normal | MTD entre 81% e 100% | Ritmo alinhado ao esperado |
| 🔴 Acima | MTD > 100% | Ritmo superior — atenção |

### Decisão: Mediana ao Invés de Média

A referência histórica usa **mediana** porque a base possui meses com gastos atípicos (outliers) já identificados e sinalizados nas camadas anteriores.

**Comparação:**
- **Média**: Sensível a valores extremos, distorce o padrão
- **Mediana**: Robusta contra outliers, representa comportamento típico

**Resultado:** Alertas mais estáveis e confiáveis.

### Implementação Técnica

**Cálculo da mediana (SQL):**
```sql
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Gasto_ate_dia) 
  OVER (PARTITION BY Dia_do_mes, id_centro_custo)
```

**Classificação do alerta (SQL):**
```sql
CASE 
  WHEN Gasto_MTD / Mediana_MTD_CC <= 0.8  THEN 'Abaixo_do_normal'
  WHEN Gasto_MTD / Mediana_MTD_CC <= 1.0  THEN 'Dentro_do_normal'
  ELSE 'Acima_do_normal'
END
```

**Orçado ideal acumulado (DAX):**
```dax
Orçado Ideal Acumulado = 
VAR DiasNoMes = DAY(EOMONTH(MAX(dim_calendario[data]), 0))
VAR OrcamentoMensal = SUM(vw_gold_orcamento[Orcado_mensal])
VAR DiaAtual = DAY(MAX(dim_calendario[data]))
RETURN DIVIDE(OrcamentoMensal, DiasNoMes) * DiaAtual
```

**Condicional de cor (DAX):**
```dax
Cor do Alerta = 
SWITCH(
    [Flag_alerta_gasto],
    "Abaixo_do_normal", "#10B981",
    "Dentro_do_normal", "#F59E0B",
    "Acima_do_normal", "#EF4444",
    "#9CA3AF"
)
```

---

## 🔗 Integração com a Camada Gold

O dashboard consome exclusivamente as views analíticas:

| View | Uso |
|------|-----|
| `vw_gold_orcamento` | Visão executiva mensal de orçamento |
| `vw_gold_realizado` | Visão executiva mensal de realizado |
| `vw_gold_lancamentos` | Visão operacional diária + alertas |

### Princípios de Integração

- Métricas complexas (YTD, MoM, YoY, mediana) calculadas no SQL
- Power BI foca em relacionamentos, contexto e visualização
- Cruzamento Orçado vs Realizado realizado no BI
- Sem transformações adicionais no Power Query

---

## 🎯 Decisões de Design

### Coerência com a Camada Gold

O dashboard não recria lógica já resolvida na camada de dados. Métricas como YTD, MoM, YoY e flags de alerta vêm prontas da Gold, garantindo:
- Dashboards performáticos
- Métricas consistentes entre consumidores
- Lógica auditável no SQL

### Separação de Contextos

**Páginas Executivas:**
- Análise retrospectiva consolidada
- Métricas de fechamento mensal
- Comparações temporais fixas

**Página Operacional:**
- Monitoramento preventivo
- Métricas de acumulado diário
- Alertas baseados em benchmark

### Leitura Rápida

Cada página possui:
- 1 visual central (responde a pergunta-chave)
- 4-5 KPIs (números essenciais)
- 2-3 visuais de apoio (detalhamentos)

---

## 📌 Resultado Final

O dashboard entrega:

- ✅ Visão executiva consolidada de desempenho orçamentário
- ✅ Análise temporal de crescimento e variação
- ✅ Monitoramento preventivo intra-mês com alertas confiáveis
- ✅ Identificação de áreas de risco antes do fechamento
- ✅ Rastreabilidade de decisões analíticas

---

## 📖 Próximos Passos

- [ ] Implementação do modelo semântico no Power BI
- [ ] Criação das medidas DAX necessárias
- [ ] Validação das métricas com cenários reais
- [ ] Ajustes visuais baseados em testes de usabilidade

---