CREATE TABLE IF NOT EXISTS midia_social (
    id_midia SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao VARCHAR(200),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50) DEFAULT 'SISTEMA',
    priority SMALLINT DEFAULT 1
);

INSERT INTO midia_social (nome, descricao, source_system) VALUES
('WhatsApp', 'Aplicativo de mensagens instantâneas', 'SISTEMA'),
('Telegram', 'Aplicativo de mensagens com foco em privacidade', 'SISTEMA'),
('Instagram', 'Rede social de fotos e vídeos', 'SISTEMA'),
('Facebook', 'Rede social geral', 'SISTEMA'),
('LinkedIn', 'Rede social profissional', 'SISTEMA'),
('Twitter/X', 'Microblogging', 'SISTEMA'),
('TikTok', 'Vídeos curtos', 'SISTEMA'),
('Signal', 'Aplicativo de mensagens seguro', 'SISTEMA'),
('WeChat', 'Aplicativo chinês de mensagens', 'SISTEMA'),
('Outro', 'Outras plataformas não listadas', 'SISTEMA')
ON CONFLICT (nome) DO NOTHING;

CREATE TABLE IF NOT EXISTS telefone_midia (
    id SERIAL PRIMARY KEY,
    id_telefone INTEGER NOT NULL REFERENCES telefone(id_telefone) ON DELETE CASCADE,
    id_midia INTEGER NOT NULL REFERENCES midia_social(id_midia) ON DELETE RESTRICT,
    identificador VARCHAR(100),
    principal BOOLEAN DEFAULT FALSE,
    valid_from TIMESTAMP DEFAULT NOW() NOT NULL,
    valid_to TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50) DEFAULT 'SISTEMA',
    priority SMALLINT DEFAULT 1,
    UNIQUE(id_telefone, id_midia)
);

CREATE TABLE IF NOT EXISTS email_midia (
    id SERIAL PRIMARY KEY,
    id_email INTEGER NOT NULL REFERENCES email(id_email) ON DELETE CASCADE,
    id_midia INTEGER NOT NULL REFERENCES midia_social(id_midia) ON DELETE RESTRICT,
    identificador VARCHAR(100),
    principal BOOLEAN DEFAULT FALSE,
    valid_from TIMESTAMP DEFAULT NOW() NOT NULL,
    valid_to TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP,
    source_system VARCHAR(50) DEFAULT 'SISTEMA',
    priority SMALLINT DEFAULT 1,
    UNIQUE(id_email, id_midia)
);

CREATE TRIGGER trg_midia_social_updated_at BEFORE UPDATE ON midia_social FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_telefone_midia_updated_at BEFORE UPDATE ON telefone_midia FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_email_midia_updated_at BEFORE UPDATE ON email_midia FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_telefone_midia_id_telefone ON telefone_midia(id_telefone);
CREATE INDEX idx_telefone_midia_id_midia ON telefone_midia(id_midia);
CREATE INDEX idx_email_midia_id_email ON email_midia(id_email);
CREATE INDEX idx_email_midia_id_midia ON email_midia(id_midia);
