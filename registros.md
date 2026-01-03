# Diário de Desenvolvimento - Projeto BI Financeiro

## [28/12/2025] Início do Projeto e Ingestão de Dados
### O que foi feito:
- Defini o escopo: Controle Orçamentário e Lançamentos.
- Gerei mais de 5000 linhas via Python pra simular o dia a dia real, com sazonalidade e erros.
- Configurei o SQL Server no VS Code e criei o banco `Financeiro_BI`.
- Estruturei a Camada de Staging (`stg_`) pra garantir que a importação não trave.

### Decisões técnicas:
- **Dados Reais:** No script Python, apliquei regras de sazonalidade e erros propositais (espaços, nulos e chaves órfãs) pra testar meu pipeline de verdade.
- **Arquitetura:** Escolhi o padrão de camadas (Staging e Trusted). Usei Views pra tratar o dado sujo antes do insert final, garantindo que a Trusted fique 100% limpa.
- **Limpeza Inicial:** Identifiquei duplicidades críticas (como 'ALUGUEL/CONDOMÍNIO') e já tratei com filtros de nulos, além de converter chaves de `VARCHAR` para `INT`.

---

## [03/01/2026] Analytics Engineering e Data Quality
### O que foi feito:
- Refatorei o script SQL pra um modelo de pipeline mais organizado (DDL, Diagnóstico, Transformação e Carga).
- Finalizei o diagnóstico e a carga de todas as dimensões (`Campanha`, `Centro de Custo`, `Categoria` e `Fornecedores`).
- Implementei uma camada de **Data Quality** rigorosa antes da fase de transformação.

### Decisões técnicas:
- **Diagnóstico Automático:** Saí da análise "no olho" e criei scripts pra pegar sujeira de forma automática. Usei `LEN(col) > LEN(TRIM(col))` pra espaços e `IS NULL OR LEN(col) = 0` pra capturar vazios.
- **Tratamento de IDs:** Vi que os IDs vinham como decimais (`101.0`). Resolvi usando dois `CASTs` (`FLOAT -> INT`) nas Views, que é a forma mais limpa de sanear isso.
- **Padronização de Strings:** Criei uma lógica de *Initcap* autoral que respeita as exceções de negócio (RH/TI e termos como "Limpeza/Conservação"), tratando só o que estava em caixa alta.
- **Causa Raiz:** Investiguei uma duplicidade na `dim_categoria` vinda de registros nulos e tratei direto na View.
- **Integridade:** Rodei um `NOT IN` pra garantir que todas as categorias tivessem um centro de custo válido antes de carregar a Trusted.



### Resolução de problemas:
- **Erros na função LEN:** Contornei erros em colunas numéricas aplicando `CAST(col AS VARCHAR)` dentro da validação.
- **Autoria do Código:** Optei por usar `RIGHT` e `LEN-1` na padronização pra manter o domínio total da lógica e conseguir defender cada linha em uma revisão técnica.
- **Hierarquia de Carga:** Respeitei a ordem das chaves estrangeiras, carregando o `Centro de Custo` antes da `Categoria`.

### Próximos passos:
- [ ] Atacar as tabelas Fato com a mesma régua de qualidade.
- [ ] Validar a integridade referencial profunda (FKs das Fatos).
- [ ] Partir pro Power BI pra criar o dashboard.