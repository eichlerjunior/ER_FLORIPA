-- =====================================================================
-- SCRIPT 03: ADICIONA RASTREAMENTO TEMPORAL E RESOLVE CONFLITOS (VERSÃO COMPLETA)
-- =====================================================================

DO $$ 
BEGIN
    -- 1. ADICIONAR CAMPOS DE VALIDADE NAS RELAÇÕES (PESSOA <-> TELEFONE/ENDERECO/EMAIL)
    -- Verifica se a tabela existe antes de tentar alterar

    -- pessoa_telefone
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='pessoa_telefone') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='pessoa_telefone' AND column_name='valid_from') THEN
            ALTER TABLE pessoa_telefone ADD COLUMN valid_from TIMESTAMP DEFAULT NOW() NOT NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='pessoa_telefone' AND column_name='valid_to') THEN
            ALTER TABLE pessoa_telefone ADD COLUMN valid_to TIMESTAMP;
        END IF;
    END IF;

    -- pessoa_endereco
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='pessoa_endereco') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='pessoa_endereco' AND column_name='valid_from') THEN
            ALTER TABLE pessoa_endereco ADD COLUMN valid_from TIMESTAMP DEFAULT NOW() NOT NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='pessoa_endereco' AND column_name='valid_to') THEN
            ALTER TABLE pessoa_endereco ADD COLUMN valid_to TIMESTAMP;
        END IF;
    END IF;

    -- pessoa_email
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='pessoa_email') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='pessoa_email' AND column_name='valid_from') THEN
            ALTER TABLE pessoa_email ADD COLUMN valid_from TIMESTAMP DEFAULT NOW() NOT NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='pessoa_email' AND column_name='valid_to') THEN
            ALTER TABLE pessoa_email ADD COLUMN valid_to TIMESTAMP;
        END IF;
    END IF;

    -- telefone_midia
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='telefone_midia') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='telefone_midia' AND column_name='valid_from') THEN
            ALTER TABLE telefone_midia ADD COLUMN valid_from TIMESTAMP DEFAULT NOW() NOT NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='telefone_midia' AND column_name='valid_to') THEN
            ALTER TABLE telefone_midia ADD COLUMN valid_to TIMESTAMP;
        END IF;
    END IF;

    -- email_midia
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='email_midia') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='email_midia' AND column_name='valid_from') THEN
            ALTER TABLE email_midia ADD COLUMN valid_from TIMESTAMP DEFAULT NOW() NOT NULL;
        END IF;
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='email_midia' AND column_name='valid_to') THEN
            ALTER TABLE email_midia ADD COLUMN valid_to TIMESTAMP;
        END IF;
    END IF;

    -- 2. ADICIONAR COLUNA 'tipo_linha' NA TABELA pessoa_telefone (se existir e não existir a coluna)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='pessoa_telefone') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name='pessoa_telefone' AND column_name='tipo_linha') THEN
            ALTER TABLE pessoa_telefone ADD COLUMN tipo_linha VARCHAR(20);
        END IF;
    END IF;

    -- 3. REMOVER COLUNAS OBSOLETAS DA TABELA 'telefone' (se existirem)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name='telefone') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='telefone' AND column_name='whatsapp') THEN
            ALTER TABLE telefone DROP COLUMN whatsapp CASCADE;
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='telefone' AND column_name='celular') THEN
            ALTER TABLE telefone DROP COLUMN celular CASCADE;
        END IF;
    END IF;
END $$;

-- 4. (OPCIONAL) RECRIAR VIEW DE TELEFONES ATIVOS (drop se existir)
DROP VIEW IF EXISTS vw_telefones_ativos;
CREATE VIEW vw_telefones_ativos AS
SELECT 
    pt.pf_cpf,
    pt.pj_cnpj,
    t.ddd,
    t.numero,
    pt.tipo_linha,
    pt.source_system,
    pt.priority,
    pt.created_at AS data_associacao
FROM pessoa_telefone pt
JOIN telefone t ON t.id_telefone = pt.id_telefone
WHERE pt.deleted_at IS NULL 
  AND pt.valid_from <= NOW() 
  AND (pt.valid_to IS NULL OR pt.valid_to > NOW());
