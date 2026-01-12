-------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------TRANSFORMAÇÃO, LIMPEZA E CRIAÇÃO DE VIEWS -----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

-- dim_camp_marketing

CREATE OR ALTER VIEW vw_campanhas AS 
       SELECT
              CAST(id_camp AS INT) AS 'ID_camp',
              nome_camp,
              CAST(mes_ref AS INT) AS 'mes_ref' 
       FROM stg_dim_campanha

GO


-- dim_centro_custo

CREATE OR ALTER VIEW vw_centro_custo AS
       SELECT
              CAST(id_cc AS INT) AS 'id_cc',
              UPPER(LEFT(TRIM(nome_cc),1))+LOWER(RIGHT(TRIM(nome_cc),LEN(TRIM(nome_cc))-1)) AS 'nome_cc'
       FROM stg_dim_centro_custo

GO


-- dim_categoria

CREATE OR ALTER VIEW vw_categoria AS 
       SELECT
              CAST(CAST(id_cat AS FLOAT) AS INT) AS 'id_cat',
              CAST(CAST(id_cc AS FLOAT) AS INT)  AS 'id_cc',
              nome_cat AS 'nome_cat'
       FROM stg_dim_categoria
       WHERE id_cat IS NOT NULL AND id_cc IS NOT NULL
GO


-- dim_fornecedores

CREATE OR ALTER VIEW vw_fornecedores AS
       SELECT
              CAST(id_forn AS INT) AS 'id_forn',
              nome_forn
       FROM
              stg_dim_fornecedores
GO



GO
-- fact_lancamentos

CREATE OR ALTER VIEW vw_lancamentos AS 
SELECT  
       CAST(id_lancamento AS INT) AS 'id_lancamento',
       CAST(CAST(data_lancamento AS DATE) AS DATETIME) AS 'data_lancamento',
       CAST(CASE WHEN
               id_centro_custo NOT IN (SELECT id_cc FROM dim_centro_custo)
                THEN -1 ELSE id_centro_custo END AS INT) AS 'id_cc',
       CAST(id_categoria AS INT) AS 'id_categoria',
       CAST(id_fornecedor AS INT) AS 'id_fornecedor',
       CAST(CAST(id_campanha_marketing AS FLOAT) AS INT) AS 'id_campanha',
       ABS(CAST(valor_lancamento AS DECIMAL(16,2))) AS 'valor_absoluto',
       CAST(valor_lancamento AS DECIMAL(16,2)) AS 'valor_original',
       CASE 
              WHEN status_pagamento IN ('PAGO', 'Paga', 'Pago') THEN 'Pago'
              WHEN status_pagamento IN ('Pending', 'Aberto') THEN 'Aberto'
              ELSE 'Outros'
       END AS 'status_pagamento'
FROM
       stg_lancamentos
WHERE data_lancamento IS NOT NULL

GO

-- fact_orcamento

CREATE OR ALTER VIEW vw_orcamento AS

SELECT
       CAST(id_orcamento AS INT) AS 'id_orcamento',
       CAST(EOMONTH(DATEFROMPARTS(CAST(ANO AS INT), CAST(mes AS INT), 1)) AS DATETIME) AS 'data',
       CAST(ano AS INT) AS 'ano',
       CAST(mes AS INT) AS 'mes',
       CAST(id_centro_custo AS INT) AS 'id_centro_custo',
       CAST(id_categoria AS INT) AS 'id_categoria',
       CAST(valor_orcado AS DECIMAL(18,2)) AS 'valor_orcado',
       CASE
              WHEN CAST(valor_orcado AS DECIMAL(18,2)) / AVG(CAST(valor_orcado AS DECIMAL(18,2))) 
              OVER (PARTITION BY id_centro_custo, id_categoria) - 1 > 9 THEN 'Dado suspeito' ELSE 'Dado confiavel'
       END AS 'status_dado'
FROM 
    stg_orcamento

GO


-- CAMADA GOLD VIEW MENSAL (EXECUTIVA)

CREATE OR ALTER VIEW vw_gold_mensal AS

