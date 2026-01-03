
-------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------- CRIAÇÃO DE TABELAS --------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
GO

CREATE TABLE dim_camp_marketing(
       id_camp INT,
       nome_campanha VARCHAR(200),
       mes_referente INT,
       CONSTRAINT dim_camp_marketing_id_camp_pk PRIMARY KEY(id_camp)
)
GO

CREATE TABLE dim_centro_custo(
       id_cc INT,
       nome_cc VARCHAR(200),
       CONSTRAINT dim_centro_custo_id_cc_pk PRIMARY KEY(id_cc)
)
GO

CREATE TABLE dim_categoria(
       id_categoria INT,
       id_cc INT,
       nome_categoria VARCHAR(200)
       CONSTRAINT dim_categoria_id_categoria_pk PRIMARY KEY(id_categoria)
       CONSTRAINT dim_categoria_id_cc_fk FOREIGN KEY (id_cc) REFERENCES dim_centro_custo(id_cc)
)      
GO

CREATE TABLE dim_fornecedores(
       id_forn INT,
       nome_forn VARCHAR(200),
       CONSTRAINT dim_fornecedores_id_forn_pk PRIMARY KEY(id_forn)
)
GO

-------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------- VERIFICAÇÃO DE TRATAMENTOS NECESSÁRIOS --------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

-- dim_fornecedores
SELECT
       id_forn,
       LEN(id_forn) - LEN(TRIM(id_forn)) AS 'Dif ID',
       CASE WHEN LEN(id_forn) - LEN(TRIM(id_forn)) > 0 THEN 'Sim' ELSE 'Não' END AS 'Necessário TRIM?',
       nome_forn,
       LEN(nome_forn) - LEN(TRIM(nome_forn)) AS 'Dif nome_Norn',
       CASE WHEN LEN(nome_forn) - LEN(TRIM(nome_forn)) > 0 THEN 'Sim' ELSE 'Não' END AS 'Necessário TRIM?'
FROM stg_dim_fornecedores


-------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------TRANSFORMAÇÃO, LIMPEZA E CRIAÇÃO DE VIEWS -----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
GO
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
              CAST(TRIM(REPLACE(id_cat, '.0', '')) AS INT) AS 'id_cat',
              CAST(TRIM(REPLACE(id_cc, '.0', '')) AS INT)  AS 'id_cc',
              UPPER(LEFT(TRIM(nome_cat),1))
            + LOWER(RIGHT(TRIM(nome_cat),LEN(TRIM(nome_cat))-1)) AS 'nome_cat'
       FROM stg_dim_categoria
       WHERE id_cat IS NOT NULL
GO

-- dim_fornecedores


CREATE OR ALTER VIEW vw_fornecedores AS
       SELECT
              CAST(id_forn AS INT) AS 'id_forn',
              nome_forn
       FROM
              stg_dim_fornecedores
GO

-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------- VERIFICAÇÃO DE QUALIDADE DAS VIEWS -----------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vw_campanhas'

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vw_centro_custo'

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vw_categoria'

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'vw_fornecedores'

-------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------- CARGA DE DADOS --------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO dim_camp_marketing
SELECT * FROM vw_campanhas

INSERT INTO dim_centro_custo
SELECT * FROM vw_centro_custo

INSERT INTO dim_categoria
SELECT * FROM vw_categoria

INSERT INTO dim_fornecedores
SELECT * FROM vw_fornecedores
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











