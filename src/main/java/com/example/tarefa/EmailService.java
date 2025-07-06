package com.example.tarefa;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import javax.mail.*;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import java.util.Properties;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Component
public class EmailService {
    
    @Value("${mail.smtp.username:be.schneidr@gmail.com}")
    private String username;
    
    @Value("${mail.smtp.password:zygt qtcl echc qafw}")
    private String password;
    
    // Email padrão para notificações
    private final String EMAIL_NOTIFICACAO = "be.schneidr@gmail.com";
    
    /**
     * Enviar email genérico
     */
    public boolean mandarEmail(String address, String title, String content) {
        // Validação básica
        if (username.isEmpty() || password.isEmpty()) {
            System.err.println("Credenciais de email não configuradas!");
            return false;
        }
        
        Properties props = new Properties();
        props.put("mail.smtp.host", "smtp.gmail.com");
        props.put("mail.smtp.port", "587");
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.starttls.enable", "true");
        props.put("mail.smtp.starttls.required", "true");
        props.put("mail.smtp.ssl.protocols", "TLSv1.2");
        props.put("mail.smtp.ssl.trust", "smtp.gmail.com");
        
        try {
            Session session = Session.getInstance(props, new javax.mail.Authenticator() {
                protected PasswordAuthentication getPasswordAuthentication() {
                    return new PasswordAuthentication(username, password);
                }
            });
            
            Message msg = new MimeMessage(session);
            msg.setFrom(new InternetAddress(username));
            msg.setRecipients(Message.RecipientType.TO, InternetAddress.parse(address));
            msg.setSubject(title);
            msg.setText(content);
            
            Transport.send(msg);
            System.out.println("📧 E-mail enviado com sucesso para: " + address);
            return true;
            
        } catch (MessagingException e) {
            System.err.println("Erro ao enviar e-mail: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Enviar email quando uma tarefa é cadastrada
     */
    public void enviarEmailCadastro(Tarefa tarefa) {
        try {
            String titulo = "✅ Nova Tarefa Cadastrada - " + tarefa.getDescricao();
            String conteudo = String.format(
                "Uma nova tarefa foi cadastrada no sistema!\n\n" +
                "📋 DETALHES DA TAREFA:\n" +
                "▫️ Descrição: %s\n" +
                "▫️ Data de Criação: %s\n" +
                "▫️ Data Prevista: %s\n" +
                "▫️ Situação: %s\n\n" +
                "🕐 Cadastrada em: %s\n\n" +
                "---\n" +
                "Sistema de Gerenciamento de Tarefas\n" +
                "Este é um email automático.",
                tarefa.getDescricao(),
                tarefa.getData_criacao() != null ? tarefa.getData_criacao() : "Não informada",
                tarefa.getData_prevista() != null ? tarefa.getData_prevista() : "Não informada",
                tarefa.getSituacao(),
                LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss"))
            );
            
            mandarEmail(EMAIL_NOTIFICACAO, titulo, conteudo);
            System.out.println("📧 Email de cadastro enviado para: " + EMAIL_NOTIFICACAO);
            
        } catch (Exception e) {
            System.err.println("Erro ao enviar email de cadastro: " + e.getMessage());
        }
    }
    
    /**
     * Enviar email quando uma tarefa é atualizada
     */
    public void enviarEmailAtualizacao(Tarefa tarefaOriginal, Tarefa tarefaAtualizada) {
        try {
            String titulo = "🔄 Tarefa Atualizada - " + tarefaAtualizada.getDescricao();
            
            StringBuilder mudancas = new StringBuilder();
            if (tarefaOriginal != null) {
                if (!safeEquals(tarefaOriginal.getDescricao(), tarefaAtualizada.getDescricao())) {
                    mudancas.append("▫️ Descrição: ").append(tarefaOriginal.getDescricao()).append(" → ").append(tarefaAtualizada.getDescricao()).append("\n");
                }
                if (!safeEquals(tarefaOriginal.getSituacao(), tarefaAtualizada.getSituacao())) {
                    mudancas.append("▫️ Situação: ").append(tarefaOriginal.getSituacao()).append(" → ").append(tarefaAtualizada.getSituacao()).append("\n");
                }
                if (!safeEquals(tarefaOriginal.getData_prevista(), tarefaAtualizada.getData_prevista())) {
                    mudancas.append("▫️ Data Prevista: ").append(tarefaOriginal.getData_prevista() != null ? tarefaOriginal.getData_prevista() : "Não informada")
                           .append(" → ").append(tarefaAtualizada.getData_prevista() != null ? tarefaAtualizada.getData_prevista() : "Não informada").append("\n");
                }
            }
            
            String conteudo = String.format(
                "Uma tarefa foi atualizada no sistema!\n\n" +
                "📋 TAREFA ATUALIZADA:\n" +
                "▫️ Descrição: %s\n" +
                "▫️ Situação: %s\n" +
                "▫️ Data Prevista: %s\n\n" +
                "🔄 MUDANÇAS REALIZADAS:\n%s\n" +
                "🕐 Atualizada em: %s\n\n" +
                "---\n" +
                "Sistema de Gerenciamento de Tarefas\n" +
                "Este é um email automático.",
                tarefaAtualizada.getDescricao(),
                tarefaAtualizada.getSituacao(),
                tarefaAtualizada.getData_prevista() != null ? tarefaAtualizada.getData_prevista() : "Não informada",
                mudancas.length() > 0 ? mudancas.toString() : "Nenhuma mudança detectada nos campos principais\n",
                LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss"))
            );
            
            mandarEmail(EMAIL_NOTIFICACAO, titulo, conteudo);
            System.out.println("📧 Email de atualização enviado para: " + EMAIL_NOTIFICACAO);
            
        } catch (Exception e) {
            System.err.println("Erro ao enviar email de atualização: " + e.getMessage());
        }
    }
    
    /**
     * Enviar email quando uma tarefa é excluída
     */
    public void enviarEmailExclusao(Tarefa tarefa) {
        try {
            String titulo = "🗑️ Tarefa Excluída - " + tarefa.getDescricao();
            String conteudo = String.format(
                "Uma tarefa foi excluída do sistema!\n\n" +
                "📋 TAREFA EXCLUÍDA:\n" +
                "▫️ Descrição: %s\n" +
                "▫️ Situação: %s\n" +
                "▫️ Data de Criação: %s\n" +
                "▫️ Data Prevista: %s\n" +
                "▫️ Data de Encerramento: %s\n\n" +
                "⚠️ Esta ação não pode ser desfeita!\n\n" +
                "🕐 Excluída em: %s\n\n" +
                "---\n" +
                "Sistema de Gerenciamento de Tarefas\n" +
                "Este é um email automático.",
                tarefa.getDescricao(),
                tarefa.getSituacao(),
                tarefa.getData_criacao() != null ? tarefa.getData_criacao() : "Não informada",
                tarefa.getData_prevista() != null ? tarefa.getData_prevista() : "Não informada",
                tarefa.getData_encerramento() != null ? tarefa.getData_encerramento() : "Não informada",
                LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss"))
            );
            
            mandarEmail(EMAIL_NOTIFICACAO, titulo, conteudo);
            System.out.println("📧 Email de exclusão enviado para: " + EMAIL_NOTIFICACAO);
            
        } catch (Exception e) {
            System.err.println("Erro ao enviar email de exclusão: " + e.getMessage());
        }
    }
    
    /**
     * Enviar email de teste
     */
    public boolean enviarEmailTeste() {
        try {
            String titulo = "🧪 Teste de Email - Sistema de Tarefas";
            String conteudo = "Este é um email de teste do sistema de gerenciamento de tarefas.\n\n" +
                "Se você recebeu este email, o sistema de notificações está funcionando corretamente!\n\n" +
                "📅 Enviado em: " + LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss")) +
                "\n\n---\nSistema de Gerenciamento de Tarefas";
            
            return mandarEmail(EMAIL_NOTIFICACAO, titulo, conteudo);
            
        } catch (Exception e) {
            System.err.println("Erro ao enviar email de teste: " + e.getMessage());
            return false;
        }
    }
    
    /**
     * Método auxiliar para comparação segura de strings
     */
    private boolean safeEquals(String str1, String str2) {
        if (str1 == null && str2 == null) return true;
        if (str1 == null || str2 == null) return false;
        return str1.equals(str2);
    }
}