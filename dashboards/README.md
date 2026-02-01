# Dashboard — Visualização e Analytics

## Responsabilidade

A camada de Dashboard é responsável por **consumir as views Gold e transformar dados analíticos em visualizações acionáveis** para tomada de decisão estratégica e operacional.

**Objetivo**: Entregar análise executiva do desempenho orçamentário e acompanhamento operacional preventivo do mês corrente, com sistema de alertas e priorização de ações.

---

## 🎯 Características

- Consumo direto das views Gold sem transformações adicionais
- Separação clara entre visões executiva (retrospectiva) e operacional (preventiva)
- Sistema de alertas baseado em benchmark estatístico (mediana histórica)
- Navegação intuitiva entre contextos analíticos
- Arquitetura push-down: cálculos complexos resolvidos no SQL, BI foca em visualização e contexto

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
- Facilita versionamento (um único arquivo no controle de versão)
- Evita duplicação do modelo semântico
- Garante consistência de métricas entre visões
- Navegação por páginas resolve separação de contextos sem fragmentação técnica
- Permite evolução incremental do dashboard mantendo integridade

---

## 📊 Estrutura de Páginas

### 1. Home
- Capa/menu de navegação
- Orientação sobre o propósito de cada visão analítica
- Entrada intuitiva no relatório

### 2. Operacional — Leitura Rápida
- Monitoramento diário escaneável
- Identificação imediata de riscos
- Priorização de ações corretivas

### 3. Operacional — Detalhamento Controlado
- Investigação objetiva de lançamentos
- Validação e conferência de gastos
- Drill-down sem transformar o dashboard em ERP

### 4. Executivo — Orçado vs Realizado *(planejado)*
- Análise mensal consolidada
- Comparação planejado vs executado
- Identificação de desvios estruturais

### 5. Executivo — Comparações Temporais *(planejado)*
- Análise de crescimento (MoM, YoY)
- Tendências temporais
- Identificação de variações sazonais

---

## 🧭 Sistema de Navegação

### Sidebar Lateral (Fixa)

Implementação: barra lateral não retrátil com ícones e tooltips.

**Decisão consciente:** Evitar sidebar retrátil para:
- Reduzir complexidade técnica desnecessária
- Manter foco na entrega de valor analítico
- Equilibrar elegância com viabilidade no contexto do projeto

**Ícones semânticos:**
- 🏠 Home
- 📊 Operacional — Leitura Rápida
- 🔍 Operacional — Detalhamento
- 📈 Executivo — Orçado vs Realizado
- 📉 Executivo — Comparações Temporais

### Filtros Contextuais

**Páginas Operacionais:**
- Centro de custo
- Categoria
- Período: fixado no mês corrente (comportamento padrão)

**Páginas Executivas:**
- Período (ano/mês)
- Centro de custo
- Categoria

---

## 🛠️ Dashboard Operacional — Leitura Rápida

### Objetivo

Permitir que o usuário entenda, **em poucos segundos**:
- Se o orçamento está sob controle
- Se o ritmo de consumo está saudável
- Onde estão os principais riscos

**Natureza do dashboard:** Preventivo, não reativo. Atua como radar de risco e instrumento de priorização de ação, não como espelho de lançamentos passados.

### Perguntas Respondidas
1. Estamos consumindo o orçamento mais rápido ou mais devagar que o esperado?
2. Quais centros de custo representam maior risco de estouro?
3. O ritmo atual está alinhado com o comportamento histórico da empresa?

### KPIs (Cards)

Leitura imediata dos números essenciais:

- **Total Orçado do Mês**: Planejamento financeiro total
- **Total Realizado até a Data Atual**: Consumo acumulado (MTD)
- **% do Orçamento Consumido**: Percentual de execução
- **% do Mês Decorrido**: Percentual temporal (referência)

**Interpretação:** A comparação entre consumo financeiro e passagem do tempo indica se o ritmo está saudável.

### Visual Principal — Consumo Acumulado

Gráfico de linha com três curvas simultâneas:

1. **Orçado Ideal Acumulado**: Orçamento distribuído com base na referência histórica (calculado em DAX)
2. **Realizado Acumulado (MTD)**: Gasto real até hoje
3. **Referência Histórica Acumulada**: Linha de comportamento esperado do consumo ao longo do mês

**Fonte de dados:**
- Realizado MTD → `vw_gold_lancamentos[Gasto_MTD]`
- Referência histórica → `vw_gold_referencia_mtd[valor_mediano_dia]`
- Orçado ideal → Calculado via DAX usando `vw_gold_referencia_mtd[peso_do_dia]`

**Interpretação:**
- Realizado acima do orçado ideal → Risco de estouro
- Realizado abaixo da referência histórica → Ritmo inferior ao padrão
- Realizado entre referência e orçado → Dentro do esperado

**Decisão arquitetural:** 

A referência histórica vem da `vw_gold_referencia_mtd` por ser um benchmark estrutural do negócio que não depende de interação do usuário. A view fornece:
- `peso_do_dia`: Percentual mediano acumulado até cada dia
- `valor_mediano_dia`: Valor mediano (R$) de gasto MTD histórico

**Cálculo do Orçado Ideal MTD (DAX):**
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

**Lógica:**
1. Identifica o dia atual do mês
2. Busca o peso histórico acumulado esperado para este dia
3. Aplica esse percentual ao orçamento mensal planejado
4. Resultado: valor que "deveria" estar gasto até hoje baseado no histórico

**Vantagens desta abordagem:**
- ✅ Orçado ideal não é linear (reflete comportamento real de gastos)
- ✅ Adapta-se ao contexto de filtros (CC, categoria)
- ✅ Usa benchmark estatisticamente robusto (mediana)

### Visuais de Apoio

#### 1. Matriz de Risco (Centro de Custo)

**Dimensão:** Centro de Custo

**Métricas:**
- % do orçamento consumido
- Status de risco (semáforo)
- Projeção de resultado final

**Semáforo de risco:**
- 🔴 Realizado > Orçado (estouro confirmado)
- 🟠 ≥ 80% do orçamento (atenção)
- 🟢 < 80% do orçamento (baixo risco)

**Decisão consciente:** Não detalhar por categoria nesta aba para manter leitura rápida. O objetivo é **identificar onde agir**, não investigar o porquê.

#### 2. Top 5 Centros de Custo com Maior Risco

Gráfico de barras horizontais ordenado por:
- Maior percentual de consumo OU
- Maior projeção de estouro

**Função:** Complementa a matriz, destacando prioridades e reduzindo esforço cognitivo do usuário.

### Sistema de Projeção

**Status de projeção:**
- "Tende a Estourar"
- "Dentro do Esperado"
- "Abaixo do Ritmo"

**Implementação:** Coluna adicional na matriz de risco e base para o ranking do Top 5.

**Decisão:** Projeção calculada em DAX (camada semântica) por depender diretamente do contexto de filtro e período selecionado pelo usuário.

---

## 🔍 Dashboard Operacional — Detalhamento Controlado

### Objetivo

Permitir **investigação objetiva** de lançamentos, sem transformar o dashboard em um sistema transacional ou substituto de ERP.

### Perguntas Respondidas
1. Quais foram os principais lançamentos do período?
2. Quanto ainda está pendente de pagamento?
3. Qual o resultado financeiro projetado para o fechamento do mês?

### KPIs (Cards)

Métricas mais analíticas para investigação:

- **Lançamentos Totais do Período**: Quantidade de transações
- **Total Realizado do Período**: Soma dos valores lançados
- **Desvio do Orçamento (R$)**: Diferença entre realizado e planejado
- **Total a Pagar (Pendentes)**: Lançamentos abertos
- **Previsão de Resultado Final**: Orçado mensal − (realizado pago + pendente)

**Fonte de dados:**
- `vw_gold_lancamentos` → Total do dia, Gasto MTD, Status pagamento
- `vw_gold_orcamento` → Orçado mensal

### Visual Principal — Tabela de Lançamentos

