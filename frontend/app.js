const API_URL = "http://localhost:8080/api/incidencias";

const form = document.getElementById("form-incidencia");
const idInput = document.getElementById("incidencia-id");
const tituloInput = document.getElementById("titulo");
const descripcionInput = document.getElementById("descripcion");
const categoriaInput = document.getElementById("categoria");
const prioridadInput = document.getElementById("prioridad");
const estadoInput = document.getElementById("estado");
const btnCancelar = document.getElementById("btn-cancelar");
const formTitle = document.getElementById("form-title");
const tabla = document.getElementById("tabla-incidencias");
const buscarInput = document.getElementById("buscar");
const filtroEstado = document.getElementById("filtro-estado");
const mensaje = document.getElementById("mensaje");

function mostrarMensaje(texto, tipo) {
  mensaje.textContent = texto;
  mensaje.className = "mensaje " + tipo;
  mensaje.hidden = false;
  setTimeout(() => { mensaje.hidden = true; }, 3000);
}

function limpiarFormulario() {
  form.reset();
  idInput.value = "";
  formTitle.textContent = "Nueva incidencia";
  btnCancelar.hidden = true;
}

async function cargarIncidencias() {
  const params = new URLSearchParams();
  if (filtroEstado.value) params.set("estado", filtroEstado.value);
  if (buscarInput.value.trim()) params.set("search", buscarInput.value.trim());

  try {
    const res = await fetch(`${API_URL}?${params.toString()}`);
    if (!res.ok) throw new Error("Error al cargar incidencias");
    const incidencias = await res.json();
    renderTabla(incidencias);
  } catch (err) {
    mostrarMensaje(err.message, "error");
  }
}

function renderTabla(incidencias) {
  tabla.innerHTML = "";

  if (incidencias.length === 0) {
    tabla.innerHTML = `<tr><td colspan="6">No hay incidencias.</td></tr>`;
    return;
  }

  incidencias.forEach(inc => {
    const fila = document.createElement("tr");
    const fecha = inc.fechaCreacion ? inc.fechaCreacion.replace("T", " ").substring(0, 16) : "";

    fila.innerHTML = `
      <td>${escapeHtml(inc.titulo)}</td>
      <td>${escapeHtml(inc.categoria || "-")}</td>
      <td class="prioridad-${inc.prioridad}">${inc.prioridad || "-"}</td>
      <td><span class="badge badge-${inc.estado}">${inc.estado}</span></td>
      <td>${fecha}</td>
      <td class="acciones">
        <button class="btn-editar" data-id="${inc.id}">Editar</button>
        <button class="btn-eliminar" data-id="${inc.id}">Eliminar</button>
      </td>
    `;
    tabla.appendChild(fila);
  });

  tabla.querySelectorAll(".btn-editar").forEach(btn =>
    btn.addEventListener("click", () => editarIncidencia(btn.dataset.id))
  );
  tabla.querySelectorAll(".btn-eliminar").forEach(btn =>
    btn.addEventListener("click", () => eliminarIncidencia(btn.dataset.id))
  );
}

function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str;
  return div.innerHTML;
}

async function editarIncidencia(id) {
  try {
    const res = await fetch(`${API_URL}/${id}`);
    if (!res.ok) throw new Error("No se pudo obtener la incidencia");
    const inc = await res.json();

    idInput.value = inc.id;
    tituloInput.value = inc.titulo;
    descripcionInput.value = inc.descripcion;
    categoriaInput.value = inc.categoria || "";
    prioridadInput.value = inc.prioridad || "MEDIA";
    estadoInput.value = inc.estado || "ABIERTA";

    formTitle.textContent = `Editar incidencia #${inc.id}`;
    btnCancelar.hidden = false;
    window.scrollTo({ top: 0, behavior: "smooth" });
  } catch (err) {
    mostrarMensaje(err.message, "error");
  }
}

async function eliminarIncidencia(id) {
  if (!confirm("¿Eliminar esta incidencia?")) return;
  try {
    const res = await fetch(`${API_URL}/${id}`, { method: "DELETE" });
    if (!res.ok && res.status !== 204) throw new Error("No se pudo eliminar");
    mostrarMensaje("Incidencia eliminada", "ok");
    cargarIncidencias();
  } catch (err) {
    mostrarMensaje(err.message, "error");
  }
}

form.addEventListener("submit", async (e) => {
  e.preventDefault();

  const payload = {
    titulo: tituloInput.value,
    descripcion: descripcionInput.value,
    categoria: categoriaInput.value,
    prioridad: prioridadInput.value,
    estado: estadoInput.value
  };

  const id = idInput.value;
  const url = id ? `${API_URL}/${id}` : API_URL;
  const method = id ? "PUT" : "POST";

  try {
    const res = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload)
    });
    if (!res.ok) throw new Error("No se pudo guardar la incidencia");

    mostrarMensaje(id ? "Incidencia actualizada" : "Incidencia creada", "ok");
    limpiarFormulario();
    cargarIncidencias();
  } catch (err) {
    mostrarMensaje(err.message, "error");
  }
});

btnCancelar.addEventListener("click", limpiarFormulario);
buscarInput.addEventListener("input", cargarIncidencias);
filtroEstado.addEventListener("change", cargarIncidencias);

cargarIncidencias();
