-------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------- VERIFICAÇÃO DE TRATAMENTOS NECESSÁRIOS --------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------- FACT_LANCAMENTOS --------------------------------------------------------------------------

SELECT * FROM stg_lancamentos -- OVERVIEW

-- VERIFICACAO DE ESPAÇOS EXTRAS

SELECT
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(id_lancamento) > LEN(TRIM(id_lancamento))
    ) AS 'espacos_ID_lancamento',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(data_lancamento) > LEN(TRIM(data_lancamento))
    ) AS 'espacos_data',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(id_centro_custo) > LEN(TRIM(id_centro_custo))
    ) AS 'espacos_ID_centro_custo',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(id_categoria) > LEN(TRIM(id_categoria))
    ) AS 'espacos_ID_categoria',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(id_fornecedor) > LEN(TRIM(id_fornecedor))
    ) AS 'espacos_ID_fornecedor',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(id_campanha_marketing) > LEN(TRIM(id_campanha_marketing))
    ) AS 'espacos_ID_campanha',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(valor_lancamento) > LEN(TRIM(valor_lancamento))
    ) AS 'espacos_valor_lancamento',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        LEN(status_pagamento) > LEN(TRIM(status_pagamento))
    ) AS 'espacos_status_pagamento'

-- VERIFICACAO DE NULOS E VAZIOS

SELECT
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_lancamento IS NULL OR LEN(id_lancamento) = 0 
    ) AS 'ID_lancamento_nulos',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        data_lancamento IS NULL OR LEN(data_lancamento) = 0
    ) AS 'data_nulos',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_centro_custo IS NULL OR LEN(id_centro_custo) = 0
    ) AS 'id_centro_custo_nulos',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_categoria IS NULL OR LEN(id_categoria) = 0
    ) AS 'id_categoria_nulos',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_fornecedor IS NULL OR LEN(id_fornecedor) = 0
    ) AS 'id_fornecedor_nulos',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        valor_lancamento IS NULL OR LEN(valor_lancamento) = 0
    ) AS 'valor_lancamento_nulos',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        status_pagamento IS NULL OR LEN(status_pagamento) = 0
    ) AS 'status_pagamento_nulos'

-- UMA VEZ IDENTIFICADO 27 REGISTROS COM DATAS NULAS, RODAREI UMA QUERY PARA VISUALIZAR O IMPACTO FINANCEIRO DESSES DADOS:
SELECT
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos), 'C')AS 'valor_total', 
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos WHERE data_lancamento IS NULL), 'C') AS 'sem_data', 
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos WHERE data_lancamento IS NULL) / (SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos), '0.00%') AS 'impacto_(%)'

-- IMPACTO IDENTIFICADO = 0,6%.

-- VERIFICACAO DE INTEGRIDADE REFERENCIAL DE CHAVES ESTRANGEIRAS

SELECT
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_centro_custo NOT IN (SELECT id_cc FROM dim_centro_custo)
    ) AS 'ID_centro_custo_invalido',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_categoria NOT IN (SELECT id_categoria FROM dim_categoria)
    ) AS 'ID_categoria_invalido',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        id_fornecedor NOT IN (SELECT id_forn FROM dim_fornecedores)
    ) AS 'id_fornecedor_invalido',
    (SELECT
        COUNT(*)
    FROM
        stg_lancamentos
    WHERE
        CAST(CAST(id_campanha_marketing AS FLOAT) AS INT) NOT IN (SELECT id_camp FROM dim_camp_marketing)
    ) AS 'id_campanha_invalido'

-- UMA VEZ IDENTIFICADO 65 REGISTROS COM UM CENTRO DE CUSTO INVÁLIDO, RODAREI UMA QUERY PARA VISUALIZAR O IMPACTO FINANCEIRO DESSES REGISTROS:
SELECT
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos), 'C')AS 'valor_total', 
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos WHERE id_centro_custo NOT IN (SELECT ID_CC FROM dim_centro_custo)), 'C') AS 'centro_custo_invalido', 
    FORMAT((SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos WHERE id_centro_custo NOT IN (SELECT ID_CC FROM dim_centro_custo)) / (SELECT SUM(CAST(valor_lancamento AS DECIMAL(18,2))) FROM stg_lancamentos), '0.00%') AS 'impacto_(%)'

