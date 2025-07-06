package com.example.tarefa;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import java.util.ArrayList;
import java.util.Map;

class TarefaApplicationTest {

    @Mock
    private EmailService emailService;

    @InjectMocks
    private TarefaApplication controller;

    private Tarefa tarefaTeste;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        tarefaTeste = new Tarefa();
        tarefaTeste.setId(1);
        tarefaTeste.setDescricao("Tarefa de teste");
        tarefaTeste.setData_criacao("2024-01-01");
        tarefaTeste.setSituacao("Pendente");
    }

    @Test
    @DisplayName("Teste 11: Verificar status da aplicação")
    void testVerificarStatus() {
        ResponseEntity<Map<String, String>> response = controller.verificarStatus();
        
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("OK", response.getBody().get("status"));
        assertEquals("Aplicação funcionando corretamente!", response.getBody().get("message"));
    }

    @Test
    @DisplayName("Teste 12: Criar tarefa com descrição válida")
    void testCriarTarefaComDescricaoValida() {
        Tarefa novaTarefa = new Tarefa();
        novaTarefa.setDescricao("Nova tarefa válida");
        novaTarefa.setData_criacao("2024-01-01");
        novaTarefa.setSituacao("Pendente");

        // Mock do método salvar para retornar true
        Tarefa spyTarefa = spy(novaTarefa);
        doReturn(true).when(spyTarefa).salvar(any(Tarefa.class));

        ResponseEntity<Map<String, Object>> response = controller.criarTarefa(spyTarefa);
        
        assertEquals(HttpStatus.CREATED, response.getStatusCode());
        assertTrue((Boolean) response.getBody().get("success"));
    }

    @Test
    @DisplayName("Teste 13: Criar tarefa com descrição vazia deve falhar")
    void testCriarTarefaComDescricaoVazia() {
        Tarefa tarefaInvalida = new Tarefa();
        tarefaInvalida.setDescricao("");
        
        ResponseEntity<Map<String, Object>> response = controller.criarTarefa(tarefaInvalida);
        
        assertEquals(HttpStatus.BAD_REQUEST, response.getStatusCode());
        assertFalse((Boolean) response.getBody().get("success"));
        assertEquals("Descrição da tarefa é obrigatória!", response.getBody().get("message"));
    }

    @Test
    @DisplayName("Teste 14: Testar endpoint de email")
    void testTestarEmail() {
        when(emailService.enviarEmailTeste()).thenReturn(true);
        
        ResponseEntity<Map<String, String>> response = controller.testarEmail();
        
        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertEquals("true", response.getBody().get("success"));
        assertEquals("Email de teste enviado com sucesso!", response.getBody().get("message"));
    }
}