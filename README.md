# 📊 Projeto de Controle Orçamentário — Pipeline ETL e Analytics
## Visão Geral

Este projeto simula um **pipeline completo de dados para controle orçamentário**, cobrindo desde a ingestão de dados brutos até a preparação de um **modelo analítico pronto para consumo em Power BI**.

O foco principal não é apenas gerar dashboards, mas **demonstrar pensamento de engenharia analítica**, com atenção especial à **qualidade dos dados**, **rastreabilidade**, **modelagem dimensional** e **integridade referencial** — problemas reais encontrados em ambientes corporativos.

O projeto foi desenvolvido com **SQL Server**, **Python** e **Power BI**, adotando boas práticas de arquitetura e ETL utilizadas no mercado.

> 🔎 **Como ler este README**
> - Para uma visão rápida: leia **Visão Geral**, **Arquitetura** e **Stack**
> - Caso tenha interesse nas decisões técnicas e nos porquês por trás do código, vale olhar **Framework de Qualidade de Dados** e **Decisões Técnicas de ETL**.
> - O status atual e os próximos passos estão descritos no final do README.

## 🎯 Problema de Negócio

Empresas que trabalham com orçamento frequentemente enfrentam desafios como:

* Dados financeiros vindos de múltiplas fontes e com baixa padronização

* Falta de controle de qualidade antes da análise

* Dificuldade em garantir consistência entre categorias, centros de custo e campanhas

Este projeto resolve esses problemas ao estruturar um pipeline que:

* Centraliza os dados

* Sanea inconsistências ainda na camada de dados

* Entrega dimensões confiáveis para análises financeiras e orçamentárias

## 🏗️ Arquitetura de Dados

![Arquitetura do Pipeline de Dados](docs_e_imagens/diagrama_pipeline_de_dados.png)

Foi adotado o padrão Medallion Architecture, separando claramente as responsabilidades de cada camada:

### 🥉 Camada Bronze (stg_)

* Ingestão de dados brutos via **Python (Pandas) + Bulk Insert**

* Todas as colunas armazenadas como VARCHAR(MAX) ou VARCHAR(200)

* Objetivo: **garantir que a carga nunca falhe por incompatibilidade de tipos**

> **Nota:** Os caminhos utilizados nos comandos `BULK INSERT` são parametrizáveis e devem ser ajustados conforme o ambiente local de execução.


A decisão de manter dados não tipados nesta camada permite que a limpeza ocorra de forma controlada no SQL Server.

### 🥈 Camada Silver (dim_ e fact_)

* Persistência física dos dados transformados e tipados

* Aplicação de **PRIMARY KEY** e **FOREIGN KEY**

* Preparação de um **modelo dimensional (Star Schema)**

As tabelas desta camada são a base confiável para o consumo analítico.

### 🔎 Transformações via Views (vw_)

* As transformações entre Bronze e Silver são feitas via **Views**

* Permite testar e ajustar regras de limpeza **sem reprocessar a carga física**

* Facilita auditoria, manutenção e rastreabilidade

## ✅ Framework de Qualidade de Dados

Antes da carga definitiva na camada Silver, foi implementado um conjunto de queries de diagnóstico, atuando como um framework de Data Quality.

### Principais validações

* **Auditoria de Espaços:** detecção de espaços extras com LEN(col) > LEN(TRIM(col))

* **Sanidade de IDs:** identificação de valores como 101.0 importados como string

* **Validação de Domínio:** meses fora do intervalo válido (1–12)

* **Unicidade:** verificação de chaves primárias duplicadas (GROUP BY + HAVING COUNT(*) > 1)

Essas validações permitem identificar problemas antes da persistência física, evitando erros silenciosos no modelo analítico.

## ⚙️ Decisões Técnicas de ETL
### Conversão de Tipagem Complexa

Para tratar IDs numéricos importados como strings decimais (ex: "101.0"), foi utilizada a conversão aninhada:

CAST(CAST(id_categoria AS FLOAT) AS INT)


Essa abordagem evita erros comuns do SQL Server ao tentar converter diretamente strings com ponto decimal para inteiros.

### Padronização Semântica de Strings

Foi desenvolvida uma lógica de InitCap personalizada, com foco na estética do dashboard sem comprometer o negócio:

* Primeira letra maiúscula, demais minúsculas

* Preservação de siglas em caixa alta (ex: **RH**, **TI**)

* Tratamento correto de delimitadores (ex: "Limpeza/Conservação")

### Integridade e Saneamento de Dados

