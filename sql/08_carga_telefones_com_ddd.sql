-- Tabela de DDDs válidos
CREATE TABLE IF NOT EXISTS ddd_anatel (
    ddd CHAR(2) PRIMARY KEY,
    uf CHAR(2),
    regiao VARCHAR(20),
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO ddd_anatel (ddd, uf, regiao) VALUES
('11','SP','Sudeste'),('12','SP','Sudeste'),('13','SP','Sudeste'),('14','SP','Sudeste'),
('15','SP','Sudeste'),('16','SP','Sudeste'),('17','SP','Sudeste'),('18','SP','Sudeste'),
('19','SP','Sudeste'),('21','RJ','Sudeste'),('22','RJ','Sudeste'),('24','RJ','Sudeste'),
('27','ES','Sudeste'),('28','ES','Sudeste'),('31','MG','Sudeste'),('32','MG','Sudeste'),
('33','MG','Sudeste'),('34','MG','Sudeste'),('35','MG','Sudeste'),('37','MG','Sudeste'),
('38','MG','Sudeste'),('41','PR','Sul'),('42','PR','Sul'),('43','PR','Sul'),
('44','PR','Sul'),('45','PR','Sul'),('46','PR','Sul'),('47','SC','Sul'),
('48','SC','Sul'),('49','SC','Sul'),('51','RS','Sul'),('53','RS','Sul'),
('54','RS','Sul'),('55','RS','Sul'),('61','DF','Centro-Oeste'),('62','GO','Centro-Oeste'),
('63','TO','Centro-Oeste'),('64','GO','Centro-Oeste'),('65','MT','Centro-Oeste'),
('66','MT','Centro-Oeste'),('67','MS','Centro-Oeste'),('68','AC','Norte'),
('69','RO','Norte'),('71','BA','Nordeste'),('73','BA','Nordeste'),('74','BA','Nordeste'),
('75','BA','Nordeste'),('77','BA','Nordeste'),('79','SE','Nordeste'),
('81','PE','Nordeste'),('82','AL','Nordeste'),('83','PB','Nordeste'),
('84','RN','Nordeste'),('85','CE','Nordeste'),('86','PI','Nordeste'),
('87','PE','Nordeste'),('88','CE','Nordeste'),('89','PI','Nordeste'),
('91','PA','Norte'),('92','AM','Norte'),('93','PA','Norte'),('94','PA','Norte'),
('95','RR','Norte'),('96','AP','Norte'),('97','AM','Norte'),('98','MA','Nordeste'),
('99','MA','Nordeste')
ON CONFLICT (ddd) DO NOTHING;

DROP FUNCTION IF EXISTS is_valid_ddd(text);
CREATE OR REPLACE FUNCTION is_valid_ddd(p_ddd TEXT)
RETURNS BOOLEAN IMMUTABLE LANGUAGE plpgsql AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM ddd_anatel WHERE ddd = p_ddd);
END;
$$;

-- Carga efetiva
DO $$ 
DECLARE 
    v_id_tipo_desconhecido INT;
    v_total_telefones INT;
    v_total_vinculos INT;