**Campos:**
- Centro de custo
- Categoria
- Fornecedor
- Campanha
- Data
- Total do dia (agregado diário)
- Gasto MTD (acumulado até a data)
- Status do pagamento

**Decisão técnica:**

A tabela usa `vw_gold_lancamentos`, que já agrega os lançamentos por dia. Isso significa:
- ✅ Valores são somáveis corretamente no Power BI
- ✅ Não há risco de contagem dupla ao aplicar filtros
- ✅ Performance otimizada (menos linhas que a fact original)

**Função:** Ponto final da análise, serve para validação e conferência, mas não incentiva microgestão excessiva.

### Bloco Lateral de Detalhamento

**Objetivo:** Remover excesso de colunas da tabela principal.

**Conteúdo:**
- Filtros adicionais
- Rankings pontuais
- Métricas auxiliares contextuais

---

## 📈 Dashboard Executivo — Orçado vs Realizado *(planejado)*

### Objetivo
Avaliar desempenho orçamentário mensal consolidado em perspectiva retrospectiva.

### Perguntas Respondidas
1. O gasto total está dentro do planejamento?
2. Quais meses apresentaram maior desvio?
3. Quais áreas são responsáveis pelos estouros?

### Visual Central
Gráfico de linha dupla: Orçado vs Realizado ao longo dos meses.

**Fonte de dados:**
- `vw_gold_orcamento` → Orçado mensal
- `vw_gold_realizado` → Realizado mensal

### KPIs (Cards)
- Total Orçado
- Total Realizado
- Desvio Absoluto (R$)
- Desvio Percentual (%)

**Padrão:** Valor principal (contexto filtrado) + valor secundário (ano completo).

### Visuais de Apoio
- Maiores desvios por centro de custo
- Maiores desvios por categoria

---

## 📉 Dashboard Executivo — Comparações Temporais *(planejado)*

### Objetivo
Analisar crescimento e variação de gastos ao longo do tempo.

### Perguntas Respondidas
1. O gasto atual é maior que o mesmo período do ano passado?
2. Qual a tendência de crescimento mês a mês?
3. Quais áreas tiveram maior aumento de custo?

### Visual Central
Gráfico de colunas agrupadas: ano atual vs ano anterior.

**Fonte de dados:**
- `vw_gold_realizado` → Métricas MoM e YoY já pré-calculadas

### KPIs (Cards)
- MoM Absoluto (R$)
- MoM Percentual (%)
- YoY Absoluto (R$)
- YoY Percentual (%)

**Decisão técnica:**

Todas essas métricas vêm **prontas da camada Gold** via window functions `LAG()`:
- ✅ Cálculos corretos mesmo com meses sem lançamentos (garantido pela `dim_calendario`)
- ✅ Performance otimizada (calculado uma vez no SQL)
- ✅ Lógica auditável e rastreável

### Visuais de Apoio
- Centros de custo com maior crescimento YoY
- Categorias com maior crescimento YoY

---

## 🔗 Integração com a Camada Gold

### Arquitetura de Dados: Separação de Responsabilidades

#### SQL (Camada Gold)
**Responsável por:**
- Cálculos pesados e agregações complexas
- Métricas históricas (mediana, YTD, MoM, YoY)
- Benchmarks estruturais do negócio
- Agregação diária de transações
- Tudo que não depende diretamente do contexto de filtro do usuário

#### Power BI (DAX — Camada Semântica)
**Responsável por:**
- Cálculos contextuais (dependem de filtros)
- Projeções dinâmicas (dependem do período selecionado)
- Métricas que variam com a interação do usuário
- Relacionamentos e cruzamentos entre tabelas Gold
- Cálculo do orçado ideal MTD

### Views Consumidas e Uso Correto

| View | Uso | Granularidade | Somável? |
|------|-----|---------------|----------|
| `vw_gold_orcamento` | Visão executiva de planejamento | Mensal | ✅ Sim |
| `vw_gold_realizado` | Visão executiva consolidada | Mensal | ✅ Sim |
| `vw_gold_lancamentos` | Visão operacional, KPIs MTD | Diária | ✅ Sim |
| `vw_gold_referencia_mtd` | Linha de referência gráfica | Dia do mês | ❌ **Não** |