* Registros com **IDs nulos na origem** foram identificados como causa raiz de duplicidades

* Esses registros foram descartados ainda na View (WHERE id IS NOT NULL)

* Validação cruzada garantiu que **toda categoria possua um Centro de Custo válido** antes da carga na Silver

## 🧩 Modelo Dimensional (Silver)

O modelo foi construído seguindo o padrão Star Schema, com foco em performance e clareza analítica.

### Dimensões implementadas

* **dim_centro_custo** — centros responsáveis pelo orçamento

* **dim_categoria** — natureza das despesas (com FK para centro de custo)

* **dim_camp_marketing** — campanhas e referência temporal

* **dim_fornecedores** — fornecedores envolvidos nos lançamentos

## 📄 Tabela Fato — fact_lancamentos (Silver)

A tabela fact_lancamentos representa os lançamentos financeiros efetivos e passou por um processo rigoroso de diagnóstico e saneamento antes da carga definitiva.

### Diagnóstico de Qualidade de Dados (Pré-Carga)

Durante o Data Profiling na tabela stg_lancamentos, foram identificados os seguintes pontos críticos:

- **Integridade Temporal**
  - 27 registros com data nula (~0,6% do montante financeiro)

- **Integridade Referencial**
  - 65 registros (~1,3%) com Centros de Custo inexistentes na dimensão

- **Anomalias de Sinal**
  - Lançamentos com valores negativos sem correlação com estorno ou cancelamento

- **Inconsistência Semântica**
  - Status de pagamento duplicados por variação de case e gênero
  - Exemplos: "Paga", "PAGO", "pago", "Pending"

---

### Decisões de Engenharia e Regras de Negócio

Para garantir confiabilidade analítica sem perda relevante de informação, foram aplicadas as seguintes estratégias:

- **Descarte Estratégico**
  - Registros sem data foram removidos devido ao alto risco analítico e baixo impacto financeiro (~0,6%)

- **Membro Coringa (Default Member)**
  - Criação do registro `-1 (NÃO IDENTIFICADO)` na `dim_centro_custo`
  - Permite preservar ~1,3% da massa financeira sem violar integridade referencial

- **Redundância Defensiva de Valores**
  - `valor`: valor absoluto tratado com `ABS()`, protegido por `CHECK CONSTRAINT (> 0)`
  - `valor_original`: preservação do dado bruto para auditoria e rastreabilidade

- **Normalização Semântica**
  - Padronização dos status de pagamento para apenas:
    - `Pago`
    - `Aberto`
  - Implementada via `CASE WHEN` com `UPPER()` e `TRIM()`

---

### Implementação Técnica

- Transformações centralizadas na `vw_lancamentos`
- Conversão de tipos:
  - `INT` para IDs
  - `DATETIME` para datas
  - `DECIMAL(16,2)` para valores
- Tratamento de IDs com resíduos decimais:
  - `CAST(CAST(col AS FLOAT) AS INT)`

### Status Final da fact_lancamentos

- **Primary Key:** definida sobre `id_lancamento`
- **Foreign Keys:** garantem vínculo com dimensões válidas ou membro coringa
- **Qualidade:** 100% dos registros respeitam regras de negócio e integridade referencial

## 📦 Auditoria Final da Carga

Após o carregamento da Silver:

* Carga realizada via INSERT INTO ... SELECT FROM vw_

* Validação de volumetria comparando tabelas através de UNION ALL

* Diferenças de registros foram analisadas e justificadas por filtros de qualidade

**Resultado:** dimensões prontas para consumo analítico, sem inconsistências estruturais.

## 🥇 Camada Gold — Decisões Analíticas

A camada Gold foi pensada para **reduzir lógica no Power BI** e entregar métricas prontas, com regras explícitas e defensivas aplicadas ainda no SQL Server.

Durante o desenvolvimento, ficou claro que uma única view não atendia bem a todos os objetivos analíticos. Por isso, foram criadas **duas views Gold distintas**, cada uma com um propósito claro.

### 📊 Gold Mensal — Orçado vs Realizado

A view **`vw_gold_mensal`** possui **granularidade mensal** e é voltada para a visão executiva e financeira.

Seu objetivo é responder perguntas como:

- O orçamento do mês foi respeitado?
- Onde estão os maiores desvios?
- Quais centros de custo e categorias têm maior peso no orçamento?

Principais métricas:

