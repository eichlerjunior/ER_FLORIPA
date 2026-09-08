-- ============================================================
-- QUALIFICAÇÃO DE IMÓVEIS (TIPO DE USO, ÁREA, ESTRUTURA)
-- ============================================================

-- 1. Tabela de domínio para tipos de imóvel
CREATE TABLE IF NOT EXISTS tipo_imovel (
    id_tipo_imovel SERIAL PRIMARY KEY,
    nome VARCHAR(50) NOT NULL UNIQUE,
    descricao VARCHAR(255),
    categoria VARCHAR(20)
);

INSERT INTO tipo_imovel (nome, descricao, categoria) VALUES
('Unifamiliar', 'Edificação destinada a uma única unidade habitacional.', 'Residencial'),
('Multifamiliar', 'Edificação destinada a duas ou mais unidades habitacionais.', 'Residencial'),
('Misto Residencial', 'Uso residencial combinado com comércio ou serviços.', 'Misto'),
('Comercial Varejista', 'Estabelecimento destinado à venda direta ao consumidor final.', 'Comercial'),
('Comercial Atacadista', 'Estabelecimento destinado à venda para intermediários.', 'Comercial'),
('Serviços de Gestão', 'Atividades-meio (gerencial, técnica, burocrática) para organizações.', 'Comercial'),
('Serviços de Atendimento', 'Atividades-fim, voltadas diretamente aos clientes.', 'Comercial'),
('Serviços de Equipamentos', 'Sistemas técnicos de suporte a assentamentos humanos.', 'Comercial'),
('Hotel e Motel', 'Estabelecimento de hospedagem.', 'Comercial'),
('Industrial Extrativista', 'Retirada da natureza de matéria-prima.', 'Industrial'),
('Industrial de Transformação', 'Alteração da matéria-prima por processos tecnológicos.', 'Industrial'),
('Galpão Industrial', 'Edificação para armazenagem ou produção industrial.', 'Industrial'),
('Rural Agropecuário', 'Atividades de cultivo da terra e criação de animais.', 'Rural'),
('Rural Extrativista', 'Extração de recursos vegetais e/ou minerais.', 'Rural'),
('Rural de Turismo', 'Atividades rurais e de turismo sustentável.', 'Rural'),
('Institucional', 'Equipamentos públicos de educação, saúde, segurança, lazer, etc.', 'Institucional'),
('Religioso', 'Templos e espaços para cultos religiosos.', 'Institucional'),
('Comunitário', 'Espaços destinados a lazer, cultura e assistência social.', 'Institucional'),
('Terreno / Lote Vago', 'Terreno sem edificação.', 'Outros'),
('Vaga de Garagem', 'Espaço para estacionamento.', 'Outros'),
('Espaço Aberto de Lazer', 'Parques, praças e áreas de recreação.', 'Outros'),
('Espaço Aberto de Conservação', 'Áreas de proteção ambiental.', 'Outros')
ON CONFLICT (nome) DO NOTHING;

-- 2. Evolução da tabela endereco
ALTER TABLE endereco ADD COLUMN IF NOT EXISTS id_tipo_imovel INTEGER REFERENCES tipo_imovel(id_tipo_imovel);
ALTER TABLE endereco ADD COLUMN IF NOT EXISTS finalidade_uso VARCHAR(100);
ALTER TABLE endereco ADD COLUMN IF NOT EXISTS descricao_adicional TEXT;
ALTER TABLE endereco ADD COLUMN IF NOT EXISTS area_terreno NUMERIC(15,2);
ALTER TABLE endereco ADD COLUMN IF NOT EXISTS area_construida NUMERIC(15,2);
ALTER TABLE endereco ADD COLUMN IF NOT EXISTS numero_pavimentos SMALLINT;
ALTER TABLE endereco ADD COLUMN IF NOT EXISTS posicao_imovel VARCHAR(20);
ALTER TABLE endereco ADD COLUMN IF NOT EXISTS estado_conservacao VARCHAR(20);
ALTER TABLE endereco ADD COLUMN IF NOT EXISTS possui_garagem BOOLEAN;
ALTER TABLE endereco ADD COLUMN IF NOT EXISTS possui_elevador BOOLEAN;
ALTER TABLE endereco ADD COLUMN IF NOT EXISTS possui_portaria BOOLEAN;

CREATE INDEX IF NOT EXISTS idx_endereco_tipo_imovel ON endereco(id_tipo_imovel);

-- 3. Trigger para updated_at na tabela tipo_imovel
CREATE TRIGGER trg_tipo_imovel_updated_at
BEFORE UPDATE ON tipo_imovel
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. Classificação inicial automática (exemplo: residencial vs comercial)
-- Aqui você pode adicionar regras para preencher id_tipo_imovel baseado em dados existentes
-- Exemplo: se o endereço tem vínculo com PJ, marcar como comercial
UPDATE endereco e
SET id_tipo_imovel = (SELECT id_tipo_imovel FROM tipo_imovel WHERE nome = 'Comercial Varejista')
WHERE EXISTS (
    SELECT 1 FROM pessoa_endereco pe
    JOIN pessoa_juridica pj ON pj.cnpj = pe.pj_cnpj
    WHERE pe.id_endereco = e.id_endereco
    AND pe.pj_cnpj IS NOT NULL
)
AND id_tipo_imovel IS NULL;

-- Se não tiver vínculo com PJ, marcar como residencial (Unifamiliar)
UPDATE endereco e
SET id_tipo_imovel = (SELECT id_tipo_imovel FROM tipo_imovel WHERE nome = 'Unifamiliar')
WHERE id_tipo_imovel IS NULL
AND EXISTS (
    SELECT 1 FROM pessoa_endereco pe
    WHERE pe.id_endereco = e.id_endereco
    AND pe.pf_cpf IS NOT NULL
);

-- 5. Consulta de exemplo: distribuição dos tipos de imóvel
SELECT ti.nome, COUNT(*) AS total
FROM endereco e
JOIN tipo_imovel ti ON ti.id_tipo_imovel = e.id_tipo_imovel
GROUP BY ti.nome
ORDER BY total DESC;
