package com.example.tarefa;

import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;

public class Tarefa {

    private int id;
    private String descricao;
    private String data_criacao;
    private String data_prevista;
    private String data_encerramento;
    private String situacao;

    public Tarefa(int id, String descricao, String data_criacao, String data_prevista, String data_encerramento, String situacao) {
        this.id = id;
        this.descricao = descricao;
        this.data_criacao = data_criacao;
        this.data_prevista = data_prevista;
        this.data_encerramento = data_encerramento;
        this.situacao = situacao;
    }

    public Tarefa() {
    }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getDescricao() {
        return descricao;
    }

    public void setDescricao(String descricao) {
        this.descricao = descricao;
    }

    public String getData_criacao() {
        return data_criacao;
    }

    public void setData_criacao(String data_criacao) {
        this.data_criacao = data_criacao;
    }

    public String getData_prevista() {
        return data_prevista;
    }

    public void setData_prevista(String data_prevista) {
        this.data_prevista = data_prevista;
    }

    public String getData_encerramento() {
        return data_encerramento;
    }

    public void setData_encerramento(String data_encerramento) {
        this.data_encerramento = data_encerramento;
    }

    public String getSituacao() {
        return situacao;
    }

    public void setSituacao(String situacao) {
        this.situacao = situacao;
    }

    public boolean salvar(Tarefa tarefa) {
        try {
            Statement stm = ConexaoBD.getInstance().getConnection().createStatement();

            String sql = "INSERT INTO tarefa VALUES (default, "
                    + "'" + tarefa.getDescricao() + "', "
                    + "'" + tarefa.getData_criacao() + "', "
                    + (tarefa.getData_prevista() == null || tarefa.getData_prevista().isEmpty() ? "NULL" : "'" + tarefa.getData_prevista() + "'") + ", "
                    + (tarefa.getData_encerramento() == null || tarefa.getData_encerramento().isEmpty() ? "NULL" : "'" + tarefa.getData_encerramento() + "'") + ", "
                    + "'" + tarefa.getSituacao() + "')";

            int resultado = stm.executeUpdate(sql);
            System.out.println("SQL: " + sql);
            return resultado > 0;
        } catch (Exception e) {
            System.out.println("Erro ao salvar dado!" + e);
            return false;
        }
    }

    public boolean editar(Tarefa tarefa) {
        try {
            Statement stm = ConexaoBD.getInstance().getConnection().createStatement();

            String sql = " UPDATE tarefa SET "
                    + "descricao = '" + tarefa.getDescricao() + "', "
                    + "data_criacao = '" + tarefa.getData_criacao() + "', "
                    + "data_prevista = '" + tarefa.getData_prevista() + "', "
                    + "data_encerramento = '" + tarefa.getData_encerramento() + "', "
                    + "situacao = '" + tarefa.getSituacao() + "' "
                    + "WHERE id = " + tarefa.getId() + "; ";

            int resultado = stm.executeUpdate(sql);

            System.out.println("SQL: " + sql);
            System.out.println("Resultado: " + resultado);
            return true;
        } catch (Exception e) {
            System.out.println("Erro ao editar tarefa!" + e);
            return false;
        }
    }

    public boolean deletarTarefa(int id) {
        try {
            Statement stm = ConexaoBD.getInstance().getConnection().createStatement();

            String sql = "DELETE FROM tarefa WHERE id = " + id;

            int resultado = stm.executeUpdate(sql);

            System.out.println("SQL: " + sql);
            System.out.println("Resultado: " + resultado);

            return true;
        } catch (Exception e) {
            System.out.println("Erro ao excluir tarefa!" + e);
            return false;
        }
    }

    public ArrayList<Tarefa> consultar() {
        ArrayList<Tarefa> tarefa = new ArrayList<>();
        Tarefa retorno;

        try {
            Statement st = ConexaoBD.getInstance().getConnection().createStatement();

            String sql = " select * from tarefa order by id; ";

            System.out.println("SQL: " + sql);

            ResultSet resultado = st.executeQuery(sql);

            while (resultado.next()) {
                retorno = new Tarefa();
                retorno.setId(resultado.getInt("id"));
                retorno.setDescricao(resultado.getString("descricao"));
                retorno.setData_criacao(resultado.getString("data_criacao"));
                retorno.setData_prevista(resultado.getString("data_prevista"));
                retorno.setData_encerramento(resultado.getString("data_encerramento"));
                retorno.setSituacao(resultado.getString("situacao"));

                tarefa.add(retorno);
            }

        } catch (Exception e) {
            System.out.println("Erro ao consultar tarefas: " + e);
        }

        return tarefa;
    }

    public ArrayList<Tarefa> consultarPorData(String dataMin, String dataMax) {
        ArrayList<Tarefa> tarefa = new ArrayList<>();
        Tarefa retorno;

        try {
            Statement st = ConexaoBD.getInstance().getConnection().createStatement();

            String sql = " select * from tarefa where data_criacao >= '" + dataMin + "' and data_criacao <= '" + dataMax + "'; ";

            System.out.println("SQL: " + sql);

            ResultSet resultado = st.executeQuery(sql);

            while (resultado.next()) {
                retorno = new Tarefa();
                retorno.setId(resultado.getInt("id"));
                retorno.setDescricao(resultado.getString("descricao"));
                retorno.setData_criacao(resultado.getString("data_criacao"));
                retorno.setData_prevista(resultado.getString("data_prevista"));
                retorno.setData_encerramento(resultado.getString("data_encerramento"));
                retorno.setSituacao(resultado.getString("situacao"));

                tarefa.add(retorno);
            }

        } catch (Exception e) {
            System.out.println("Erro ao consultar tarefas: " + e);
        }

        return tarefa;
    }

    public Tarefa consultarUltima() {
        Tarefa tarefa = new Tarefa();
        Tarefa retorno;

        try {
            Statement st = ConexaoBD.getInstance().getConnection().createStatement();

            String sql = " select id from tarefa where id=(select max(id) from tarefa); ";

            System.out.println("SQL: " + sql);

            ResultSet resultado = st.executeQuery(sql);

            while (resultado.next()) {
                retorno = new Tarefa();
                retorno.setId(resultado.getInt("id"));
                tarefa.setDescricao(resultado.getString("descricao"));
                tarefa.setData_criacao(resultado.getString("data_criacao"));
                tarefa.setData_prevista(resultado.getString("data_prevista"));
                tarefa.setData_encerramento(resultado.getString("data_encerramento"));
                tarefa.setSituacao(resultado.getString("situacao"));
            }

        } catch (Exception e) {
            System.out.println("Erro ao consultar tarefas: " + e);
        }

        return tarefa;
    }

    public Tarefa consultarPorId(int id) {
        Tarefa tarefa = null;

        try {
            Statement st = ConexaoBD.getInstance().getConnection().createStatement();

            String sql = " select * from tarefa where id = " + id + "; ";

            System.out.println("SQL: " + sql);

            ResultSet resultado = st.executeQuery(sql);

            while (resultado.next()) {
                tarefa = new Tarefa();
                tarefa.setId(resultado.getInt("id"));
                tarefa.setDescricao(resultado.getString("descricao"));
                tarefa.setData_criacao(resultado.getString("data_criacao"));
                tarefa.setData_prevista(resultado.getString("data_prevista"));
                tarefa.setData_encerramento(resultado.getString("data_encerramento"));
                tarefa.setSituacao(resultado.getString("situacao"));
            }

        } catch (Exception e) {
            System.out.println("Erro ao consultar tarefas: " + e);
        }

        return tarefa;
    }
}
