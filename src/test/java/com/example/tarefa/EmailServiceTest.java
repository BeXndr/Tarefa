package com.example.tarefa;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;
import org.springframework.test.util.ReflectionTestUtils;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class EmailServiceTest {

    private EmailService emailService;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);
        emailService = new EmailService();
        
        // Configurar propriedades usando reflection para testes
        ReflectionTestUtils.setField(emailService, "username", "test@gmail.com");
        ReflectionTestUtils.setField(emailService, "password", "testpassword");
    }

    @Test
    @DisplayName("Teste 24: Enviar email de cadastro deve processar tarefa corretamente")
    void testEnviarEmailCadastro() {
        Tarefa tarefa = new Tarefa();
        tarefa.setDescricao("Tarefa de teste para email");
        tarefa.setData_criacao("2024-01-01");
        tarefa.setSituacao("Pendente");

        // Criar spy para poder verificar se o método interno foi chamado
        EmailService spyEmailService = spy(emailService);
        doReturn(true).when(spyEmailService).mandarEmail(anyString(), anyString(), anyString());

        assertDoesNotThrow(() -> {
            spyEmailService.enviarEmailCadastro(tarefa);
        });

        verify(spyEmailService).mandarEmail(anyString(), contains("Nova Tarefa Cadastrada"), anyString());
    }

    @Test
    @DisplayName("Teste 25: Enviar email de teste deve retornar boolean")
    void testEnviarEmailTeste() {
        EmailService spyEmailService = spy(emailService);
        doReturn(true).when(spyEmailService).mandarEmail(anyString(), anyString(), anyString());

        boolean resultado = spyEmailService.enviarEmailTeste();

        assertTrue(resultado);
        verify(spyEmailService).mandarEmail(anyString(), contains("Teste de Email"), anyString());
    }
}
