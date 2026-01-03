# Diário de Desenvolvimento - Projeto BI Financeiro
## [28/12/2025] Início do Projeto e Ingestão de Dados
### O que foi feito:
Definição do escopo: Controle Orçamentário e Lançamentos.

Geração de dados sintéticos: 5000+ linhas usando Python para simular cenários reais com sazonalidade e erros.

Configuração do ambiente: SQL Server no VS Code e criação do banco de dados Financeiro_BI.

Estruturação inicial: Implementação da Camada de Staging (stg_).

### Decisões técnicas:
Realismo de Dados: Aplicação de regras de sazonalidade (13º salário, campanhas de marketing) e inserção de erros propositais (espaços, nulos, chaves órfãs) para testar o pipeline.

Arquitetura de Camadas: Optei pelo padrão Staging e Trusted para garantir rastreabilidade.

Uso Consultivo de IA: Utilização de Gemini e ChatGPT para validação de lógica SQL e refinamento da arquitetura.

## [03/01/2026] Analytics Engineering e Camada de Data Quality
### O que foi feito:
Refatoração Estrutural: Reorganização do script SQL em blocos lógicos: DDL, Diagnóstico, Transformação, Carga e Auditoria.

Finalização das Dimensões: Conclusão do diagnóstico e carga das tabelas dim_camp_marketing, dim_centro_custo, dim_categoria e dim_fornecedores.

Implementação de Data Quality: Criação de uma camada de auditoria pré-transformação para garantir a saúde dos dados.

### Decisões técnicas:
Metodologia de Diagnóstico Automático:

Espaços Extras: Substituição da análise visual pela lógica LEN(col) > LEN(TRIM(col)).

Padrão de IDs: Identificação de chaves em formato decimal (101.0) tratadas via conversão aninhada CAST(CAST(col AS FLOAT) AS INT).

Auditoria de Unicidade: Uso de GROUP BY com HAVING COUNT > 1 para validar chaves primárias.

Saneamento Seletivo de Strings:

Implementação de lógica autoral para formato Initcap.

Exceções de Negócio: Ajuste do código para ignorar siglas (RH, TI) e termos compostos (Limpeza/Conservação), preservando a semântica original.

Investigação de Causa Raiz: Detecção de duplicidade na categoria "ALUGUEL/CONDOMÍNIO" causada por registros nulos, resolvida com filtros de integridade na View.

Integridade Referencial: Validação via NOT IN para garantir que toda categoria esteja vinculada a um centro de custo existente.

### Resolução de problemas:
Saneamento de Campos Numéricos: Correção de erros na função LEN em colunas numéricas através de CAST(col AS VARCHAR) durante a validação.

Validação de Tipagem: Uso do INFORMATION_SCHEMA.COLUMNS para auditar se a tipagem das Views coincidia com o DDL das tabelas finais.

Soberania da Lógica: Optei por utilizar RIGHT e LEN-1 em vez de funções prontas para manter a autoria e defesa técnica do código em futuras revisões.

### Status Final das Dimensões:
Carga Concluída: Todas as dimensões foram povoadas seguindo a hierarquia de chaves estrangeiras.

Relatório de Auditoria: Implementação de UNION ALL final para conferência de volumetria entre as camadas.

### Próximos passos:
[ ] Iniciar o desafio das tabelas fato (fato_lancamentos e fato_orcamento).

[ ] Implementar validação de integridade referencial profunda entre Fatos e Dimensões.

[ ] Desenvolver o Dashboard no Power BI focado em KPIs de desvio orçamentário.