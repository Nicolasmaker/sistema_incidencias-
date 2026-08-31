package com.sistemaIncidencias.grupo8.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**") // Permite todas las rutas de la API
                .allowedOrigins("*") // Permite que cualquier frontend se conecte (ideal para desarrollo)
                .allowedMethods("GET", "POST", "PUT", "DELETE");
    }
}