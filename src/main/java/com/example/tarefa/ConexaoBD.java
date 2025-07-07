package com.example.tarefa;

import java.sql.*;

public class ConexaoBD {

    private static ConexaoBD instancia = null;
    private Connection conexao = null;
    
    
    private static final String DB_DRIVER = "org.postgresql.Driver";
    
    // Configurações usando variáveis de ambiente (para Docker) com fallback para desenvolvimento local
    private static final String DB_URL = System.getenv("DATABASE_URL") != null 
        ? System.getenv("DATABASE_URL") 
        : "jdbc:postgresql://localhost:5432/tarefa";
    
    private static final String DB_USER = System.getenv("DATABASE_USERNAME") != null 
        ? System.getenv("DATABASE_USERNAME") 
        : "postgres";
    
    private static final String DB_SENHA = System.getenv("DATABASE_PASSWORD") != null 
        ? System.getenv("DATABASE_PASSWORD") 
        : "postgres";

    public ConexaoBD() {
        try {
            // Log das configurações (sem mostrar senha)
            System.out.println("Adicionando um print pra ver se muda");
            System.out.println("🔗 Conectando ao banco de dados:");
            System.out.println("   URL: " + DB_URL);
            System.out.println("   Usuário: " + DB_USER);
            System.out.println("   Driver: " + DB_DRIVER);
            
            // Carrega Driver do Banco de Dados
            Class.forName(DB_DRIVER);

            if (DB_USER.length() != 0) {
                // Conexão COM usuário e senha
                conexao = DriverManager.getConnection(DB_URL, DB_USER, DB_SENHA);
                System.out.println("✅ Conexão com banco estabelecida com sucesso!");
            } else {
                // Conexão SEM usuário e senha
                conexao = DriverManager.getConnection(DB_URL);
                System.out.println("✅ Conexão com banco estabelecida (sem autenticação)!");
            }

            // Testar a conexão
            if (conexao != null && !conexao.isClosed()) {
                System.out.println("🚀 Banco de dados pronto para uso!");
            }

        } catch (ClassNotFoundException e) {
            System.err.println("❌ Driver PostgreSQL não encontrado: " + e.getMessage());
            System.err.println("💡 Certifique-se de que o driver PostgreSQL está no classpath");
        } catch (SQLException e) {
            System.err.println("❌ Erro ao conectar com o banco de dados: " + e.getMessage());
            System.err.println("💡 Verifique se o PostgreSQL está rodando e as credenciais estão corretas");
            System.err.println("   URL: " + DB_URL);
            System.err.println("   Usuário: " + DB_USER);
        } catch (Exception e) {
            System.err.println("❌ Erro inesperado: " + e.getMessage());
            e.printStackTrace();
        }
    }

    // Retorna instância (Singleton)
    public static ConexaoBD getInstance() {
        if (instancia == null) {
            instancia = new ConexaoBD();
        }
        return instancia;
    }

    // Retorna conexão
    public Connection getConnection() {
        try {
            // Verificar se a conexão ainda está válida
            if (conexao == null || conexao.isClosed()) {
                System.out.println("🔄 Reconectando ao banco de dados...");
                instancia = new ConexaoBD();
                return instancia.conexao;
            }
            return conexao;
        } catch (SQLException e) {
            System.err.println("❌ Erro ao verificar conexão: " + e.getMessage());
            throw new RuntimeException("Falha na conexão com banco de dados", e);
        }
    }

    // Efetua fechamento da conexão
    public void shutDown() {
        try {
            if (conexao != null && !conexao.isClosed()) {
                conexao.close();
                System.out.println("🔌 Conexão com banco fechada");
            }
            instancia = null;
            conexao = null;
        } catch (SQLException e) {
            System.err.println("❌ Erro ao fechar conexão: " + e.getMessage());
        }
    }
    
    // Método para testar conectividade
    public boolean testarConexao() {
        try {
            Connection conn = getConnection();
            if (conn != null && !conn.isClosed()) {
                // Executar uma query simples para testar
                Statement stmt = conn.createStatement();
                ResultSet rs = stmt.executeQuery("SELECT 1");
                boolean sucesso = rs.next();
                rs.close();
                stmt.close();
                return sucesso;
            }
            return false;
        } catch (SQLException e) {
            System.err.println("❌ Teste de conexão falhou: " + e.getMessage());
            return false;
        }
    }
}