- **Orcado** — soma mensal do orçamento planejado  
- **Realizado** — soma mensal dos lançamentos financeiros  
- **Valor_desvio** — diferença entre realizado e orçado  
- **Percentual_desvio** — variação percentual em relação ao orçamento  
- **%_Atingimento** — quanto do orçamento foi consumido  
- **Peso_centro_custo / Peso_categoria** — participação relativa no orçamento total  
- **Métricas YTD** — acumulados de orçado, realizado e desvio ao longo do ano  

Essa view foi desenhada para consumo direto em dashboards, sem necessidade de cálculos complexos em DAX.

### 📅 Gold Diária — Acompanhamento Intramês

Além da visão mensal, foi criada uma **view Gold diária**, voltada para acompanhamento operacional.

O objetivo é permitir análises como:

- Quanto do orçamento do mês já foi consumido até hoje?
- O ritmo de gasto está acima do esperado?
- Em que momento do mês os desvios começam a aparecer?

A separação entre Gold mensal e Gold diária evita:

- Views excessivamente complexas
- Mistura de granularidades diferentes
- Lógica condicional desnecessária no Power BI


### Regras Analíticas Implementadas

As views da camada Gold aplicam regras de negócio explícitas para facilitar a leitura e o uso direto no Power BI, evitando lógica desnecessária no relatório.

Principais métricas consolidadas:

- **Orçado:** soma do orçamento planejado no período
- **Realizado:** soma dos lançamentos financeiros efetivos
- **Desvio:** diferença entre orçado e realizado
- **Percentual Consumido:** relação entre realizado e orçado (quando existe orçamento)

Regras importantes:

- Quando não há orçamento planejado para o período, os indicadores percentuais permanecem como `NULL`
- Divisões por zero são evitadas com `NULLIF`, garantindo estabilidade do modelo
- O consumo é analisado separando visão mensal (executiva) e diária (acompanhamento intramês)

Essas regras tornam os indicadores mais confiáveis e evitam interpretações incorretas nos dashboards.


### 🧠 Tratamento de Cenários de Exceção

Foram tratados explicitamente cenários comuns em ambientes reais:

- Categorias com gasto realizado, mas sem orçamento definido
- Períodos sem planejamento financeiro
- Prevenção de divisão por zero no cálculo percentual
- Uso de `COALESCE` para garantir consistência visual no consumo analítico

Essas decisões evitam distorções no dashboard e tornam o modelo resiliente a falhas de planejamento.

### 🔍 Validação Analítica

A camada Gold foi validada por meio de queries de conferência, assegurando:

- Consistência entre valores orçados e realizados
- Correto agrupamento por ano, mês, centro de custo e categoria
- Coerência dos status de orçamento gerados

Com essas validações, a camada Gold consolida o modelo analítico final, pronta para consumo no Power BI.

Nesta camada:
- As tabelas fato de **Lançamentos** e **Orçamento** são integradas para análises comparativas (*Budget vs Actual*).
- As dimensões saneadas da Silver garantem filtros confiáveis por centro de custo, categoria e tempo.
- As métricas financeiras e orçamentárias já incorporam regras de negócio, exceções e validações aplicadas no SQL Server.

O objetivo da camada Gold não é apenas visualização, mas **entregar métricas prontas para tomada de decisão**, reduzindo a necessidade de lógica complexa no Power BI.

*(Dashboards em desenvolvimento contínuo)*


## 🛠️ Stack Utilizada

* **SQL Server** — ETL, modelagem dimensional e integridade

* **Python (Pandas)** — ingestão e geração de dados sintéticos

* **Power BI** — visualização e análise

* **Git / GitHub** — versionamento e documentação

## 📌 Objetivo do Projeto

Este projeto nasceu como uma forma prática de consolidar meus estudos em análise de dados, BI e engenharia analítica, aplicando esses conceitos na construção de um pipeline completo de dados financeiros.

Mais do que o resultado final, o foco está no processo: tomar decisões técnicas, lidar com dados imperfeitos e estruturar uma base analítica confiável, próxima do que acontece no dia a dia de ambientes corporativos.

Ao longo do projeto, são explorados principalmente:
- Pensamento arquitetural
- Cuidado e rigor com qualidade de dados
- Transformação de dados brutos em informações prontas para análise 

## 📎 Próximos Passos

* Evoluir a camada Gold

* Publicar dashboards finais

> **Status do projeto:** em desenvolvimento contínuo, com evolução progressiva da camada Gold e das análises no Power BI.

📬 Fique à vontade para explorar o repositório e entrar em contato para feedbacks ou sugestões.

