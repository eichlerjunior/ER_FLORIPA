-- =====================================================================
-- 1. FUNÇÕES DE LIMPEZA
-- =====================================================================
CREATE OR REPLACE FUNCTION clean_numbers(p_text TEXT) 
RETURNS TEXT IMMUTABLE LANGUAGE plpgsql AS $$
BEGIN
    RETURN regexp_replace(p_text, '[^0-9]', '', 'g');
END;
$$;

CREATE OR REPLACE FUNCTION clean_cpf(p_text TEXT) 
RETURNS TEXT IMMUTABLE LANGUAGE plpgsql AS $$
DECLARE v_clean TEXT;
BEGIN
    v_clean := clean_numbers(p_text);
    RETURN CASE WHEN length(v_clean) = 11 THEN v_clean ELSE NULL END;
END;
$$;

CREATE OR REPLACE FUNCTION clean_cnpj(p_text TEXT) 
RETURNS TEXT IMMUTABLE LANGUAGE plpgsql AS $$
DECLARE v_clean TEXT;
BEGIN
    v_clean := clean_numbers(p_text);
    RETURN CASE WHEN length(v_clean) = 14 THEN v_clean ELSE NULL END;
END;
$$;

CREATE OR REPLACE FUNCTION clean_phone(p_text TEXT) 
RETURNS TEXT IMMUTABLE LANGUAGE plpgsql AS $$
DECLARE v_clean TEXT;
BEGIN
    v_clean := clean_numbers(p_text);
    RETURN CASE WHEN length(v_clean) IN (10, 11) THEN v_clean ELSE NULL END;
END;
$$;

CREATE OR REPLACE FUNCTION clean_cep(p_text TEXT) 
RETURNS TEXT IMMUTABLE LANGUAGE plpgsql AS $$
DECLARE v_clean TEXT;
BEGIN
    v_clean := clean_numbers(p_text);
    RETURN CASE WHEN length(v_clean) = 8 THEN v_clean ELSE NULL END;
END;
$$;

CREATE OR REPLACE FUNCTION clean_boolean(p_text TEXT) 
RETURNS BOOLEAN IMMUTABLE LANGUAGE plpgsql AS $$
BEGIN
    RETURN upper(trim(p_text)) IN ('S', 'SIM', 'TRUE', '1', 'YES', 'Y');
END;
$$;

CREATE OR REPLACE FUNCTION clean_decimal(p_text TEXT) 
RETURNS NUMERIC IMMUTABLE LANGUAGE plpgsql AS $$
DECLARE v_clean TEXT;
BEGIN
    IF p_text IS NULL OR trim(p_text) = '' THEN RETURN NULL; END IF;
    v_clean := regexp_replace(trim(p_text), '\.', '', 'g');
    v_clean := replace(v_clean, ',', '.');
    v_clean := regexp_replace(v_clean, '[^0-9.]', '', 'g');
    BEGIN
        RETURN v_clean::NUMERIC;
    EXCEPTION WHEN OTHERS THEN
        RETURN NULL;
    END;
END;
$$;

CREATE OR REPLACE FUNCTION clean_date(p_text TEXT) 
RETURNS DATE IMMUTABLE LANGUAGE plpgsql AS $$
BEGIN
    IF p_text IS NULL OR trim(p_text) = '' THEN RETURN NULL; END IF;
    RETURN p_text::DATE;
EXCEPTION WHEN OTHERS THEN
    RETURN NULL;
END;
$$;

-- =====================================================================
-- 2. TABELAS PRINCIPAIS
-- =====================================================================
DROP TABLE IF EXISTS pessoa_fisica CASCADE;
CREATE TABLE pessoa_fisica (
    cpf CHAR(11) PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    outro_nome VARCHAR(200),
    sexo CHAR(1),
    data_nasc DATE,
    signo VARCHAR(50),
    nome_mae VARCHAR(200),
    nome_pai VARCHAR(200),
    escolaridade VARCHAR(100),
    rg VARCHAR(20),
    uf_rg CHAR(2),
    emissor_rg VARCHAR(20),
    flag_obito BOOLEAN,
    data_obito DATE,
    ano_obito VARCHAR(4),
    flag_ppe BOOLEAN,
    cargo_ppe VARCHAR(100),
    flag_clt BOOLEAN,
    empregador_cnpj CHAR(14),
    empregador_nome VARCHAR(200),
    empregador_cnae VARCHAR(20),
    empregador_cnae_descricao VARCHAR(200),
    empregador_porte VARCHAR(50),
    data_admissao DATE,
    cbo VARCHAR(20),
    cbo_descricao VARCHAR(200),
    salario_valor NUMERIC(15,2),
    salario_faixa CHAR(1),
    salario_faixa_descricao VARCHAR(50),
    renda_estimada NUMERIC(15,2),
    renda_estimada_faixa CHAR(1),
    renda_estimada_faixa_descricao VARCHAR(50),
    flag_inss BOOLEAN,
    numero_beneficio VARCHAR(20),
    especie_beneficio VARCHAR(100),
    beneficio_valor NUMERIC(15,2),
    beneficio_faixa CHAR(1),
    beneficio_faixa_descricao VARCHAR(50),
    flag_socio_empresa BOOLEAN,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50) DEFAULT 'FPOLIS_PF',
    priority SMALLINT DEFAULT 1
);

