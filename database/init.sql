-- Script de inicialização do banco de dados
-- Criar tabela de tarefas

CREATE TABLE IF NOT EXISTS tarefa (
    id SERIAL PRIMARY KEY,
    descricao VARCHAR(500) NOT NULL,
    data_criacao DATE NOT NULL,
    data_prevista DATE,
    data_encerramento DATE,
    situacao VARCHAR(50) NOT NULL CHECK (situacao IN ('Pendente', 'Em Andamento', 'Concluída', 'Cancelada'))
);

-- Inserir dados de exemplo (apenas para desenvolvimento e teste)
INSERT INTO tarefa (descricao, data_criacao, data_prevista, situacao) VALUES
('Configurar ambiente Docker', CURRENT_DATE - INTERVAL '2 days', CURRENT_DATE + INTERVAL '3 days', 'Em Andamento'),
('Implementar testes unitários', CURRENT_DATE - INTERVAL '1 day', CURRENT_DATE + INTERVAL '5 days', 'Pendente'),
('Deploy da aplicação', CURRENT_DATE, CURRENT_DATE + INTERVAL '7 days', 'Pendente'),
('Documentar API', CURRENT_DATE - INTERVAL '3 days', CURRENT_DATE - INTERVAL '1 day', 'Concluída');

-- Criar índices para melhor performance
CREATE INDEX IF NOT EXISTS idx_tarefa_situacao ON tarefa(situacao);
CREATE INDEX IF NOT EXISTS idx_tarefa_data_criacao ON tarefa(data_criacao);
CREATE INDEX IF NOT EXISTS idx_tarefa_data_prevista ON tarefa(data_prevista);

-- Comentários nas colunas
COMMENT ON TABLE tarefa IS 'Tabela principal para armazenar tarefas do sistema';
COMMENT ON COLUMN tarefa.id IS 'Identificador único da tarefa';
COMMENT ON COLUMN tarefa.descricao IS 'Descrição detalhada da tarefa';
COMMENT ON COLUMN tarefa.data_criacao IS 'Data em que a tarefa foi criada';
COMMENT ON COLUMN tarefa.data_prevista IS 'Data prevista para conclusão da tarefa';
COMMENT ON COLUMN tarefa.data_encerramento IS 'Data em que a tarefa foi finalizada';
COMMENT ON COLUMN tarefa.situacao IS 'Situação atual da tarefa';