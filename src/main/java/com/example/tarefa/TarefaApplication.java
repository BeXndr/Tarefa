package com.example.tarefa;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
@RestController
@RequestMapping("/api")
public class TarefaApplication {

    @Autowired
    private EmailService emailService;

    public static void main(String[] args) {
        SpringApplication.run(TarefaApplication.class, args);
        System.out.println("🚀 Aplicação Tarefa iniciada com sucesso!");
    }

    /**
     * GET /api/tarefas - Lista todas as tarefas
     */
    @GetMapping("/tarefas")
    public ResponseEntity<ArrayList<Tarefa>> listarTarefas() {
        try {
            Tarefa tarefaService = new Tarefa();
            ArrayList<Tarefa> tarefas = tarefaService.consultar();
            return ResponseEntity.ok(tarefas);
        } catch (Exception e) {
            System.err.println("Erro ao listar tarefas: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ArrayList<>());
        }
    }

    /**
     * GET /api/tarefas/{id} - Busca uma tarefa por ID
     */
    @GetMapping("/tarefas/{id}")
    public ResponseEntity<Tarefa> buscarTarefaPorId(@PathVariable int id) {
        try {
            Tarefa tarefaService = new Tarefa();
            Tarefa tarefa = tarefaService.consultarPorId(id);
            
            if (tarefa != null) {
                return ResponseEntity.ok(tarefa);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            System.err.println("Erro ao buscar tarefa: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    /**
     * POST /api/tarefas - Cria uma nova tarefa
     */
    @PostMapping("/tarefas")
    public ResponseEntity<Map<String, Object>> criarTarefa(@RequestBody Tarefa novaTarefa) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            if (novaTarefa.getDescricao() == null || novaTarefa.getDescricao().trim().isEmpty()) {
                response.put("success", false);
                response.put("message", "Descrição da tarefa é obrigatória!");
                return ResponseEntity.badRequest().body(response);
            }

            boolean sucesso = novaTarefa.salvar(novaTarefa);
            
            if (sucesso) {
                // 📧 ENVIAR EMAIL DE CADASTRO
                emailService.enviarEmailCadastro(novaTarefa);
                
                response.put("success", true);
                response.put("message", "Tarefa criada com sucesso!");
                response.put("tarefa", novaTarefa);
                return ResponseEntity.status(HttpStatus.CREATED).body(response);
            } else {
                response.put("success", false);
                response.put("message", "Erro ao criar tarefa!");
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
            }
        } catch (Exception e) {
            System.err.println("Erro ao criar tarefa: " + e.getMessage());
            response.put("success", false);
            response.put("message", "Erro interno do servidor: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    /**
     * PUT /api/tarefas/{id} - Atualiza uma tarefa existente
     */
    @PutMapping("/tarefas/{id}")
    public ResponseEntity<Map<String, Object>> atualizarTarefa(@PathVariable int id, @RequestBody Tarefa tarefaAtualizada) {
        Map<String, Object> response = new HashMap<>();
        
        try {
            Tarefa tarefaService = new Tarefa();
            Tarefa tarefaOriginal = tarefaService.consultarPorId(id);
            
            tarefaAtualizada.setId(id);
            boolean sucesso = tarefaAtualizada.editar(tarefaAtualizada);
            
            if (sucesso) {
                // 📧 ENVIAR EMAIL DE ATUALIZAÇÃO
                emailService.enviarEmailAtualizacao(tarefaOriginal, tarefaAtualizada);
                
                response.put("success", true);
                response.put("message", "Tarefa atualizada com sucesso!");
                response.put("tarefa", tarefaAtualizada);
                return ResponseEntity.ok(response);
            } else {
                response.put("success", false);
                response.put("message", "Erro ao atualizar tarefa!");
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
            }
        } catch (Exception e) {
            System.err.println("Erro ao atualizar tarefa: " + e.getMessage());
            response.put("success", false);
            response.put("message", "Erro interno do servidor: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    /**
     * DELETE /api/tarefas/{id} - Remove uma tarefa
     */
    @DeleteMapping("/tarefas/{id}")
    public ResponseEntity<Map<String, String>> deletarTarefa(@PathVariable int id) {
        Map<String, String> response = new HashMap<>();
        
        try {
            Tarefa tarefaService = new Tarefa();
            Tarefa tarefaParaExcluir = tarefaService.consultarPorId(id);
            
            boolean sucesso = tarefaService.deletarTarefa(id);
            
            if (sucesso) {
                // 📧 ENVIAR EMAIL DE EXCLUSÃO
                if (tarefaParaExcluir != null) {
                    emailService.enviarEmailExclusao(tarefaParaExcluir);
                }
                
                response.put("success", "true");
                response.put("message", "Tarefa excluída com sucesso!");
                return ResponseEntity.ok(response);
            } else {
                response.put("success", "false");
                response.put("message", "Erro ao excluir tarefa!");
                return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
            }
        } catch (Exception e) {
            System.err.println("Erro ao deletar tarefa: " + e.getMessage());
            response.put("success", "false");
            response.put("message", "Erro interno do servidor: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    /**
     * GET /api/tarefas/buscar - Busca tarefas por período
     */
    @GetMapping("/tarefas/buscar")
    public ResponseEntity<ArrayList<Tarefa>> buscarTarefasPorPeriodo(
            @RequestParam String dataMin, 
            @RequestParam String dataMax) {
        try {
            Tarefa tarefaService = new Tarefa();
            ArrayList<Tarefa> tarefas = tarefaService.consultarPorData(dataMin, dataMax);
            return ResponseEntity.ok(tarefas);
        } catch (Exception e) {
            System.err.println("Erro ao buscar tarefas por período: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ArrayList<>());
        }
    }

    /**
     * GET /api/status - Verifica se a aplicação está funcionando
     */
    @GetMapping("/status")
    public ResponseEntity<Map<String, String>> verificarStatus() {
        Map<String, String> status = new HashMap<>();
        status.put("status", "OK");
        status.put("message", "Aplicação funcionando corretamente!");
        status.put("timestamp", String.valueOf(System.currentTimeMillis()));
        return ResponseEntity.ok(status);
    }

    /**
     * GET /api/test-db - Testa a conexão com o banco de dados
     */
    @GetMapping("/test-db")
    public ResponseEntity<Map<String, String>> testarBancoDados() {
        Map<String, String> response = new HashMap<>();
        
        try {
            ConexaoBD.getInstance().getConnection();
            response.put("status", "OK");
            response.put("message", "Conexão com banco de dados estabelecida!");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("status", "ERRO");
            response.put("message", "Erro na conexão com banco: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    /**
     * POST /api/email/teste - Endpoint para testar email
     */
    @PostMapping("/email/teste")
    public ResponseEntity<Map<String, String>> testarEmail() {
        Map<String, String> response = new HashMap<>();
        
        try {
            boolean sucesso = emailService.enviarEmailTeste();
            
            if (sucesso) {
                response.put("success", "true");
                response.put("message", "Email de teste enviado com sucesso!");
            } else {
                response.put("success", "false");
                response.put("message", "Erro ao enviar email de teste!");
            }
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            response.put("success", "false");
            response.put("message", "Erro ao testar email: " + e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }
}