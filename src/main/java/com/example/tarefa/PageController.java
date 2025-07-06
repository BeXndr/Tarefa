package com.example.tarefa;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class PageController {

    /**
     * Página inicial - redireciona para lista de tarefas
     */
    @GetMapping("/")
    public String home() {
        return "redirect:/tarefas";
    }

    /**
     * Lista de tarefas
     */
    @GetMapping("/tarefas")
    public String listarTarefas() {
        return "lista.html";
    }

    /**
     * Formulário para nova tarefa
     */
    @GetMapping("/tarefas/nova")
    public String novaTarefa() {
        return "formulario.html";
    }

    /**
     * Formulário para editar tarefa
     */
    @GetMapping("/tarefas/editar")
    public String editarTarefa() {
        return "formulario.html";
    }

    /**
     * Página de lista (alternativa)
     */
    @GetMapping("/lista")
    public String lista() {
        return "lista.html";
    }

    /**
     * Página de formulário (alternativa)
     */
    @GetMapping("/formulario")
    public String formulario() {
        return "formulario.html";
    }
}