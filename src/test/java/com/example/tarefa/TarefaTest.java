package com.example.tarefa;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.mockito.MockedStatic;
import org.mockito.Mockito;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import java.sql.*;
import java.util.ArrayList;

class TarefaTest {

    private Tarefa tarefa;
    private Connection mockConnection;
    private Statement mockStatement;
    private ResultSet mockResultSet;

    @BeforeEach
    void setUp() {
        tarefa = new Tarefa();
        mockConnection = mock(Connection.class);
        mockStatement = mock(Statement.class);
        mockResultSet = mock(ResultSet.class);
    }

    @Test
    @DisplayName("Teste 1: Construtor com parâmetros deve criar tarefa corretamente")
    void testConstrutorComParametros() {
        Tarefa novaTarefa = new Tarefa(1, "Teste", "2024-01-01", "2024-01-02", null, "Pendente");
        
        assertEquals(1, novaTarefa.getId());
        assertEquals("Teste", novaTarefa.getDescricao());
        assertEquals("2024-01-01", novaTarefa.getData_criacao());
        assertEquals("2024-01-02", novaTarefa.getData_prevista());
        assertNull(novaTarefa.getData_encerramento());
        assertEquals("Pendente", novaTarefa.getSituacao());
    }

    @Test
    @DisplayName("Teste 2: Getters e Setters devem funcionar corretamente")
    void testGettersSetters() {
        tarefa.setId(5);
        tarefa.setDescricao("Tarefa de teste");
        tarefa.setData_criacao("2024-01-01");
        tarefa.setData_prevista("2024-01-05");
        tarefa.setData_encerramento("2024-01-03");
        tarefa.setSituacao("Concluída");

        assertEquals(5, tarefa.getId());
        assertEquals("Tarefa de teste", tarefa.getDescricao());
        assertEquals("2024-01-01", tarefa.getData_criacao());
        assertEquals("2024-01-05", tarefa.getData_prevista());
        assertEquals("2024-01-03", tarefa.getData_encerramento());
        assertEquals("Concluída", tarefa.getSituacao());
    }

    @Test
    @DisplayName("Teste 3: Salvar tarefa com sucesso")
    void testSalvarTarefaComSucesso() throws Exception {
        try (MockedStatic<ConexaoBD> mockedConexao = Mockito.mockStatic(ConexaoBD.class)) {
            ConexaoBD mockConexaoBD = mock(ConexaoBD.class);
            mockedConexao.when(ConexaoBD::getInstance).thenReturn(mockConexaoBD);
            when(mockConexaoBD.getConnection()).thenReturn(mockConnection);
            when(mockConnection.createStatement()).thenReturn(mockStatement);
            when(mockStatement.executeUpdate(anyString())).thenReturn(1);

            Tarefa novaTarefa = new Tarefa();
            novaTarefa.setDescricao("Nova tarefa");
            novaTarefa.setData_criacao("2024-01-01");
            novaTarefa.setSituacao("Pendente");

            boolean resultado = novaTarefa.salvar(novaTarefa);

            assertTrue(resultado);
            verify(mockStatement).executeUpdate(contains("INSERT INTO tarefa"));
        }
    }

    @Test
    @DisplayName("Teste 4: Consultar todas as tarefas")
    void testConsultarTodasTarefas() throws Exception {
        try (MockedStatic<ConexaoBD> mockedConexao = Mockito.mockStatic(ConexaoBD.class)) {
            ConexaoBD mockConexaoBD = mock(ConexaoBD.class);
            mockedConexao.when(ConexaoBD::getInstance).thenReturn(mockConexaoBD);
            when(mockConexaoBD.getConnection()).thenReturn(mockConnection);
            when(mockConnection.createStatement()).thenReturn(mockStatement);
            when(mockStatement.executeQuery(anyString())).thenReturn(mockResultSet);
            
            when(mockResultSet.next()).thenReturn(true, false);
            when(mockResultSet.getInt("id")).thenReturn(1);
            when(mockResultSet.getString("descricao")).thenReturn("Tarefa teste");
            when(mockResultSet.getString("data_criacao")).thenReturn("2024-01-01");
            when(mockResultSet.getString("data_prevista")).thenReturn("2024-01-02");
            when(mockResultSet.getString("data_encerramento")).thenReturn(null);
            when(mockResultSet.getString("situacao")).thenReturn("Pendente");

            ArrayList<Tarefa> resultado = tarefa.consultar();

            assertEquals(1, resultado.size());
            assertEquals("Tarefa teste", resultado.get(0).getDescricao());
        }
    }

    @Test
    @DisplayName("Teste 5: Editar tarefa existente")
    void testEditarTarefa() throws Exception {
        try (MockedStatic<ConexaoBD> mockedConexao = Mockito.mockStatic(ConexaoBD.class)) {
            ConexaoBD mockConexaoBD = mock(ConexaoBD.class);
            mockedConexao.when(ConexaoBD::getInstance).thenReturn(mockConexaoBD);
            when(mockConexaoBD.getConnection()).thenReturn(mockConnection);
            when(mockConnection.createStatement()).thenReturn(mockStatement);
            when(mockStatement.executeUpdate(anyString())).thenReturn(1);

            tarefa.setId(1);
            tarefa.setDescricao("Tarefa editada");
            tarefa.setData_criacao("2024-01-01");
            tarefa.setSituacao("Em Andamento");

            boolean resultado = tarefa.editar(tarefa);

            assertTrue(resultado);
            verify(mockStatement).executeUpdate(contains("UPDATE tarefa SET"));
        }
    }
}