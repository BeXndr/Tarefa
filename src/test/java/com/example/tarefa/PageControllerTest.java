package com.example.tarefa;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import static org.junit.jupiter.api.Assertions.*;

class PageControllerTest {

    private PageController pageController;

    @BeforeEach
    void setUp() {
        pageController = new PageController();
    }

    @Test
    @DisplayName("Teste 18: Home deve redirecionar para /tarefas")
    void testHomeRedirect() {
        String resultado = pageController.home();
        assertEquals("redirect:/tarefas", resultado);
    }

    @Test
    @DisplayName("Teste 19: listarTarefas deve retornar lista.html")
    void testListarTarefas() {
        String resultado = pageController.listarTarefas();
        assertEquals("lista.html", resultado);
    }

    @Test
    @DisplayName("Teste 20: novaTarefa deve retornar formulario.html")
    void testNovaTarefa() {
        String resultado = pageController.novaTarefa();
        assertEquals("formulario.html", resultado);
    }

    @Test
    @DisplayName("Teste 21: editarTarefa deve retornar formulario.html")
    void testEditarTarefa() {
        String resultado = pageController.editarTarefa();
        assertEquals("formulario.html", resultado);
    }

    @Test
    @DisplayName("Teste 22: lista deve retornar lista.html")
    void testLista() {
        String resultado = pageController.lista();
        assertEquals("lista.html", resultado);
    }

    @Test
    @DisplayName("Teste 23: formulario deve retornar formulario.html")
    void testFormulario() {
        String resultado = pageController.formulario();
        assertEquals("formulario.html", resultado);
    }
}