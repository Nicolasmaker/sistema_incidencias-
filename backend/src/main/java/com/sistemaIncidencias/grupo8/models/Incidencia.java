package com.sistemaIncidencias.grupo8.models;

import java.time.LocalDateTime;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "incidencias")
@Data
public class Incidencia {

    // Enums definidos dentro de la misma clase
    public enum Prioridad { BAJA, MEDIA, ALTA }
    public enum Estado { ABIERTA, EN_PROGRESO, RESUELTA }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String titulo;

    @Column(nullable = false)
    private String descripcion;

    private String categoria;

    @Enumerated(EnumType.STRING)
    private Prioridad prioridad;

    @Enumerated(EnumType.STRING)
    private Estado estado = Estado.ABIERTA;

    private LocalDateTime fechaCreacion = LocalDateTime.now();
}
