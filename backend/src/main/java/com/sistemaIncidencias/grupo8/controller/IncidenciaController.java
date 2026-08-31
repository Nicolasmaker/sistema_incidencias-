package com.sistemaIncidencias.grupo8.controller;

import org.springframework.web.bind.annotation.RestController;

import com.sistemaIncidencias.grupo8.models.Incidencia;
import com.sistemaIncidencias.grupo8.services.IncidenciaService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/incidencias")
public class IncidenciaController {

    private final IncidenciaService service;

    public IncidenciaController(IncidenciaService service) {
        this.service = service;
    }

    @GetMapping
    public List<Incidencia> listar(
            @RequestParam(required = false) Incidencia.Estado estado,
            @RequestParam(required = false) String search) {
        return service.listar(estado, search);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Incidencia> verDetalle(@PathVariable Long id) {
        return service.verDetalle(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Incidencia crear(@RequestBody Incidencia incidencia) {
        return service.guardar(incidencia);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Incidencia> actualizar(@PathVariable Long id, @RequestBody Incidencia actual) {
        return service.verDetalle(id).map(inc -> {
            inc.setTitulo(actual.getTitulo());
            inc.setDescripcion(actual.getDescripcion());
            inc.setCategoria(actual.getCategoria());
            inc.setPrioridad(actual.getPrioridad());
            inc.setEstado(actual.getEstado());
            return ResponseEntity.ok(service.guardar(inc));
        }).orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        if (service.existe(id)) {
            service.eliminar(id);
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}
