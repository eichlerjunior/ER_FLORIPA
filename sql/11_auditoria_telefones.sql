-- ============================================================
-- AUDITORIA PARA TELEFONES E VÍNCULOS
-- ============================================================

CREATE TABLE IF NOT EXISTS auditoria_telefone (
    id_auditoria SERIAL PRIMARY KEY,
    tabela_afetada VARCHAR(30), -- 'telefone' ou 'pessoa_telefone'
    operacao VARCHAR(10),       -- 'INSERT', 'UPDATE', 'DELETE'
    id_registro INTEGER,        -- id_telefone ou id da pessoa_telefone
    dados_anteriores JSONB,
    dados_novos JSONB,
    usuario VARCHAR(50) DEFAULT current_user,
    data_hora TIMESTAMP DEFAULT NOW()
);

-- Função trigger para capturar mudanças em telefone
CREATE OR REPLACE FUNCTION auditoria_telefone_trg()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria_telefone (tabela_afetada, operacao, id_registro, dados_novos)
        VALUES (TG_TABLE_NAME, 'INSERT', NEW.id_telefone, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria_telefone (tabela_afetada, operacao, id_registro, dados_anteriores, dados_novos)
        VALUES (TG_TABLE_NAME, 'UPDATE', NEW.id_telefone, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria_telefone (tabela_afetada, operacao, id_registro, dados_anteriores)
        VALUES (TG_TABLE_NAME, 'DELETE', OLD.id_telefone, to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

-- Aplicar trigger na tabela telefone
CREATE TRIGGER trg_auditoria_telefone
AFTER INSERT OR UPDATE OR DELETE ON telefone
FOR EACH ROW EXECUTE FUNCTION auditoria_telefone_trg();

-- Aplicar trigger na tabela pessoa_telefone (adaptada para registrar o id da relação)
CREATE OR REPLACE FUNCTION auditoria_pessoa_telefone_trg()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO auditoria_telefone (tabela_afetada, operacao, id_registro, dados_novos)
        VALUES ('pessoa_telefone', 'INSERT', NEW.id, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO auditoria_telefone (tabela_afetada, operacao, id_registro, dados_anteriores, dados_novos)
        VALUES ('pessoa_telefone', 'UPDATE', NEW.id, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO auditoria_telefone (tabela_afetada, operacao, id_registro, dados_anteriores)
        VALUES ('pessoa_telefone', 'DELETE', OLD.id, to_jsonb(OLD));
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_auditoria_pessoa_telefone
AFTER INSERT OR UPDATE OR DELETE ON pessoa_telefone
FOR EACH ROW EXECUTE FUNCTION auditoria_pessoa_telefone_trg();

-- (Opcional) Criar uma view para consultar auditoria de forma amigável
CREATE OR REPLACE VIEW vw_auditoria_telefone AS
SELECT 
    a.data_hora,
    a.usuario,
    a.tabela_afetada,
    a.operacao,
    a.id_registro,
    CASE 
        WHEN a.tabela_afetada = 'telefone' THEN 
            (SELECT ddd || numero FROM telefone WHERE id_telefone = a.id_registro)
        ELSE 
            (SELECT pf_cpf || ' - ' || (SELECT ddd || numero FROM telefone WHERE id_telefone = pt.id_telefone)
             FROM pessoa_telefone pt WHERE pt.id = a.id_registro)
    END AS identificador,
    a.dados_anteriores,
    a.dados_novos
FROM auditoria_telefone a
ORDER BY a.data_hora DESC;