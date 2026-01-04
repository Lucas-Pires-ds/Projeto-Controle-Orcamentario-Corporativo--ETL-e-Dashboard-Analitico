-------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- CARGA DE DADOS --------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO dim_camp_marketing(id_camp, nome_campanha, mes_referente)
SELECT ID_camp, nome_camp, mes_ref FROM vw_campanhas

INSERT INTO dim_centro_custo(id_cc, nome_cc)
SELECT id_cc, nome_cc FROM vw_centro_custo

INSERT INTO dim_categoria(id_categoria, id_cc, nome_categoria)
SELECT id_cat, id_cc, nome_cat FROM vw_categoria

INSERT INTO dim_fornecedores(id_forn, nome_forn)
SELECT id_forn, nome_forn FROM vw_fornecedores

-------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- AUDITORIA FINAL -------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 'dim_camp_marketing' AS Tabela, COUNT(*) AS Total_Registros FROM dim_camp_marketing
UNION ALL
SELECT 'dim_centro_custo' AS Tabela, COUNT(*) AS Total_Registros FROM dim_centro_custo
UNION ALL
SELECT 'dim_categoria' AS Tabela, COUNT(*) AS Total_Registros FROM dim_categoria
UNION ALL
SELECT 'dim_fornecedores' AS Tabela, COUNT(*) AS Total_Registros FROM dim_fornecedores