**IMPORTANTE — Uso Correto da vw_gold_referencia_mtd:**

Esta view **NÃO deve ser usada para somatórios**. Ela fornece benchmarks estatísticos que só fazem sentido no contexto correto:

❌ **Uso incorreto:**
```dax
// ERRADO - soma medianas sem significado
Total Referência = SUM(vw_gold_referencia_mtd[valor_mediano_dia])
```

✅ **Uso correto:**
```dax
// CERTO - busca o benchmark do dia específico
Referência do Dia = 
VAR DiaAtual = DAY(MAX(dim_calendario[data]))
RETURN 
    CALCULATE(
        MAX(vw_gold_referencia_mtd[valor_mediano_dia]),
        vw_gold_referencia_mtd[dia] = DiaAtual
    )
```

✅ **Uso correto - Orçado Ideal:**
```dax
// CERTO - usa o peso histórico para distribuir o orçamento
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

**Relacionamento com outras tabelas:**

A `vw_gold_referencia_mtd` se relaciona com as demais apenas para:
- Aplicar filtros de Centro de Custo
- Aplicar filtros de Categoria
- **NÃO para agregações ou somatórios**

### Separação de Lançamentos em Duas Views

**Contexto da refatoração:**

Na arquitetura v1.0, `vw_gold_lancamentos` continha:
- Valores diários agregados (somáveis)
- Mediana histórica MTD (não-somável)

**Problema identificado:**

Ao consumir no Power BI, quando múltiplos centros de custo ou categorias eram filtrados, a mediana histórica era **somada incorretamente**, resultando em benchmarks distorcidos.

**Solução implementada (v2.0):**

Separação em duas views especializadas:

1. **`vw_gold_lancamentos`** (Granularidade: diária)
   - Valores agregados por dia
   - Total do dia somável
   - Gasto MTD calculado via window function
   - Uso: KPIs, totais, gráficos de evolução

2. **`vw_gold_referencia_mtd`** (Granularidade: dia do mês)
   - Peso do dia (mediana do % acumulado)
   - Valor mediano do dia (mediana do R$ acumulado)
   - Uso: **apenas** linhas de referência e cálculo de orçado ideal

**Impacto no Power BI:**

- ✅ Métricas corretas ao aplicar filtros
- ✅ Separação clara de responsabilidades
- ✅ Cada view usada conforme seu propósito

### Princípios de Integração

- ✅ Métricas estruturais calculadas no SQL (push-down computation)
- ✅ Power BI foca em relacionamentos, contexto e visualização
- ✅ Cruzamento Orçado vs Realizado realizado no BI via relacionamento
- ✅ Sem transformações adicionais no Power Query
- ✅ Modelo leve, performático e alinhado à filosofia de arquitetura em camadas
- ✅ **Views somáveis separadas de views de referência**

**Resultado:** Dashboards responsivos, métricas auditáveis e lógica rastreável até a camada de dados.

---

## 🎨 Design System e UI/UX

### Identidade Visual

**Estilo:** SaaS moderno, inspirado em dashboards corporativos maduros.

**Paleta de cores:**
- **Fundo:** #F3F4F8 (light mode)
- **Cards:** #FFFFFF
- **Bordas:** Cantos arredondados
- **Sombras:** Sutis, para sensação de profundidade

**Decisão:** Light mode como padrão para facilitar leitura em ambientes corporativos.

### Iconografia

**Princípio:** Ícones semânticos, coerentes e consistentes.

**Definições:**
- **Realizado / Pagos:** Check / Check-circle
- **Desvio do orçamento:** Setas divergentes
- **Total a pagar:** Relógio
- **Previsão:** Linha de tendência

**Regra geral:**
- Ícones neutros, mesma família visual
- Cor discreta (o número é o protagonista)
- Reforço semântico via tooltips

### Títulos Dinâmicos

**Implementação:** Títulos dos visuais feitos em DAX.

**Benefícios:**
- Contexto dinâmico (ex: "Consumo do Mês de Janeiro/2026")
- Clareza para o usuário
- Melhor storytelling analítico

---

## 🎯 Decisões de Design

### Coerência com a Camada Gold

O dashboard não recria lógica já resolvida na camada de dados. Métricas como YTD, MoM, YoY, mediana e agregações diárias vêm prontas da Gold, garantindo:
- ✅ Dashboards performáticos
- ✅ Métricas consistentes entre consumidores
- ✅ Lógica auditável no SQL
- ✅ Redução de complexidade no modelo semântico

### Separação de Contextos Analíticos

**Páginas Operacionais:**
- Monitoramento preventivo
- Métricas de acumulado diário (MTD)
- Alertas baseados em benchmark
- Foco: identificar onde agir
- **Fonte:** `vw_gold_lancamentos` + `vw_gold_referencia_mtd` (apenas referência)

**Páginas Executivas:**
- Análise retrospectiva consolidada
- Métricas de fechamento mensal
- Comparações temporais fixas (MoM, YoY)
- Foco: entender o que aconteceu
- **Fonte:** `vw_gold_orcamento` + `vw_gold_realizado`

### Princípio de Leitura Rápida

Cada página possui estrutura padronizada:
- **1 visual central:** Responde a pergunta-chave
- **4-5 KPIs:** Números essenciais para contexto
- **2-3 visuais de apoio:** Detalhamentos e rankings

**Decisão consciente:** Evitar excesso de formatação (bullets, headers, bold) nos visuais. Informação clara prevalece sobre elementos decorativos.

---

## 📌 Modelo de Dados — Relacionamentos

### Tabelas Fato (Somáveis)

- `vw_gold_orcamento`
- `vw_gold_realizado`
- `vw_gold_lancamentos`

**Relacionamentos:**
- Via `dim_calendario` (data)
- Via dimensões de Centro de Custo (id_centro_custo)
- Via dimensões de Categoria (id_categoria)

### Tabela de Referência (Não-Somável)

- `vw_gold_referencia_mtd`

**Relacionamentos:**
- Com dimensões de Centro de Custo e Categoria
- **NÃO tem relacionamento direto com dim_calendario** (usa campo `dia` independente)
- Usada apenas para contexto de filtro, não para agregações

**Cardinalidade:**
- Muitos para Um (*:1) com dimensões
- Filtros fluem das dimensões para a referência
- Valores da referência **NÃO se propagam para outras tabelas**

---

## 📊 Medidas DAX Essenciais

### Métricas Básicas (Somáveis)

```dax
Total Orçado = SUM(vw_gold_orcamento[Orcado_mensal])

