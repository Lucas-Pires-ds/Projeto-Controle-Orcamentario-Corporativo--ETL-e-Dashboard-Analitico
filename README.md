# Projeto: Controle Orçamentário - De ponta a ponta (ETL, Data Quality e Analytics)

## 📌 Visão Geral
Este projeto é focado em análise de dados financeiros, mas com um diferencial: em vez de apenas conectar o Power BI em dados crus, eu construí um pipeline de **ETL com alicerces de Engenharia de Dados**. O objetivo é garantir que qualquer análise no Dashboard seja baseada em dados que já passaram por uma régua rigorosa de qualidade e auditoria.

---

## 🏗️ Arquitetura do Pipeline
Desenhei o projeto em camadas para separar bem as responsabilidades e garantir que o processo seja rastreável:

1.  **Staging  (raw)**: Onde os dados aterrissam "como estão". É aqui que identifico ruídos, nulos e erros de preenchimento que gerei propositalmente via Python para simular um cenário real.
2.  **Diagnóstico de Qualidade (Data Quality)**: Antes de carregar qualquer dado definitivo, rodo scripts de auditoria via SQL para validar se o dado está saudável.
3.  **Trusted Layer (Dimensões e Fatos)**: É a camada final. Aqui o dado já está limpo, tipado e com todas as chaves batendo. É a única "fonte da verdade" do projeto.

---

## 🛠️ Tecnologias Utilizadas
* **SQL Server**: Onde acontece o "trabalho pesado" de limpeza, auditoria e modelagem.
* **Python**: Usei para gerar os dados sintéticos com regras de sazonalidade e erros controlados.
* **Power BI**: (Em construção) Camada para visualização e KPIs de gestão.

---

## 📈 Log de Desenvolvimento (Metodologia)

### [28/12/2025] Ingestão e Estrutura Inicial
* Configurei o ambiente SQL e a estrutura das primeiras tabelas.
* Fiz a carga de 5000+ registros via Bulk Insert na Staging.
* **Decisão técnica:** Optei por usar **Views** para a transformação. Isso me permite testar toda a limpeza e as regras de negócio antes de dar o insert final na camada física.

### [03/01/2026] Analytics Engineering: Auditoria e Carga das Dimensões
Nesta etapa, o foco foi garantir que as dimensões estivessem perfeitas. Saí da análise "no olho" e implementei validações via código:

* **Data Quality Automático:** Criei scripts para pegar espaços extras e nulos/vazios de forma automática, garantindo que nenhum registro "sujo" passasse despercebido.
* **Resolução de Tipagem:** Identifiquei que os IDs vinham como decimais (`101.0`) e tratei isso com conversões aninhadas (`FLOAT -> INT`) direto na View.
* **Padronização Inteligente (Initcap):** Desenvolvi uma lógica de padronização de nomes que respeita exceções de negócio. O código corrige o que está em caixa alta, mas preserva siglas (RH, TI) e termos técnicos compostos.
* **Investigação de Causa Raiz:** Rastreando os dados, encontrei duplicidades ocultas por nulos (como no caso da categoria Aluguel) e saneei isso direto no pipeline.
* **Integridade de Chaves:** Validei as chaves estrangeiras entre as dimensões para garantir que nenhuma categoria ficasse órfã de um centro de custo.

---

## 🚀 Próximos Passos
- [ ] Aplicar esse mesmo rigor de Data Quality nas tabelas Fato.
- [ ] Validar a integridade referencial completa entre Fatos e Dimensões.
- [ ] Construir o Dashboard no Power BI com foco em Orçado vs. Realizado.

---

Este é um projeto de portfólio para demonstrar habilidades em ETL, BI e Análise de Dados.