CREATE TABLE IF NOT EXISTS tipo_relacao (
    id_tipo_relacao SERIAL PRIMARY KEY,
    nome VARCHAR(30) NOT NULL UNIQUE,
    descricao VARCHAR(100),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
);

INSERT INTO tipo_relacao (nome, descricao) VALUES
('Proprietario', 'Titular do número/endereço/email'),
('Empresa', 'Vínculo profissional/empresarial'),
('Parente', 'Familiar'),
('Recado', 'Número para recados'),
('Referencia', 'Referência comercial ou bancária'),
('Outro', 'Outros vínculos não categorizados'),
('Desconhecido', 'Não foi possível determinar a relação')
ON CONFLICT (nome) DO NOTHING;

ALTER TABLE pessoa_telefone ADD COLUMN IF NOT EXISTS id_tipo_relacao INTEGER REFERENCES tipo_relacao(id_tipo_relacao);
ALTER TABLE pessoa_endereco ADD COLUMN IF NOT EXISTS id_tipo_relacao INTEGER REFERENCES tipo_relacao(id_tipo_relacao);
ALTER TABLE pessoa_email ADD COLUMN IF NOT EXISTS id_tipo_relacao INTEGER REFERENCES tipo_relacao(id_tipo_relacao);

DO $$ 
DECLARE v_id_desconhecido INT;
BEGIN
    SELECT id_tipo_relacao INTO v_id_desconhecido FROM tipo_relacao WHERE nome = 'Desconhecido';
    UPDATE pessoa_telefone SET id_tipo_relacao = v_id_desconhecido WHERE id_tipo_relacao IS NULL;
    UPDATE pessoa_endereco SET id_tipo_relacao = v_id_desconhecido WHERE id_tipo_relacao IS NULL;
    UPDATE pessoa_email SET id_tipo_relacao = v_id_desconhecido WHERE id_tipo_relacao IS NULL;
    ALTER TABLE pessoa_telefone ALTER COLUMN id_tipo_relacao SET NOT NULL;
    ALTER TABLE pessoa_endereco ALTER COLUMN id_tipo_relacao SET NOT NULL;
    ALTER TABLE pessoa_email ALTER COLUMN id_tipo_relacao SET NOT NULL;
END $$;

CREATE TRIGGER trg_tipo_relacao_updated_at BEFORE UPDATE ON tipo_relacao FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
