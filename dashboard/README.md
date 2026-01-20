# Camada Dashboard — Power BI

# Dashboards — Camada Analítica

## Responsabilidade

A camada de **Dashboards** é responsável por **consumir as views da camada Gold** e transformá-las em **análises visuais orientadas à tomada de decisão**, sem reimplementar lógica de negócio já resolvida no SQL.

**Objetivo**: Demonstrar como as bases analíticas foram consumidas no Power BI, explicitando decisões de modelagem, relacionamento e escopo analítico.

---

## 🎯 Escopo Atual

Este README documenta **apenas o que foi efetivamente definido e implementado até o momento**. Decisões visuais, layout, paleta de cores e escolhas estéticas **não fazem parte deste estágio** e serão tratadas posteriormente.

O foco aqui é:
- Consumo correto das views Gold
- Decisões de modelagem no Power BI
- Limites técnicos do ambiente
- Separação clara entre SQL (dados) e BI (análise)

---

## 📊 Fontes de Dados Utilizadas

O dashboard consome exclusivamente **views da camada Gold**, sem acesso direto a tabelas Silver ou Bronze.

### Views Consumidas

| View | Papel no Dashboard |
|-----|--------------------|
| `vw_gold_orcamento` | Base mensal de orçamento planejado |
| `vw_gold_realizado` | Base mensal do realizado com métricas temporais |
| `vw_gold_lancamentos` | Base detalhada para drill-down e auditoria |

Essa decisão garante:
- Consistência com a arquitetura Medallion
- Reutilização das métricas já validadas
- Redução de lógica duplicada no Power BI

---

## 🧩 Modelo de Dados no Power BI

O modelo no Power BI replica, de forma controlada, a separação conceitual definida na camada Gold.

### Estratégia de Relacionamento

- `vw_gold_orcamento` e `vw_gold_realizado` **não são unidas no SQL**
- O cruzamento Orçado vs Realizado ocorre **no Power BI**, via relacionamentos
- A granularidade comum é:
  - Ano
  - Mês
  - Centro de custo
  - Categoria

**Justificativa**:
- Diferentes análises podem exigir cruzamentos distintos
- Evita rigidez excessiva na camada Gold
- Mantém o SQL focado em preparação de dados, não em narrativa analítica

### Papel da Data de Fim de Mês

Ambas as views (`vw_gold_orcamento` e `vw_gold_realizado`) expõem uma **data no último dia do mês** (`EOMONTH`).

Essa escolha facilita:
- Relacionamento com uma dimensão calendário no BI
- Uso correto de hierarquias temporais
- Comparações mensais consistentes

---

## 📈 Escopos Analíticos Definidos

Até o momento, foram claramente separados três escopos de análise:

### 1. Visão Executiva Mensal

Baseada principalmente em:
- `vw_gold_orcamento`
- `vw_gold_realizado`

Foco em:
- Orçado vs Realizado
- Evolução mensal
- Acumulado no ano (YTD)
- Concentração de gastos por centro de custo e categoria

Toda a lógica de:
- YTD
- MoM
- YoY
- Pesos relativos

já está resolvida no SQL e apenas consumida no BI.

---

### 2. Acompanhamento Intramês

O acompanhamento intramês é viabilizado pela **granularidade diária preservada** em `vw_gold_lancamentos`.

Objetivo:
- Entender quanto do orçamento mensal já foi consumido
- Monitorar concentração de gastos dentro do mês
- Permitir leitura progressiva do consumo

A decisão de manter uma view diária separada evita:
- Inflar a view mensal com dados desnecessários
- Criar métricas híbridas difíceis de manter

---

### 3. Drill-down e Auditoria

`vw_gold_lancamentos` funciona como base de suporte analítico:
- Investigação de picos mensais
- Identificação de fornecedores, campanhas ou categorias específicas
- Análise de lançamentos associados a centro de custo coringa

Essa view **não é agregada no BI** por padrão, preservando sua função de detalhamento.

---

## ⚠️ Limitações Técnicas Atuais

### Licenciamento do Power BI

O projeto foi desenvolvido **sem licença Power BI Pro**.

Consequências práticas:
- Compartilhamento via arquivo `.pbix`
- Ausência de publicação em workspace compartilhado
- Sem controle de permissões ou RLS
- Atualização manual dos dados

Essas limitações são assumidas conscientemente e **não impactam a validade técnica do modelo analítico**.

---

## 🎯 Decisões de Arquitetura no BI

### Lógica Analítica Fora do DAX

Sempre que possível, optou-se por:
- Resolver métricas no SQL (Gold)
- Manter o Power BI focado em visualização e interação

Isso reduz:
- Complexidade de medidas DAX
- Risco de inconsistência entre visuais
- Dificuldade de manutenção

### Uso de Flags Analíticas

Flags como:
- Valor atípico
- Centro de custo coringa

são consumidas diretamente no BI para:
- Filtros
- Destaques visuais
- Segmentações analíticas

Sem necessidade de recriar regras no Power BI.

---

## 📌 Estado Atual do Dashboard

Até este ponto, o projeto possui:

- Modelo de dados definido no Power BI
- Conexão direta com views Gold
- Separação clara entre análise mensal, intramês e detalhamento
- Base pronta para construção de KPIs e visuais

Decisões visuais, layout, storytelling e refinamento de UX **serão documentados em iterações futuras**, à medida que forem definidos.

---

## 📖 Contexto no Projeto

Este README fecha o ciclo iniciado no pipeline:

- Bronze: ingestão
- Silver: limpeza e modelagem
- Gold: métricas analíticas
- **Dashboard: consumo e análise**

O foco permanece na **clareza técnica, rastreabilidade e separação de responsabilidades**, evitando sobreposição entre camadas.

