package com.example.tarefa;

import java.sql.*;

public class ConexaoBD {

    private static ConexaoBD instancia = null;
    private Connection conexao = null;
    
    private static final String DB_DRIVER = "org.postgresql.Driver";
    private static final String DB_URL = "jdbc:postgresql://localhost:5432/tarefa";
    private static final String DB_USER = "postgres";
    private static final String DB_SENHA = "postgres";

    public ConexaoBD() {
        try {
            // Carrega Driver do Banco de Dados
            Class.forName(DB_DRIVER);

            if (DB_USER.length() != 0) // conexão COM usuário e senha
            {
                conexao = DriverManager.getConnection(DB_URL, DB_USER, DB_SENHA);
            } else // conexão SEM usuário e senha
            {
                conexao = DriverManager.getConnection(DB_URL);
            }

        } catch (Exception e) {
            System.err.println(e);
        }
    }

    // Retorna instância
    public static ConexaoBD getInstance() {
        if (instancia == null) {
            instancia = new ConexaoBD();
        }
        return instancia;
    }

    // Retorna conexão
    public Connection getConnection() {
        if (conexao == null) {
            throw new RuntimeException("conexao==null");
        }
        return conexao;
    }

    // Efetua fechamento da conexão
    public void shutDown() {
        try {
            conexao.close();
            instancia = null;
            conexao = null;
        } catch (Exception e) {
            System.err.println(e);
        }
    }
}