WITH T AS (
SELECT
       CAL.ano AS 'Ano',
       CAL.mes AS 'Mes',
       CC.id_cc AS 'ID_Centro_custo',
       CC.nome_cc AS 'Centro_de_custo',
       CAT.id_categoria AS 'ID_Categoria',
       CAT.nome_categoria AS 'Categoria',
       DF.id_forn AS 'ID_Fornecedor',
       DF.nome_forn AS 'Fornecedor',
       MKT.id_camp AS 'ID_Campanha',
       MKT.nome_campanha AS 'Campanha',
       SUM(FO.valor) AS 'Orcado',
       SUM(FL.valor) AS 'Realizado',
       SUM(FL.valor) - SUM(FO.valor) AS 'Valor_desvio',
       (SUM(FL.valor) - NULLIF(SUM(FO.valor),0)) / NULLIF(SUM(FO.valor),0)  AS 'Percentual_desvio',
       SUM(FL.valor) / NULLIF(SUM(FO.valor),0) AS '%_Atingimento',
       FO.status_dado AS 'Status_dado_orcado',
       CASE WHEN CC.id_cc = -1 THEN 'Sim' ELSE 'Nao' END AS 'Flag_centro_custo_coringa',
       CASE WHEN SUM(FO.valor) IS NULL THEN 'Nao orcado' ELSE 'Orcado' END AS 'Flag_houve_orcamento'     
FROM 
       fact_lancamentos FL
LEFT JOIN
       dim_calendario CAL 
              ON CAL.[data] = FL.data_lancamento
LEFT JOIN 
       dim_centro_custo CC
              ON CC.id_cc = FL.id_centro_custo
LEFT JOIN
       dim_categoria CAT
              ON CAT.id_categoria = FL.id_categoria
LEFT JOIN fact_orcamento FO
       ON FO.ano = CAL.ano
      AND FO.mes = CAL.mes
      AND FO.id_centro_custo = CC.id_cc
      AND FO.id_categoria = CAT.id_categoria
LEFT JOIN 
       dim_camp_marketing MKT 
              ON MKT.id_camp = FL.id_campanha
LEFT JOIN dim_fornecedores DF
       ON DF.id_forn = FL.id_fornecedor
GROUP BY CAL.ANO, CAL.mes, CC.id_cc, CC.nome_cc, CAT.id_categoria, CAT.nome_categoria, DF.id_forn, DF.nome_forn, MKT.id_camp, MKT.nome_campanha, status_dado 
)

SELECT Ano,
       Mes,
       ID_Centro_custo,
       Centro_de_custo,
       ID_Categoria,
       Categoria,
       ID_Fornecedor,
       Fornecedor,
       COALESCE(CAST (ID_Campanha AS VARCHAR(50)), 'Sem campanha') AS 'ID_Campanha',
       COALESCE(Campanha, 'Sem campanha') AS 'Campanha',
       Orcado as 'Orcado',
       Realizado,
       COALESCE(Valor_desvio,Realizado - COALESCE(Orcado, 0)) AS 'Valor_desvio',
       Percentual_desvio,
       [%_Atingimento],
       NULLIF(SUM(ORCADO) OVER(PARTITION BY Centro_de_custo),0) / NULLIF(SUM(ORCADO) OVER(),0) AS 'Peso_centro_custo',
       SUM(ORCADO) OVER(PARTITION BY Categoria) / SUM(ORCADO) OVER() AS 'Peso_categoria',
       NULLIF(SUM(ORCADO) OVER( PARTITION BY Ano, Centro_de_custo, Categoria ORDER BY Mes), 0) AS 'Orcado_YTD',
       SUM(REALIZADO) OVER( PARTITION BY Ano, Centro_de_custo, Categoria ORDER BY Mes) AS 'Realizado_YTD',
       SUM(REALIZADO) OVER( PARTITION BY Ano, Centro_de_custo, Categoria ORDER BY Mes) 
       - NULLIF(SUM(ORCADO) OVER( PARTITION BY Ano, Centro_de_custo, Categoria ORDER BY Mes),0) AS 'Valor_desvio_YTD',
       SUM(REALIZADO) OVER( PARTITION BY Ano, Centro_de_custo, Categoria ORDER BY Mes) 
       / NULLIF(SUM(ORCADO) OVER( PARTITION BY Ano, Centro_de_custo, Categoria ORDER BY Mes),0) AS 'Percentual_desvio_YTD',
       Status_dado_orcado,
       Flag_centro_custo_coringa,
       Flag_houve_orcamento
FROM T






go































-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------- VERIFICAÇÃO DA TIPAGEM DE DADOS DAS VIEWS ----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vw_campanhas'
UNION ALL
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vw_centro_custo'
UNION ALL
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vw_categoria'
UNION ALL
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vw_fornecedores'
UNION ALL
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vw_lancamentos'
UNION ALL
SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vw_orcamento'
