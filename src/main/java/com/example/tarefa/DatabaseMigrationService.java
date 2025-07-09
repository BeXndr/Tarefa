package com.example.tarefa;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Service;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

@Service
public class DatabaseMigrationService implements CommandLineRunner {

    @Autowired
    private ConexaoBD conexaoBD;

    @Override
    public void run(String... args) throws Exception {
        System.out.println("🚀 Iniciando migrações automáticas do banco...");
        executarTodasMigracoes();
        System.out.println("✅ Migrações concluídas!");
    }

    public void executarTodasMigracoes() {
        criarTabelaControleVersao();
        
        List<Migração> migracoes = definirMigracoes();
        
        for (Migração migracao : migracoes) {
            if (!migracaoJaExecutada(migracao.versao)) {
                executarMigracao(migracao);
                registrarMigracao(migracao.versao, migracao.descricao);
            }
        }
    }

    private List<Migração> definirMigracoes() {
        List<Migração> migracoes = new ArrayList<>();
        
        // Migração 1: Tabela principal
        migracoes.add(new Migração("001", "Criar tabela tarefa", """
            CREATE TABLE IF NOT EXISTS tarefa (
                id SERIAL PRIMARY KEY,
                descricao VARCHAR(500) NOT NULL,
                data_criacao DATE NOT NULL,
                data_prevista DATE,
                data_encerramento DATE,
                situacao VARCHAR(50) NOT NULL CHECK (situacao IN ('Pendente', 'Em Andamento', 'Concluída', 'Cancelada'))
            );
            
            CREATE INDEX IF NOT EXISTS idx_tarefa_situacao ON tarefa(situacao);
            CREATE INDEX IF NOT EXISTS idx_tarefa_data_criacao ON tarefa(data_criacao);
            CREATE INDEX IF NOT EXISTS idx_tarefa_data_prevista ON tarefa(data_prevista);
            """));

        // Migração 2: Tabela de usuários
        migracoes.add(new Migração("002", "Criar tabela usuarios", """
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                nome VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                senha_hash VARCHAR(255) NOT NULL,
                ativo BOOLEAN DEFAULT true,
                data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                ultimo_login TIMESTAMP
            );
            """));
        
        migracoes.add(new Migração("003", "Criar tabela funcionarios", """
            CREATE TABLE IF NOT EXISTS funcionarios (
                id SERIAL PRIMARY KEY,
                nome VARCHAR(100) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                senha_hash VARCHAR(255) NOT NULL,
                ativo BOOLEAN DEFAULT true,
                data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                ultimo_login TIMESTAMP
            );
            """));

        return migracoes;
    }

    private void criarTabelaControleVersao() {
        String sql = """
            CREATE TABLE IF NOT EXISTS schema_migrations (
                versao VARCHAR(10) PRIMARY KEY,
                descricao VARCHAR(255),
                executada_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            """;
        
        try {
            Statement stmt = conexaoBD.getConnection().createStatement();
            stmt.executeUpdate(sql);
            System.out.println("✅ Tabela de controle de versão verificada");
        } catch (SQLException e) {
            System.err.println("❌ Erro ao criar tabela de controle: " + e.getMessage());
        }
    }

    private boolean migracaoJaExecutada(String versao) {
        String sql = "SELECT COUNT(*) FROM schema_migrations WHERE versao = ?";
        
        try {
            PreparedStatement stmt = conexaoBD.getConnection().prepareStatement(sql);
            stmt.setString(1, versao);
            ResultSet rs = stmt.executeQuery();
            
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            System.err.println("❌ Erro ao verificar migração: " + e.getMessage());
        }
        
        return false;
    }

    private void executarMigracao(Migração migracao) {
        try {
            System.out.println("🔄 Executando migração " + migracao.versao + ": " + migracao.descricao);
            
            Statement stmt = conexaoBD.getConnection().createStatement();
            
            // Dividir por comandos separados se necessário
            String[] comandos = migracao.sql.split(";");
            
            for (String comando : comandos) {
                comando = comando.trim();
                if (!comando.isEmpty()) {
                    stmt.executeUpdate(comando);
                }
            }
            
            System.out.println("✅ Migração " + migracao.versao + " executada com sucesso");
            
        } catch (SQLException e) {
            System.err.println("❌ Erro na migração " + migracao.versao + ": " + e.getMessage());
            throw new RuntimeException("Falha na migração " + migracao.versao, e);
        }
    }

    private void registrarMigracao(String versao, String descricao) {
        String sql = "INSERT INTO schema_migrations (versao, descricao) VALUES (?, ?)";
        
        try {
            PreparedStatement stmt = conexaoBD.getConnection().prepareStatement(sql);
            stmt.setString(1, versao);
            stmt.setString(2, descricao);
            stmt.executeUpdate();
            
        } catch (SQLException e) {
            System.err.println("❌ Erro ao registrar migração: " + e.getMessage());
        }
    }

    // Classe interna para representar uma migração
    private static class Migração {
        public final String versao;
        public final String descricao;
        public final String sql;

        public Migração(String versao, String descricao, String sql) {
            this.versao = versao;
            this.descricao = descricao;
            this.sql = sql;
        }
    }

    // Método público para executar migrações sob demanda
    public void executarMigracoesManual() {
        System.out.println("🔄 Executando migrações manuais...");
        executarTodasMigracoes();
    }

    // Método para verificar status das migrações
    public void verificarStatusMigracoes() {
        String sql = "SELECT versao, descricao, executada_em FROM schema_migrations ORDER BY versao";
        
        try {
            Statement stmt = conexaoBD.getConnection().createStatement();
            ResultSet rs = stmt.executeQuery(sql);
            
            System.out.println("📋 Status das migrações:");
            while (rs.next()) {
                System.out.println("  ✅ " + rs.getString("versao") + " - " + 
                                 rs.getString("descricao") + " (" + 
                                 rs.getTimestamp("executada_em") + ")");
            }
            
        } catch (SQLException e) {
            System.err.println("❌ Erro ao verificar status: " + e.getMessage());
        }
    }
}