-- =====================================================================
-- SCRIPT 06: ADICIONA HISTÓRICO DE GRAFIA (NOMES E RAZÕES SOCIAIS)
-- =====================================================================

-- 1. Histórico de nomes para PF
CREATE TABLE IF NOT EXISTS pessoa_fisica_nome_historico (
    id SERIAL PRIMARY KEY,
    cpf CHAR(11) NOT NULL REFERENCES pessoa_fisica(cpf) ON DELETE CASCADE,
    nome VARCHAR(200) NOT NULL,
    valid_from TIMESTAMP DEFAULT NOW() NOT NULL,
    valid_to TIMESTAMP,
    source_system VARCHAR(50),
    priority SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
);

-- 2. Histórico de razões sociais para PJ
CREATE TABLE IF NOT EXISTS pessoa_juridica_razao_historico (
    id SERIAL PRIMARY KEY,
    cnpj CHAR(14) NOT NULL REFERENCES pessoa_juridica(cnpj) ON DELETE CASCADE,
    razao_social VARCHAR(200) NOT NULL,
    valid_from TIMESTAMP DEFAULT NOW() NOT NULL,
    valid_to TIMESTAMP,
    source_system VARCHAR(50),
    priority SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
);

-- 3. Triggers de updated_at
CREATE TRIGGER trg_pf_nome_historico_updated_at
BEFORE UPDATE ON pessoa_fisica_nome_historico
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_pj_razao_historico_updated_at
BEFORE UPDATE ON pessoa_juridica_razao_historico
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. Índices
CREATE INDEX idx_pf_nome_historico_cpf ON pessoa_fisica_nome_historico(cpf);
CREATE INDEX idx_pf_nome_historico_valid_from ON pessoa_fisica_nome_historico(valid_from);
CREATE INDEX idx_pj_razao_historico_cnpj ON pessoa_juridica_razao_historico(cnpj);
CREATE INDEX idx_pj_razao_historico_valid_from ON pessoa_juridica_razao_historico(valid_from);
