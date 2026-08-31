package com.sistemaIncidencias.grupo8.repository;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import com.sistemaIncidencias.grupo8.models.Incidencia;
import com.sistemaIncidencias.grupo8.models.Incidencia.Estado;

public interface IncidenciaRepository extends JpaRepository<Incidencia, Long> {
    
    // Filtro por estado
    List<Incidencia> findByEstado(Estado estado);
    
    // Busqueda por texto en el titulo
    List<Incidencia> findByTituloContainingIgnoreCase(String texto);
}