BEGIN
    SELECT id_tipo_relacao INTO v_id_tipo_desconhecido 
    FROM tipo_relacao 
    WHERE nome = 'Desconhecido';

    CREATE TEMP TABLE temp_telefones_pf AS
    WITH numeros_limpos AS (
        SELECT 
            "CPF" AS cpf,
            regexp_replace("Telefone1", '[^0-9]', '', 'g') AS numero_clean,
            'Fixo' AS tipo,
            1 AS ordem
        FROM "FPOLIS_PF"
        WHERE "Telefone1" IS NOT NULL AND trim("Telefone1") != ''
        UNION ALL
        SELECT "CPF", regexp_replace("Telefone2", '[^0-9]', '', 'g'), 'Fixo', 2 FROM "FPOLIS_PF" WHERE "Telefone2" IS NOT NULL AND trim("Telefone2") != ''
        UNION ALL
        SELECT "CPF", regexp_replace("Telefone3", '[^0-9]', '', 'g'), 'Fixo', 3 FROM "FPOLIS_PF" WHERE "Telefone3" IS NOT NULL AND trim("Telefone3") != ''
        UNION ALL
        SELECT "CPF", regexp_replace("Telefone4", '[^0-9]', '', 'g'), 'Fixo', 4 FROM "FPOLIS_PF" WHERE "Telefone4" IS NOT NULL AND trim("Telefone4") != ''
        UNION ALL
        SELECT "CPF", regexp_replace("Celular1", '[^0-9]', '', 'g'), 'Celular', 1 FROM "FPOLIS_PF" WHERE "Celular1" IS NOT NULL AND trim("Celular1") != ''
        UNION ALL
        SELECT "CPF", regexp_replace("Celular2", '[^0-9]', '', 'g'), 'Celular', 2 FROM "FPOLIS_PF" WHERE "Celular2" IS NOT NULL AND trim("Celular2") != ''
        UNION ALL
        SELECT "CPF", regexp_replace("Celular3", '[^0-9]', '', 'g'), 'Celular', 3 FROM "FPOLIS_PF" WHERE "Celular3" IS NOT NULL AND trim("Celular3") != ''
        UNION ALL
        SELECT "CPF", regexp_replace("Celular4", '[^0-9]', '', 'g'), 'Celular', 4 FROM "FPOLIS_PF" WHERE "Celular4" IS NOT NULL AND trim("Celular4") != ''
        UNION ALL
        SELECT "CPF", regexp_replace("Comercial1", '[^0-9]', '', 'g'), 'Comercial', 1 FROM "FPOLIS_PF" WHERE "Comercial1" IS NOT NULL AND trim("Comercial1") != ''
        UNION ALL
        SELECT "CPF", regexp_replace("Comercial2", '[^0-9]', '', 'g'), 'Comercial', 2 FROM "FPOLIS_PF" WHERE "Comercial2" IS NOT NULL AND trim("Comercial2") != ''
        UNION ALL
        SELECT "CPF", regexp_replace("Comercial3", '[^0-9]', '', 'g'), 'Comercial', 3 FROM "FPOLIS_PF" WHERE "Comercial3" IS NOT NULL AND trim("Comercial3") != ''
        UNION ALL
        SELECT "CPF", regexp_replace("Comercial4", '[^0-9]', '', 'g'), 'Comercial', 4 FROM "FPOLIS_PF" WHERE "Comercial4" IS NOT NULL AND trim("Comercial4") != ''
    )
    SELECT 
        cpf,
        numero_clean,
        tipo,
        ordem,
        LEFT(numero_clean, 2) AS ddd,
        RIGHT(numero_clean, LENGTH(numero_clean) - 2) AS numero
    FROM numeros_limpos
    WHERE 
        LENGTH(numero_clean) IN (10, 11)
        AND is_valid_ddd(LEFT(numero_clean, 2)) = TRUE;

    INSERT INTO telefone (ddd, numero, tipo, source_system, priority)
    SELECT DISTINCT
        ddd,
        numero,
        tipo,
        'FPOLIS_PF',
        1
    FROM temp_telefones_pf
    ON CONFLICT (ddd, numero) DO NOTHING;

    GET DIAGNOSTICS v_total_telefones = ROW_COUNT;

    INSERT INTO pessoa_telefone (
        pf_cpf, 
        id_telefone, 
        ordem, 
        tipo_uso, 
        tipo_linha,
        id_tipo_relacao,
        valid_from,
        source_system,
        priority
    )
    SELECT 
        clean_cpf(t.cpf),
        tel.id_telefone,
        t.ordem,
        t.tipo,
        t.tipo,
        v_id_tipo_desconhecido,
        NOW(),
        'FPOLIS_PF',
        1
    FROM temp_telefones_pf t
    JOIN telefone tel ON tel.ddd = t.ddd AND tel.numero = t.numero
    WHERE clean_cpf(t.cpf) IS NOT NULL
    ON CONFLICT (pf_cpf, id_telefone) DO NOTHING;

    GET DIAGNOSTICS v_total_vinculos = ROW_COUNT;

    DROP TABLE temp_telefones_pf;
    
    RAISE NOTICE '✅ Telefones únicos inseridos: %', v_total_telefones;
    RAISE NOTICE '✅ Vínculos PF-Telefone inseridos: %', v_total_vinculos;
END $$;
