-- ============================================================
-- ESTRUTURA PARA OPERADORAS E HIERARQUIA
-- ============================================================

-- 1. Operadoras com rede própria (detentoras de espectro)
CREATE TABLE IF NOT EXISTS operadora_rede (
    id_operadora_rede SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    codigo_anatel VARCHAR(10),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Inserir as principais redes
INSERT INTO operadora_rede (nome, codigo_anatel) VALUES
('Vivo', '15'),
('Claro', '21'),
('TIM', '41'),
('Algar Telecom', '12'),
('Sercomtel', '43'),
('Oi', '31')  -- ainda relevante para fixo e alguns móveis
ON CONFLICT (nome) DO NOTHING;

-- 2. Operadoras Móveis Virtuais (MVNOs) e provedores SCM
CREATE TABLE IF NOT EXISTS operadora_mvno (
    id_operadora_mvno SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL UNIQUE,
    id_operadora_rede INTEGER REFERENCES operadora_rede(id_operadora_rede),
    tipo VARCHAR(20) DEFAULT 'MVNO', -- 'MVNO_Autorizada', 'MVNO_Credenciada', 'Provedor_SCM'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
);

-- Inserir as principais MVNOs e provedores (incluindo as que você mencionou)
INSERT INTO operadora_mvno (nome, id_operadora_rede, tipo) VALUES
('Surf Telecom', (SELECT id_operadora_rede FROM operadora_rede WHERE nome='TIM'), 'MVNO_Autorizada'),
('Telecall', (SELECT id_operadora_rede FROM operadora_rede WHERE nome='Vivo'), 'MVNO_Autorizada'),
('Vero', (SELECT id_operadora_rede FROM operadora_rede WHERE nome='TIM'), 'MVNO_Autorizada'),
('Nuh! Digital', (SELECT id_operadora_rede FROM operadora_rede WHERE nome='Claro'), 'MVNO_Autorizada'),
('Unifique', (SELECT id_operadora_rede FROM operadora_rede WHERE nome='TIM'), 'MVNO_Autorizada'),
('Correios Celular', NULL, 'MVNO_Credenciada'),  -- não mapeamos rede exata
('NuCel (Nubank)', NULL, 'MVNO_Credenciada'),
('Inter Telecom', NULL, 'MVNO_Credenciada'),
('Brisanet', NULL, 'Provedor_SCM'),
('Brasil TecPar', NULL, 'Provedor_SCM'),
('Giga Mais Fibra', NULL, 'Provedor_SCM'),
('Orbitel Telecom', NULL, 'Provedor_SCM'),
('Outras MVNOs', NULL, 'MVNO_Credenciada'),
('Outros Provedores SCM', NULL, 'Provedor_SCM')
ON CONFLICT (nome) DO NOTHING;

-- 3. Tabela de sinônimos para mapear nomes variantes nos dados de origem
CREATE TABLE IF NOT EXISTS operadora_sinonimo (
    id_sinonimo SERIAL PRIMARY KEY,
    id_operadora_rede INTEGER REFERENCES operadora_rede(id_operadora_rede),
    id_operadora_mvno INTEGER REFERENCES operadora_mvno(id_operadora_mvno),
    nome_origem VARCHAR(100) NOT NULL UNIQUE,  -- nome como aparece na origem
    created_at TIMESTAMP DEFAULT NOW()
);

-- Inserir sinônimos comuns (ex: 'VIVO', 'Telefônica', etc.)
INSERT INTO operadora_sinonimo (id_operadora_rede, nome_origem) VALUES
((SELECT id_operadora_rede FROM operadora_rede WHERE nome='Vivo'), 'VIVO'),
((SELECT id_operadora_rede FROM operadora_rede WHERE nome='Vivo'), 'Telefônica'),
((SELECT id_operadora_rede FROM operadora_rede WHERE nome='Claro'), 'CLARO'),
((SELECT id_operadora_rede FROM operadora_rede WHERE nome='TIM'), 'TIM'),
((SELECT id_operadora_rede FROM operadora_rede WHERE nome='Algar Telecom'), 'ALGAR'),
((SELECT id_operadora_rede FROM operadora_rede WHERE nome='Sercomtel'), 'SERCOMTEL'),
((SELECT id_operadora_rede FROM operadora_rede WHERE nome='Oi'), 'OI')
ON CONFLICT (nome_origem) DO NOTHING;

-- Também podemos mapear sinônimos para MVNOs
INSERT INTO operadora_sinonimo (id_operadora_mvno, nome_origem) VALUES
((SELECT id_operadora_mvno FROM operadora_mvno WHERE nome='Vero'), 'VERO'),
((SELECT id_operadora_mvno FROM operadora_mvno WHERE nome='Surf Telecom'), 'SURF'),
((SELECT id_operadora_mvno FROM operadora_mvno WHERE nome='Telecall'), 'TELECALL')
ON CONFLICT (nome_origem) DO NOTHING;

-- 4. Adicionar coluna na tabela telefone para referenciar a operadora (via MVNO ou Rede)
ALTER TABLE telefone ADD COLUMN IF NOT EXISTS id_operadora_rede INTEGER REFERENCES operadora_rede(id_operadora_rede);
ALTER TABLE telefone ADD COLUMN IF NOT EXISTS id_operadora_mvno INTEGER REFERENCES operadora_mvno(id_operadora_mvno);

-- 5. Criar índices e triggers (se ainda não existirem)
CREATE INDEX IF NOT EXISTS idx_telefone_operadora_rede ON telefone(id_operadora_rede);
CREATE INDEX IF NOT EXISTS idx_telefone_operadora_mvno ON telefone(id_operadora_mvno);

-- Trigger para updated_at (já existe, mas garantimos)
CREATE TRIGGER trg_operadora_rede_updated_at BEFORE UPDATE ON operadora_rede FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_operadora_mvno_updated_at BEFORE UPDATE ON operadora_mvno FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();