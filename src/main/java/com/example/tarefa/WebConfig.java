package com.example.tarefa;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.ViewControllerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    /**
     * Configuração de recursos estáticos
     */
    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // Mapear arquivos estáticos
        registry.addResourceHandler("/**")
                .addResourceLocations("classpath:/static/");
        
        // Mapear especificamente para as páginas HTML
        registry.addResourceHandler("/lista.html", "/formulario.html")
                .addResourceLocations("classpath:/static/");
    }

    /**
     * Configuração de view controllers simples
     */
    @Override
    public void addViewControllers(ViewControllerRegistry registry) {
        // Redirecionar página inicial
        registry.addRedirectViewController("/", "/lista.html");
        registry.addRedirectViewController("/tarefas", "/lista.html");
        registry.addRedirectViewController("/tarefas/", "/lista.html");
        registry.addRedirectViewController("/tarefas/nova", "/formulario.html");
        registry.addRedirectViewController("/tarefas/editar", "/formulario.html");
    }

    /**
     * Configuração CORS para API
     */
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }
}