package com.sistemaIncidencias.grupo8.controller;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.sistemaIncidencias.grupo8.models.Incidencia;
import com.sistemaIncidencias.grupo8.models.Incidencia.Estado;
import com.sistemaIncidencias.grupo8.models.Incidencia.Prioridad;
import com.sistemaIncidencias.grupo8.services.IncidenciaService;

@ExtendWith(MockitoExtension.class)
class IncidenciaControllerTest {

    @Mock
    private IncidenciaService service;

    @InjectMocks
    private IncidenciaController controller;

    private Incidencia incidencia;

    @BeforeEach
    void setUp() {
        incidencia = new Incidencia();
        incidencia.setId(1L);
        incidencia.setTitulo("Problema de acceso VPN");
        incidencia.setDescripcion("Usuario no puede autenticarse");
        incidencia.setCategoria("Accesos");
        incidencia.setPrioridad(Prioridad.MEDIA);
        incidencia.setEstado(Estado.ABIERTA);
    }

    @Test
    @DisplayName("Endpoint health debe retornar status UP")
    void debeRetornarHealthCheck() {
        ResponseEntity<Map<String, Object>> response = controller.healthCheck();

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("UP", response.getBody().get("status"));
        assertEquals("microservicio-incidencias", response.getBody().get("service"));
    }

    @Test
    @DisplayName("Listar debe delegar en service y retornar lista")
    void debeListarIncidencias() {
        when(service.listar(Estado.ABIERTA, null)).thenReturn(Arrays.asList(incidencia));

        List<Incidencia> resultado = controller.listar(Estado.ABIERTA, null);

        assertNotNull(resultado);
        assertEquals(1, resultado.size());
        assertEquals("Problema de acceso VPN", resultado.get(0).getTitulo());
        verify(service, times(1)).listar(Estado.ABIERTA, null);
    }

    @Test
    @DisplayName("Ver detalle debe retornar 200 OK si existe")
    void debeRetornarDetalleCuandoExiste() {
        when(service.verDetalle(1L)).thenReturn(Optional.of(incidencia));

        ResponseEntity<Incidencia> response = controller.verDetalle(1L);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(1L, response.getBody().getId());
    }

    @Test
    @DisplayName("Ver detalle debe retornar 404 NOT FOUND si no existe")
    void debeRetornar404CuandoNoExiste() {
        when(service.verDetalle(99L)).thenReturn(Optional.empty());

        ResponseEntity<Incidencia> response = controller.verDetalle(99L);

        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
    }

    @Test
    @DisplayName("Crear incidencia debe delegar al service y retornar guardada")
    void debeCrearIncidencia() {
        when(service.guardar(any(Incidencia.class))).thenReturn(incidencia);

        Incidencia creada = controller.crear(incidencia);

        assertNotNull(creada);
        assertEquals("Problema de acceso VPN", creada.getTitulo());
        verify(service, times(1)).guardar(incidencia);
    }

    @Test
    @DisplayName("Actualizar incidencia existente debe retornar 200 OK con datos modificados")
    void debeActualizarIncidenciaExistente() {
        Incidencia modificada = new Incidencia();
        modificada.setTitulo("Problema VPN resuelto");
        modificada.setDescripcion("Se reseteo el token");
        modificada.setCategoria("Accesos");
        modificada.setPrioridad(Prioridad.BAJA);
        modificada.setEstado(Estado.RESUELTA);

        when(service.verDetalle(1L)).thenReturn(Optional.of(incidencia));
        when(service.guardar(any(Incidencia.class))).thenAnswer(i -> i.getArgument(0));

        ResponseEntity<Incidencia> response = controller.actualizar(1L, modificada);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("Problema VPN resuelto", response.getBody().getTitulo());
        assertEquals(Estado.RESUELTA, response.getBody().getEstado());
    }

    @Test
    @DisplayName("Eliminar debe retornar 204 NO CONTENT si existe")
    void debeEliminarCuandoExiste() {
        when(service.existe(1L)).thenReturn(true);
        doNothing().when(service).eliminar(1L);

        ResponseEntity<Void> response = controller.eliminar(1L);

        assertEquals(HttpStatus.NO_CONTENT, response.getStatusCode());
        verify(service, times(1)).eliminar(1L);
    }

    @Test
    @DisplayName("Eliminar debe retornar 404 NOT FOUND si no existe")
    void debeRetornar404AlEliminarNoExistente() {
        when(service.existe(99L)).thenReturn(false);

        ResponseEntity<Void> response = controller.eliminar(99L);

        assertEquals(HttpStatus.NOT_FOUND, response.getStatusCode());
        verify(service, never()).eliminar(99L);
    }
}