Total Realizado = SUM(vw_gold_lancamentos[Total_do_dia])

Total Realizado MTD = 
    CALCULATE(
        SUM(vw_gold_lancamentos[Total_do_dia]),
        FILTER(
            ALL(dim_calendario[data]),
            dim_calendario[data] <= MAX(dim_calendario[data])
            && MONTH(dim_calendario[data]) = MONTH(MAX(dim_calendario[data]))
            && YEAR(dim_calendario[data]) = YEAR(MAX(dim_calendario[data]))
        )
    )
```

### Orçado Ideal MTD (Baseado em Referência Histórica)

```dax
Orçado Ideal MTD = 
VAR DiaAtual = DAY(MAX(dim_calendario[data]))
VAR PesoHistorico = 
    CALCULATE(
        MAX(vw_gold_referencia_mtd[peso_do_dia]),
        vw_gold_referencia_mtd[dia] = DiaAtual,
        ALLEXCEPT(vw_gold_referencia_mtd, vw_gold_referencia_mtd[id_centro_custo], vw_gold_referencia_mtd[id_categoria])
    )
VAR OrcamentoMensal = [Total Orçado]
RETURN 
    IF(
        NOT ISBLANK(OrcamentoMensal) && NOT ISBLANK(PesoHistorico),
        OrcamentoMensal * PesoHistorico,
        BLANK()
    )
