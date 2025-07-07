-- ============================================
-- MIGRAÇÕES DE BANCO DE DADOS
-- ============================================
-- Este arquivo contém apenas mudanças ESTRUTURAIS
-- NÃO adicione INSERT/UPDATE de dados aqui
-- Os dados existentes são preservados

-- ============================================
-- NOVA TABELA: Usuários
-- ============================================

CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    ativo BOOLEAN DEFAULT true,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ultimo_login TIMESTAMP
);

-- Comentários na nova tabela
COMMENT ON TABLE usuarios IS 'Tabela de usuários do sistema';
COMMENT ON COLUMN usuarios.id IS 'Identificador único do usuário';
COMMENT ON COLUMN usuarios.nome IS 'Nome completo do usuário';
COMMENT ON COLUMN usuarios.email IS 'Email do usuário (login)';
COMMENT ON COLUMN usuarios.senha_hash IS 'Senha criptografada';

-- ============================================
-- VERIFICAÇÃO FINAL
-- ============================================

-- Mostrar confirmação
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'usuarios') THEN
        RAISE NOTICE '✅ Tabela usuarios criada com sucesso';
    ELSE
        RAISE NOTICE '❌ Erro ao criar tabela usuarios';
    END IF;
END $$;