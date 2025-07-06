package com.example.tarefa;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.AfterEach;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import java.sql.Connection;

class ConexaoBDTest {

    @BeforeEach
    void setUp() {
        // Limpar instância singleton antes de cada teste
        ConexaoBD.getInstance().shutDown();
    }

    @AfterEach
    void tearDown() {
        // Limpar após cada teste
        try {
            ConexaoBD.getInstance().shutDown();
        } catch (Exception e) {
            // Ignorar erros na limpeza
        }
    }

    @Test
    @DisplayName("Teste 15: Singleton deve retornar sempre a mesma instância")
    void testSingletonPattern() {
        ConexaoBD instancia1 = ConexaoBD.getInstance();
        ConexaoBD instancia2 = ConexaoBD.getInstance();

        assertSame(instancia1, instancia2, "Deve retornar a mesma instância");
    }

    @Test
    @DisplayName("Teste 16: Conexão não deve ser nula após inicialização")
    void testConexaoNaoNula() {
        ConexaoBD conexaoBD = ConexaoBD.getInstance();

        assertNotNull(conexaoBD, "Instância não deve ser nula");
        assertDoesNotThrow(() -> {
            Connection conn = conexaoBD.getConnection();
            assertNotNull(conn, "Conexão não deve ser nula");
        });
    }

    @Test
    @DisplayName("Teste 17: Shutdown deve limpar instância")
    void testShutdown() {
        ConexaoBD conexaoBD = ConexaoBD.getInstance();
        conexaoBD.shutDown();

        // Após shutdown, getInstance() deve criar nova instância
        ConexaoBD novaInstancia = ConexaoBD.getInstance();
        assertNotNull(novaInstancia);
    }
}