DROP TABLE IF EXISTS pessoa_juridica CASCADE;
CREATE TABLE pessoa_juridica (
    cnpj CHAR(14) PRIMARY KEY,
    razao_social VARCHAR(200) NOT NULL,
    fantasia VARCHAR(200),
    situacao_cadastral VARCHAR(50),
    data_situacao_cadastral DATE,
    situacao_especial VARCHAR(50),
    data_situacao_especial DATE,
    cnae_principal VARCHAR(20),
    cnae_descricao VARCHAR(200),
    natureza_juridica VARCHAR(20),
    descricao_natureza_juridica VARCHAR(200),
    data_abertura DATE,
    num_funcionarios INTEGER,
    capital_social NUMERIC(15,2),
    porte_empresa VARCHAR(50),
    inscricao_estadual VARCHAR(30),
    regime_apuracao VARCHAR(50),
    faturamento_presumido NUMERIC(15,2),
    matriz BOOLEAN,
    tem_filial BOOLEAN,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50) DEFAULT 'FPOLIS_PJ',
    priority SMALLINT DEFAULT 1
);

-- =====================================================================
-- 3. TABELAS COMPARTILHADAS (ENDEREÇO, TELEFONE, EMAIL)
-- =====================================================================
DROP TABLE IF EXISTS endereco CASCADE;
CREATE TABLE endereco (
    id_endereco SERIAL PRIMARY KEY,
    tipo_logradouro VARCHAR(10),
    logradouro VARCHAR(200) NOT NULL,
    numero VARCHAR(20),
    complemento VARCHAR(100),
    bairro VARCHAR(100),
    cidade VARCHAR(100) NOT NULL,
    uf CHAR(2) NOT NULL,
    cep CHAR(8),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50),
    priority SMALLINT DEFAULT 1
);

DROP TABLE IF EXISTS telefone CASCADE;
CREATE TABLE telefone (
    id_telefone SERIAL PRIMARY KEY,
    ddd CHAR(2) NOT NULL,
    numero VARCHAR(9) NOT NULL,
    tipo VARCHAR(20) DEFAULT 'Fixo',
    UNIQUE(ddd, numero),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50),
    priority SMALLINT DEFAULT 1
);

DROP TABLE IF EXISTS email CASCADE;
CREATE TABLE email (
    id_email SERIAL PRIMARY KEY,
    endereco VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50),
    priority SMALLINT DEFAULT 1
);

-- =====================================================================
-- 4. TABELAS DE LIGAÇÃO (POLIMÓRFICAS)
-- =====================================================================
DROP TABLE IF EXISTS pessoa_endereco CASCADE;
CREATE TABLE pessoa_endereco (
    id SERIAL PRIMARY KEY,
    pf_cpf CHAR(11) REFERENCES pessoa_fisica(cpf) ON DELETE CASCADE,
    pj_cnpj CHAR(14) REFERENCES pessoa_juridica(cnpj) ON DELETE CASCADE,
    id_endereco INTEGER NOT NULL REFERENCES endereco(id_endereco),
    ordem SMALLINT,
    tipo_endereco VARCHAR(30),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50),
    priority SMALLINT DEFAULT 1,
    CONSTRAINT endereco_pertence_a_um CHECK (
        (pf_cpf IS NOT NULL AND pj_cnpj IS NULL) OR 
        (pf_cpf IS NULL AND pj_cnpj IS NOT NULL)
    )
);

DROP TABLE IF EXISTS pessoa_telefone CASCADE;
CREATE TABLE pessoa_telefone (
    id SERIAL PRIMARY KEY,
    pf_cpf CHAR(11) REFERENCES pessoa_fisica(cpf) ON DELETE CASCADE,
    pj_cnpj CHAR(14) REFERENCES pessoa_juridica(cnpj) ON DELETE CASCADE,
    id_telefone INTEGER NOT NULL REFERENCES telefone(id_telefone),
    ordem SMALLINT,
    tipo_uso VARCHAR(20),
    tipo_linha VARCHAR(20),
    valid_from TIMESTAMP DEFAULT NOW() NOT NULL,
    valid_to TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50),
    priority SMALLINT DEFAULT 1,
    CONSTRAINT telefone_pertence_a_um CHECK (
        (pf_cpf IS NOT NULL AND pj_cnpj IS NULL) OR 
        (pf_cpf IS NULL AND pj_cnpj IS NOT NULL)
    )
);

