package com.sistemaIncidencias.grupo8.services;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.sistemaIncidencias.grupo8.models.Incidencia;
import com.sistemaIncidencias.grupo8.repository.IncidenciaRepository;

@Service
public class IncidenciaService {

    private final IncidenciaRepository repository;

    public IncidenciaService(IncidenciaRepository repository) {
        this.repository = repository;
    }

    public List<Incidencia> listar(Incidencia.Estado estado, String search) {
        if (estado != null) return repository.findByEstado(estado);
        if (search != null) return repository.findByTituloContainingIgnoreCase(search);
        return repository.findAll();
    }

    public Optional<Incidencia> verDetalle(Long id) {
        return repository.findById(id);
    }

    public Incidencia guardar(Incidencia incidencia) {
        return repository.save(incidencia);
    }

    public void eliminar(Long id) {
        repository.deleteById(id);
    }

    public boolean existe(Long id) {
        return repository.existsById(id);
    }
}