-- IMPACTO IDENTIFICADO = 1,3%

-- VERIFICACAO DE VALORES NEGATIVOS

SELECT
    status_pagamento,
    COUNT(CAST(valor_lancamento as DECIMAL(18,2))) AS 'qtd_registros',
    SUM(CAST(valor_lancamento as DECIMAL(18,2))) AS 'valor_por_status'
FROM
    stg_lancamentos
WHERE 
    CAST(valor_lancamento as DECIMAL(18,2)) LIKE '-%'
GROUP BY status_pagamento

-- VERIFICACAO DE STATUS DE PAGAMENTO DUPLICADOS

SELECT
    DISTINCT
        status_pagamento COLLATE Latin1_General_CS_AS AS 'status_pagamento'
FROM stg_lancamentos


-- VERIFICACAO DE TIPOS DE DADOS

SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'stg_lancamentos' 

/* RESULTADO DAS VERIFICAÇÕES:

ESPACOS EXTRAS: 0 ENCONTRADOS. NENHUM TRATAMENTO NECESSÁRIO.

NULOS OU VAZIOS: 27 REGISTROS COM DATAS NULAS ENCONTRADOS. IMPACTO FINANCEIRO IDENTIFICADO DE 0,6%. TRATAMENTO: DADOS SERÃO DESCARTADOS POR TEREM BAIXO 
IMPACTO FINANCEIRO, FRENTE O RISCO DE CORROMPIMENTO DE ANALISES TEMPORAIS.

INTEGRIDADE REFERENCIAL DE CHAVES ESTRANGEIRAS: IDENTIFIQUEI 65 REGISTROS COM CENTRO DE CUSTO NÃO CADASTRADO, REPRESENTANDO 1,3% DE IMPACTO FINANCEIRO DO MONTANTE TOTAL.
DADO QUE JÁ DESCARTEI 0,6% REFERENTE AOS REGISTROS SEM DATA, OPTO POR NÃO DESCARTAR ESSES 1,3% QUE TOTALIZARIAM JUNTO AOS REGISTROS ANTERIORMENTE DESCARTADOS, PRATICAMENTE 2%
DE UM MONTANTE DE 11,6 MILHOES. TRATAMENTO: ADICIONAREI NA TABELA "DIM_CENTRO_CUSTO" UM CENTRO DE CUSTO CORINGA PARA LANCAMENTOS COM CENTROS DE CUSTO INVÁLIDOS.

VALORES NEGATIVOS: IDENTIFIQUEI 51 REGISTROS COM VALORES NEGATIVOS. COMO NÃO ESTÃO ATRELADOS A UM STATUS ESPECÍFICO (EX: "CANCELADO" OU "ESTORNADO"), 
TRATEI COMO INCONSISTÊNCIA DE SINAL. POR PRECAUÇÃO, MANTIVE A COLUNA COM O VALOR ORIGINAL PARA AUDITORIA, MAS CRIEI UMA COLUNA DE VALOR TRATADO UTILIZANDO A FUNÇÃO ABS(), 
GARANTINDO A INTEGRIDADE DOS CÁLCULOS NO DASHBOARD.

STATUS DE PAGAMENTO: FORAM INDENTIFICADAS DUPLICIDADES NOS TERMOS UTILIZADOS PARA STATUS DE PAGAMENTO, SENDO ELAS (Paga, Pago, PAGO) E (Aberto, Pending). 
TRATAMENTO: PADRONIZAÇÃO DE STATUS PARA 2 OPÇÕES: "Pago" e "Aberto". 

TIPOS DE DADOS: TODOS OS DADOS ESTÃO COM TIPO VARCHAR. TRATAMENTO: CONVETEREI OS IDS EM INT, DATA_LANCAMENTO EM DATETIME E VALOR EM DECIMAL (16,2).
*/