DROP TABLE IF EXISTS pessoa_email CASCADE;
CREATE TABLE pessoa_email (
    id SERIAL PRIMARY KEY,
    pf_cpf CHAR(11) REFERENCES pessoa_fisica(cpf) ON DELETE CASCADE,
    pj_cnpj CHAR(14) REFERENCES pessoa_juridica(cnpj) ON DELETE CASCADE,
    id_email INTEGER NOT NULL REFERENCES email(id_email),
    ordem SMALLINT,
    valid_from TIMESTAMP DEFAULT NOW() NOT NULL,
    valid_to TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50),
    priority SMALLINT DEFAULT 1,
    CONSTRAINT email_pertence_a_um CHECK (
        (pf_cpf IS NOT NULL AND pj_cnpj IS NULL) OR 
        (pf_cpf IS NULL AND pj_cnpj IS NOT NULL)
    )
);

-- =====================================================================
-- 5. TABELAS ESPECÍFICAS
-- =====================================================================
DROP TABLE IF EXISTS parentesco CASCADE;
CREATE TABLE parentesco (
    id SERIAL PRIMARY KEY,
    pf_cpf CHAR(11) NOT NULL REFERENCES pessoa_fisica(cpf) ON DELETE CASCADE,
    parente_documento VARCHAR(20),
    parente_nome VARCHAR(200),
    parentesco VARCHAR(50),
    parente_telefone1 VARCHAR(11),
    parente_telefone2 VARCHAR(11),
    parente_telefone3 VARCHAR(11),
    parente_telefone4 VARCHAR(11),
    ordem SMALLINT,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50) DEFAULT 'FPOLIS_PF',
    priority SMALLINT DEFAULT 1
);

DROP TABLE IF EXISTS socio_pj CASCADE;
CREATE TABLE socio_pj (
    id SERIAL PRIMARY KEY,
    pj_cnpj CHAR(14) NOT NULL REFERENCES pessoa_juridica(cnpj) ON DELETE CASCADE,
    documento VARCHAR(20),
    nome VARCHAR(200),
    cargo VARCHAR(100),
    participacao NUMERIC(10,2),
    data_entrada DATE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50) DEFAULT 'FPOLIS_PJ',
    priority SMALLINT DEFAULT 1
);

DROP TABLE IF EXISTS cnae_secundario CASCADE;
CREATE TABLE cnae_secundario (
    id SERIAL PRIMARY KEY,
    pj_cnpj CHAR(14) NOT NULL REFERENCES pessoa_juridica(cnpj) ON DELETE CASCADE,
    cnae_codigo VARCHAR(20),
    cnae_descricao VARCHAR(200),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50) DEFAULT 'FPOLIS_PJ',
    priority SMALLINT DEFAULT 1
);

-- =====================================================================
-- 6. TRIGGERS PARA UPDATED_AT
-- =====================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_pessoa_fisica_updated_at BEFORE UPDATE ON pessoa_fisica FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_pessoa_juridica_updated_at BEFORE UPDATE ON pessoa_juridica FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_endereco_updated_at BEFORE UPDATE ON endereco FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_telefone_updated_at BEFORE UPDATE ON telefone FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_email_updated_at BEFORE UPDATE ON email FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_pessoa_endereco_updated_at BEFORE UPDATE ON pessoa_endereco FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_pessoa_telefone_updated_at BEFORE UPDATE ON pessoa_telefone FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_pessoa_email_updated_at BEFORE UPDATE ON pessoa_email FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_parentesco_updated_at BEFORE UPDATE ON parentesco FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_socio_pj_updated_at BEFORE UPDATE ON socio_pj FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_cnae_secundario_updated_at BEFORE UPDATE ON cnae_secundario FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================================
-- 7. ÍNDICES
-- =====================================================================
CREATE INDEX idx_pf_cpf ON pessoa_fisica(cpf);
CREATE INDEX idx_pf_nome ON pessoa_fisica(nome);
CREATE INDEX idx_pj_cnpj ON pessoa_juridica(cnpj);
CREATE INDEX idx_pj_razao ON pessoa_juridica(razao_social);
CREATE INDEX idx_endereco_cidade ON endereco(cidade);
CREATE INDEX idx_endereco_uf ON endereco(uf);
CREATE INDEX idx_telefone_ddd_numero ON telefone(ddd, numero);
CREATE INDEX idx_email_endereco ON email(endereco);
CREATE INDEX idx_pe_pf ON pessoa_endereco(pf_cpf);
CREATE INDEX idx_pe_pj ON pessoa_endereco(pj_cnpj);
CREATE INDEX idx_pt_pf ON pessoa_telefone(pf_cpf);
CREATE INDEX idx_pt_pj ON pessoa_telefone(pj_cnpj);
CREATE INDEX idx_pemail_pf ON pessoa_email(pf_cpf);
CREATE INDEX idx_pemail_pj ON pessoa_email(pj_cnpj);
CREATE INDEX idx_parentesco_pf ON parentesco(pf_cpf);
CREATE INDEX idx_socio_pj ON socio_pj(pj_cnpj);
CREATE INDEX idx_cnae_pj ON cnae_secundario(pj_cnpj);
