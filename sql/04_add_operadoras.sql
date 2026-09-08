CREATE TABLE IF NOT EXISTS operadora (
    id_operadora SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    codigo_anatel VARCHAR(10),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
);

INSERT INTO operadora (nome, codigo_anatel) VALUES
('Vivo', '15'), ('Claro', '21'), ('Tim', '41'), ('Oi', '31'),
('Nextel', '99'), ('Algar', '12'), ('Sercomtel', '43'), ('Outra', NULL)
ON CONFLICT (nome) DO NOTHING;

CREATE TABLE IF NOT EXISTS telefone_operadora (
    id SERIAL PRIMARY KEY,
    id_telefone INTEGER NOT NULL REFERENCES telefone(id_telefone) ON DELETE CASCADE,
    id_operadora INTEGER NOT NULL REFERENCES operadora(id_operadora),
    valid_from TIMESTAMP DEFAULT NOW() NOT NULL,
    valid_to TIMESTAMP,
    source_system VARCHAR(50),
    priority SMALLINT DEFAULT 1,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE TRIGGER trg_operadora_updated_at BEFORE UPDATE ON operadora FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_telefone_operadora_updated_at BEFORE UPDATE ON telefone_operadora FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX idx_telefone_operadora_id_telefone ON telefone_operadora(id_telefone);
CREATE INDEX idx_telefone_operadora_id_operadora ON telefone_operadora(id_operadora);

CREATE OR REPLACE VIEW vw_telefone_operadora_atual AS
SELECT 
    t.id_telefone,
    t.ddd,
    t.numero,
    o.nome AS operadora_atual,
    to_hist.valid_from AS desde,
    to_hist.source_system,
    to_hist.priority
FROM telefone t
LEFT JOIN telefone_operadora to_hist ON to_hist.id_telefone = t.id_telefone
    AND to_hist.deleted_at IS NULL
    AND to_hist.valid_from <= NOW()
    AND (to_hist.valid_to IS NULL OR to_hist.valid_to > NOW())
LEFT JOIN operadora o ON o.id_operadora = to_hist.id_operadora;
