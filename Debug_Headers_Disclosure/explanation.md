# Debug Headers filtran la topología del backend

## Resumen

Absolutamente todas las respuestas HTTP de la app FastAPI incluyen
cabeceras de debug que no deberían llegar nunca a producción:

```
x-powered-by: Python/3.11 FastAPI/0.104
server: uvicorn/0.24.0 Linux
x-pocketbase: http://localhost:8090
x-42-internal: campus=paris
```

El propio comentario HTML del deploy log lo confirma como algo conocido y
nunca resuelto: `<!-- TODO: remove debug headers before v1.4 release — wil -->`.

## Explotación

No requiere más que una petición cualquiera:

```
curl -s -I http://localhost:4942/
```

Ya revela:
- Stack exacto (Python 3.11, FastAPI 0.104, uvicorn 0.24.0) — útil para
  buscar CVEs conocidos de esas versiones concretas.
- La URL interna del backend PocketBase (`http://localhost:8090`),
  confirmando puerto y protocolo sin necesidad de escanear nada.
- Metadata interna de despliegue (`campus=paris`).

## Impacto

Por sí sola es solo reconocimiento (severidad baja), pero reduce
significativamente el esfuerzo de un atacante: confirma versiones exactas
para buscar vulnerabilidades conocidas y expone la existencia/ubicación
del backend interno sin necesidad de descubrirlo por otra vía. No hay
flag asociada a este hallazgo.

## Remediación

- Eliminar cabeceras de framework/servidor en producción
  (`server`, `x-powered-by`) — en FastAPI/uvicorn esto se hace con un
  middleware que las retire antes de enviar la respuesta, o configurando
  el proxy inverso delante para que las sobrescriba.
- No añadir nunca cabeceras custom de debug (`x-pocketbase`,
  `x-42-internal`) fuera de un entorno de desarrollo local; si se
  necesitan para debug, deben estar detrás de un flag de entorno
  (`DEBUG=true`) que esté explícitamente desactivado en producción.
