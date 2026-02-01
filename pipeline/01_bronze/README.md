# Camada Bronze — Ingestão de Dados

## Responsabilidade

A camada Bronze é responsável pela **ingestão de dados brutos** sem aplicar nenhuma transformação, validação ou tipagem.

**Objetivo**: Garantir que a carga de dados nunca falhe por incompatibilidade de tipos ou valores inesperados.

---

## 🎯 Características

- Todas as colunas armazenadas como `VARCHAR(MAX)` ou `VARCHAR(200)`
- Nenhuma validação ou constraint aplicada
- Preservação integral dos dados originais
- Nomenclatura padronizada: `stg_*` (staging)

---

## 🔧 Stack Utilizada

### Python (Pandas)
- Geração de dados sintéticos simulando sistema financeiro
- Exportação para CSV

### SQL Server (BULK INSERT)
- Carga rápida de grandes volumes
- Parametrizável por ambiente

---

## 📂 Estrutura de Arquivos
```
bronze/
├── README.md (este arquivo)
├── scripts_python/
│   ├── 01_geracao_das_dimensoes.py
│   └── 02_geracao_das_facts.py
└── scripts_sql/
    └── 01_ingestao_de_dados.sql
```

---

## 📊 Tabelas Criadas

| Tabela | Descrição |
|--------|-----------|
| `stg_orcamento` | Valores orçados por centro de custo e categoria |
| `stg_lancamentos` | Lançamentos financeiros diários |
| `stg_dim_centro_custo` | Centros de custo da empresa |
| `stg_dim_categoria` | Categorias de despesas |
| `stg_dim_fornecedores` | Cadastro de fornecedores |
| `stg_dim_campanha` | Campanhas de marketing ativas |

---

## 🔄 Processo de Ingestão

### 1. Geração dos Dados Sintéticos

Dois scripts Python geram CSVs simulando dados de um sistema financeiro real:

#### 01_geracao_das_dimensoes.py

Gera as dimensões analíticas:

**Dimensões geradas**:
- `dim_centro_custo.csv`: Centros de custo operacionais
- `dim_categoria.csv`: Categorias de despesa por centro de custo
- `dim_fornecedores.csv`: Cadastro de fornecedores
- `dim_campanha_marketing.csv`: Campanhas de marketing

#### 02_geracao_das_facts.py

Gera as tabelas fato com granularidade temporal:

**fact_orcamento**: 
- Planejamento mensal de despesas por categoria e centro de custo
- Período: 2023-2024

**fact_lancamentos**: 
- Lançamentos financeiros diários
- Período: 01/01/2023 a 31/12/2024
- Status de pagamento variados

### 2. Criação das Tabelas Staging

Script SQL: `01_ingestao_de_dados.sql`

Todas as tabelas Bronze seguem o mesmo padrão:
```sql
CREATE TABLE stg_lancamentos (
    id_lancamento VARCHAR(MAX),
    data_lancamento VARCHAR(MAX),
    id_centro_custo VARCHAR(MAX),
    id_categoria VARCHAR(MAX),
    id_fornecedor VARCHAR(MAX),
    id_campanha_marketing VARCHAR(MAX),
    valor_lancamento VARCHAR(MAX),
    status_pagamento VARCHAR(MAX)
);
```

**Características**:
- Todos os campos como `VARCHAR(MAX)`
- Nenhuma constraint ou validação
- Estrutura flexível para aceitar qualquer valor

### 3. Carga via BULK INSERT
```sql
BULK INSERT stg_lancamentos 
FROM 'C:\Projeto controle orcamentario\dados\raw\fact_lancamentos.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    CODEPAGE = '65001'
);
```

> **Nota**: O caminho do arquivo deve ser ajustado conforme o ambiente local

**Parâmetros utilizados**:
- `FIRSTROW = 2`: Ignora o header do CSV
- `CODEPAGE = '65001'`: UTF-8 para suportar caracteres acentuados
- `FIELDTERMINATOR = ','`: Delimitador de colunas
- `ROWTERMINATOR = '\n'`: Delimitador de linhas

---

## 🎯 Decisões Técnicas

### Tipagem Flexível com VARCHAR

Todas as colunas da camada Bronze foram definidas como `VARCHAR(MAX)` para maximizar a robustez da ingestão.

**Justificativa**: 
- Sistemas reais frequentemente enviam dados com tipagem inconsistente
- Evita falhas de carga por incompatibilidade de tipos
- Permite capturar qualquer valor, mesmo que incorreto ou inesperado
- Dados originais preservados integralmente para auditoria

O tratamento e conversão de tipos ocorrem apenas na camada Silver, após diagnóstico completo dos dados.

### Ausência de Validações na Bronze

A camada Bronze não aplica validações, constraints ou regras de negócio durante a ingestão.

**Justificativa**:

Esta decisão segue o princípio de separação de responsabilidades da arquitetura Medallion:

- **Bronze**: Ingestão pura, preservação do estado original
- **Silver**: Limpeza, validação e transformação
- **Gold**: Agregação e métricas analíticas

**Benefícios**:
- **Rastreabilidade**: Sempre possível consultar o dado original sem alterações
- **Reprocessamento**: Novas regras podem ser aplicadas sem reingestão
- **Diagnóstico**: Problemas de origem ficam visíveis para análise
- **Flexibilidade**: Mudanças nas regras de negócio não exigem recarga dos dados

---

## 📌 Próxima Etapa

Os dados brutos da camada Bronze são processados pela camada Silver, que aplica:

1. **Diagnóstico de Qualidade**
   - Identificação de valores ausentes, inválidos ou inconsistentes
   - Análise de integridade referencial
   - Detecção de outliers e anomalias

2. **Transformações**
   - Conversão de tipos (`VARCHAR` → `INT`, `DECIMAL`, `DATE`)
   - Limpeza de textos (`TRIM`, normalização de case)
   - Padronização de valores categóricos
   - Tratamento de dados problemáticos com flags de rastreamento

3. **Modelagem Dimensional**
   - Star Schema com integridade referencial garantida
   - Dimensões conformed
   - Fatos com granularidade adequada

📖 **[Documentação da camada Silver](../02_silver/)**

---