```

**Explicação:**
1. Identifica o dia atual do mês
2. Busca o peso histórico esperado para este dia (mantendo filtros de CC/Categoria)
3. Aplica o peso ao orçamento mensal
4. Retorna BLANK se não houver dados

### Referência Histórica (Linha de Gráfico)

```dax
Referência Histórica MTD = 
VAR DiaAtual = DAY(MAX(dim_calendario[data]))
RETURN 
    CALCULATE(
        MAX(vw_gold_referencia_mtd[valor_mediano_dia]),
        vw_gold_referencia_mtd[dia] = DiaAtual
    )
```

### Desvios e Projeções

```dax
Desvio Orçamento = [Total Realizado MTD] - [Orçado Ideal MTD]

% Orçamento Consumido = 
    DIVIDE(
        [Total Realizado MTD],
        [Orçado Ideal MTD],
        0
    )

Projeção Final = 
VAR DiasNoMes = DAY(EOMONTH(MAX(dim_calendario[data]), 0))
VAR DiaAtual = DAY(MAX(dim_calendario[data]))
VAR TaxaGasto = DIVIDE([Total Realizado MTD], DiaAtual, 0)
RETURN TaxaGasto * DiasNoMes
```

---

## 📌 Resultado Final

O dashboard entrega:

- ✅ Visão executiva consolidada de desempenho orçamentário
- ✅ Análise temporal de crescimento e variação (planejada)
- ✅ Monitoramento preventivo intra-mês com benchmarks estatisticamente confiáveis
- ✅ Identificação de áreas de risco antes do fechamento
- ✅ Rastreabilidade de decisões analíticas até a camada de dados
- ✅ Experiência de usuário otimizada para leitura rápida e investigação controlada
- ✅ **Uso correto de views somáveis vs não-somáveis**
- ✅ **Orçado ideal calculado com base em comportamento histórico real**

---

## 🔄 Evolução da Arquitetura — Impacto no Dashboard

### v1.0 → v2.0: Refatoração da Integração com Gold

**Problema da v1.0:**

Dashboard consumia `vw_gold_lancamentos` única que continha:
- Valores transacionais (somáveis)
- Medianas históricas (não-somáveis)

**Sintoma:** Ao filtrar múltiplos CCs, o Power BI somava as medianas, gerando benchmarks irreais.

**Solução v2.0:**

Consumo de duas views especializadas:
1. `vw_gold_lancamentos` → para KPIs e totais
2. `vw_gold_referencia_mtd` → **apenas** para linhas de referência

**Impacto no modelo de dados:**
- ✅ Relacionamentos reestruturados
- ✅ Medidas DAX ajustadas para buscar dados da view correta
- ✅ Gráficos usando séries independentes (realizado vs referência)

**Resultado:**
- ✅ Benchmarks corretos em qualquer contexto de filtro
- ✅ Orçado ideal calculado com precisão
- ✅ Modelo mais robusto e manutenível

---

## 📖 Status e Próximos Passos

### Concluído
- [x] Arquitetura do dashboard definida
- [x] Estrutura de páginas planejada
- [x] Sistema de alertas especificado
- [x] Design system estabelecido
- [x] Mockups das abas operacionais finalizados
- [x] **Refatoração do modelo de dados para consumir views separadas**
- [x] **Medidas DAX ajustadas para uso correto da vw_gold_referencia_mtd**

### Em Desenvolvimento
- [ ] Implementação do modelo semântico no Power BI
- [ ] Criação das medidas DAX necessárias
- [ ] Construção da Aba Operacional — Leitura Rápida
- [ ] Construção da Aba Operacional — Detalhamento Controlado

### Planejado
- [ ] Construção da Home (capa/navegação)
- [ ] Implementação das páginas executivas
- [ ] Validação das métricas com cenários reais
- [ ] Ajustes visuais baseados em testes de usabilidade
- [ ] Refatoração pós-entrega (limpeza, simplificação, organização)