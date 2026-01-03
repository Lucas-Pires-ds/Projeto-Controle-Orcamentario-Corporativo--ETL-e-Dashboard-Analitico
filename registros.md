# Diário de Desenvolvimento - Projeto BI Financeiro

## [28/12/2025] Início do Projeto e Ingestão de Dados
### O que foi feito:
- Definição do escopo: Controle Orçamentário e Lançamentos.
- Geração de dados sintéticos: 5000+ linhas usando Python para simular cenários reais com sazonalidade e erros.
- Configuração do ambiente: SQL Server no VS Code e criação do banco de dados `Financeiro_BI`.
- Estruturação inicial: Implementação da **Camada Bronze (stg_)**.

### Decisões técnicas:
- **Realismo de Dados:** Apliquei regras de sazonalidade (13º salário, marketing) e inserção de erros propositais (espaços, nulos, chaves órfãs) para testar o pipeline no limite.
- **Arquitetura de Camadas (Medallion):** Optei pelo padrão Bronze e Silver para garantir rastreabilidade. A Camada Bronze foi configurada em VARCHAR para garantir que a importação aterrissasse sem erros de conversão, permitindo tratar a "sujeira" via código depois.
- **Uso Consultivo de IA:** Utilização de Gemini e ChatGPT para validação de lógica SQL e refinamento da arquitetura.

---

## [03/01/2026] Analytics Engineering e Camada de Data Quality
### O que foi feito:
- **Refatoração Estrutural:** Reorganizei o script SQL em blocos lógicos: DDL, Diagnóstico, Transformação, Carga e Auditoria.
- **Finalização das Dimensões:** Concluí o diagnóstico e a carga das tabelas na **Camada Silver** (`dim_camp_marketing`, `dim_centro_custo`, `dim_categoria` e `dim_fornecedores`).
- **Implementação de Data Quality:** Criei uma camada de auditoria pré-transformação para garantir a saúde dos dados.

### Decisões técnicas:
- **Metodologia de Diagnóstico Automático:**
    - **Espaços Extras:** Substituí a análise visual pela lógica `LEN(col) > LEN(TRIM(col))`.
    - **Padrão de IDs:** Tratei chaves em formato decimal (`101.0`) via conversão aninhada `CAST(CAST(col AS FLOAT) AS INT)`.
    - **Auditoria de Unicidade:** Usei `GROUP BY` com `HAVING COUNT > 1` para validar as chaves primárias.
- **Saneamento Seletivo de Strings:**
    - Implementei lógica autoral para o formato *Initcap*.
    - **Exceções de Negócio:** Ajustei o código para ignorar siglas (RH, TI) e termos compostos (Limpeza/Conservação), mantendo a semântica original.
- **Investigação de Causa Raiz:** Detectei duplicidade na categoria "ALUGUEL/CONDOMÍNIO" causada por registros nulos, resolvendo com filtros de integridade na View.
- **Integridade Referencial:** Validação via `NOT IN` para garantir que toda categoria esteja vinculada a um centro de custo existente.

### Resolução de problemas:
- **Saneamento de Campos Numéricos:** Corrigi erros na função `LEN` em colunas numéricas usando `CAST(col AS VARCHAR)` na validação.
- **Validação de Tipagem:** Usei o `INFORMATION_SCHEMA.COLUMNS` para auditar se a tipagem das Views batia com o DDL das tabelas finais.
- **Soberania da Lógica:** Escolhi usar `RIGHT` e `LEN-1` em vez de funções prontas para manter o domínio total da lógica e facilitar a defesa técnica do código.

### Status Final das Dimensões:
- **Carga Concluída:** Todas as dimensões foram povoadas na Silver seguindo a hierarquia de chaves estrangeiras.
- **Relatório de Auditoria:** Usei `UNION ALL` no final para conferir a volumetria entre as camadas Bronze e Silver.

### Próximos passos:
- [ ] Iniciar o desafio das tabelas fato (`fato_lancamentos` e `fato_orcamento`).
- [ ] Implementar validação de integridade referencial profunda entre Fatos e Dimensões.
- [ ] Desenvolver a **Camada Gold** e o Dashboard no Power BI focado em KPIs de desvio orçamentário.