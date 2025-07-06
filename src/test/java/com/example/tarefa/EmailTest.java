package com.example.tarefa;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import static org.junit.jupiter.api.Assertions.*;

class EmailTest {

    private Email email;

    @BeforeEach
    void setUp() {
        email = new Email("test@example.com", "Título Teste", "Conteúdo de teste");
    }

    @Test
    @DisplayName("Teste 6: Construtor deve inicializar propriedades corretamente")
    void testConstrutorEmail() {
        assertEquals("test@example.com", email.getAddress());
        assertEquals("Título Teste", email.getTitle());
        assertEquals("Conteúdo de teste", email.getText());
    }

    @Test
    @DisplayName("Teste 7: Setter/Getter de address")
    void testSetGetAddress() {
        email.setAddress("novo@example.com");
        assertEquals("novo@example.com", email.getAddress());
    }

    @Test
    @DisplayName("Teste 8: Setter/Getter de title")
    void testSetGetTitle() {
        email.setTitle("Novo Título");
        assertEquals("Novo Título", email.getTitle());
    }

    @Test
    @DisplayName("Teste 9: Setter/Getter de text")
    void testSetGetText() {
        email.setText("Novo conteúdo");
        assertEquals("Novo conteúdo", email.getText());
    }

    @Test
    @DisplayName("Teste 10: Email com valores nulos")
    void testEmailComValoresNulos() {
        Email emailNulo = new Email(null, null, null);
        assertNull(emailNulo.getAddress());
        assertNull(emailNulo.getTitle());
        assertNull(emailNulo.getText());
    }
}