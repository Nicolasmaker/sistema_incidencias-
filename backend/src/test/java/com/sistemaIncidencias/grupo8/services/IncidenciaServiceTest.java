package com.sistemaIncidencias.grupo8.services;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.sistemaIncidencias.grupo8.models.Incidencia;
import com.sistemaIncidencias.grupo8.models.Incidencia.Estado;
import com.sistemaIncidencias.grupo8.models.Incidencia.Prioridad;
import com.sistemaIncidencias.grupo8.repository.IncidenciaRepository;

@ExtendWith(MockitoExtension.class)
class IncidenciaServiceTest {

    @Mock
    private IncidenciaRepository repository;

    @InjectMocks
    private IncidenciaService service;

    private Incidencia incidenciaBase;

    @BeforeEach
    void setUp() {
        incidenciaBase = new Incidencia();
        incidenciaBase.setId(1L);
        incidenciaBase.setTitulo("Fallo de red en servidor");
        incidenciaBase.setDescripcion("No hay conectividad con el cluster de base de datos");
        incidenciaBase.setCategoria("Redes");
        incidenciaBase.setPrioridad(Prioridad.ALTA);
        incidenciaBase.setEstado(Estado.ABIERTA);
    }

    @Test
    @DisplayName("Debe listar todas las incidencias cuando no hay filtros")
    void debeListarTodasLasIncidencias() {
        when(repository.findAll()).thenReturn(Arrays.asList(incidenciaBase));

        List<Incidencia> resultado = service.listar(null, null);

        assertNotNull(resultado);
        assertEquals(1, resultado.size());
        assertEquals("Fallo de red en servidor", resultado.get(0).getTitulo());
        verify(repository, times(1)).findAll();
    }

    @Test
    @DisplayName("Debe filtrar incidencias por estado")
    void debeListarPorEstado() {
        when(repository.findByEstado(Estado.ABIERTA)).thenReturn(Arrays.asList(incidenciaBase));

        List<Incidencia> resultado = service.listar(Estado.ABIERTA, null);

        assertNotNull(resultado);
        assertEquals(1, resultado.size());
        assertEquals(Estado.ABIERTA, resultado.get(0).getEstado());
        verify(repository, times(1)).findByEstado(Estado.ABIERTA);
    }

    @Test
    @DisplayName("Debe buscar incidencias por texto de búsqueda en título")
    void debeBuscarPorTitulo() {
        when(repository.findByTituloContainingIgnoreCase("red")).thenReturn(Arrays.asList(incidenciaBase));

        List<Incidencia> resultado = service.listar(null, "red");

        assertNotNull(resultado);
        assertEquals(1, resultado.size());
        verify(repository, times(1)).findByTituloContainingIgnoreCase("red");
    }

    @Test
    @DisplayName("Debe obtener el detalle de una incidencia existente")
    void debeObtenerDetalleExistente() {
        when(repository.findById(1L)).thenReturn(Optional.of(incidenciaBase));

        Optional<Incidencia> resultado = service.verDetalle(1L);

        assertTrue(resultado.isPresent());
        assertEquals(1L, resultado.get().getId());
        verify(repository, times(1)).findById(1L);
    }

    @Test
    @DisplayName("Debe guardar y retornar una incidencia")
    void debeGuardarIncidencia() {
        when(repository.save(any(Incidencia.class))).thenReturn(incidenciaBase);

        Incidencia guardada = service.guardar(incidenciaBase);

        assertNotNull(guardada);
        assertEquals("Fallo de red en servidor", guardada.getTitulo());
        verify(repository, times(1)).save(incidenciaBase);
    }

    @Test
    @DisplayName("Debe eliminar una incidencia por su ID")
    void debeEliminarIncidencia() {
        doNothing().when(repository).deleteById(1L);

        service.eliminar(1L);

        verify(repository, times(1)).deleteById(1L);
    }

    @Test
    @DisplayName("Debe verificar correctamente la existencia de una incidencia")
    void debeVerificarExistencia() {
        when(repository.existsById(1L)).thenReturn(true);
        when(repository.existsById(99L)).thenReturn(false);

        assertTrue(service.existe(1L));
        assertFalse(service.existe(99L));
        verify(repository, times(1)).existsById(1L);
        verify(repository, times(1)).existsById(99L);
    }
}
