# Projeto: Controle Orçamentário - De ponta a ponta (ETL, Data Quality e Analytics)

## 📌 Visão Geral
Este projeto é focado em análise de dados financeiros, mas com um diferencial: em vez de apenas conectar o Power BI em dados crus, eu construí um pipeline de **ETL com alicerces de Engenharia de Dados**. O objetivo é garantir que qualquer análise no Dashboard seja baseada em dados que já passaram por uma régua rigorosa de qualidade e auditoria.

---

## 🏗️ Arquitetura do Pipeline (Medalhão)
Desenhei o projeto utilizando o conceito de camadas para separar as responsabilidades e garantir que o processo seja rastreável:

1.  **Camada Bronze (Raw/Staging)**: Onde os dados aterrissam "como estão". Configurei esta camada com colunas em formato VARCHAR para garantir que a importação aterrissasse sem erros de conversão, permitindo que qualquer "sujeira" fosse tratada via código depois.
2.  **Diagnóstico de Qualidade (Data Quality)**: Antes de mover o dado para a próxima camada, rodo scripts de auditoria via SQL para validar se o dado está saudável.
3.  **Camada Silver (Trusted/Dimensional)**: É a camada onde o dado já está limpo, tipado e com todas as chaves batendo. É a "fonte da verdade" do projeto, estruturada em modelos dimensionais.
4.  **Camada Gold (Analytics)**: (Em desenvolvimento) Tabelas agregadas e visões prontas para consumo direto no Power BI.

---

## 🛠️ Tecnologias Utilizadas
* **SQL Server**: Motor principal para processamento, limpeza, auditoria e modelagem.
* **Python**: Geração de dados sintéticos com regras de sazonalidade e erros propositais.
* **Power BI**: (Em construção) Camada de visualização e análise de indicadores.

---

## 📈 Log de Desenvolvimento (Metodologia)

### [28/12/2025] Ingestão e Estrutura Inicial
* Configuração do ambiente SQL e criação das tabelas da camada **Bronze**.
* Carga de 5000+ registros via Bulk Insert.
* **Decisão técnica:** Uso de **Views** para isolar a lógica de transformação, permitindo testar a limpeza antes de persistir os dados na camada Silver.

### [03/01/2026] Analytics Engineering: Auditoria e Carga das Dimensões
Foco total na qualidade das dimensões, movendo a análise visual para validações automáticas via código:

* **Data Quality Automático:** Implementação de scripts para detectar espaços extras, nulos e campos vazios de forma massiva.
* **Resolução de Tipagem:** Tratamento de IDs decimais (`101.0`) importados como string, resolvidos com conversão aninhada (`FLOAT -> INT`) na View de transformação.
* **Padronização Inteligente (Initcap):** Lógica de padronização que respeita siglas de negócio (RH, TI) e termos compostos, tratando apenas o que estava em caixa alta indevida.
* **Investigação de Causa Raiz:** Identificação de duplicidades geradas por registros nulos e saneamento direto no pipeline.
* **Integridade Referencial:** Validação de chaves estrangeiras entre as dimensões para evitar dados "órfãos" no modelo final.

---

## 🚀 Próximos Passos
- [ ] Aplicar o rigor de Data Quality nas tabelas Fato (Silver Layer).
- [ ] Validar a integridade referencial profunda entre Fatos e Dimensões.
- [ ] Desenvolver a Camada Gold para suportar os indicadores do Power BI.

---

Este é um projeto de portfólio para demonstrar habilidades em ETL, BI e Análise de Dados.

