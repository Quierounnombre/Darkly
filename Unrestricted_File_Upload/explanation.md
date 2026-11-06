# Unrestricted File Upload → XSS same-origin

## Resumen

El formulario de avatar en `/profile/me/settings` envía a
`POST /upload/avatar` sin ningún filtro de extensión ni de tipo de
contenido. Coincide con el comentario del deploy log:

```
v1.3.3 — wil — "quick fix on file upload" (removed the whitelist entirely)
```

Los ficheros se guardan como `/static/uploads/{user_id}_{nombre_original}`
y se sirven de vuelta con su **content-type real**, deducido de la
extensión/contenido del fichero — no forzado a algo seguro como
`application/octet-stream` o `text/plain`.

## Explotación

1. Autenticarse (sesión forjada o real).
2. Subir un fichero `.svg` cuyo contenido incluya un `<script>` (ver
   `Resources/payload.svg`):

   ```xml
   <svg xmlns="http://www.w3.org/2000/svg"><script>alert(document.domain)</script></svg>
   ```

3. `POST /upload/avatar` (multipart, campo `file`) acepta el fichero sin
   rechazarlo, y la respuesta redirige a:

   ```
   /profile/me/settings?upload_flag=FLAG{unr3str1ct3d_upl0ad_g0_brrr}
   ```

4. El fichero queda disponible en
   `http://localhost:4942/static/uploads/{user_id}_payload.svg`, servido
   con `Content-Type: image/svg+xml`. Al abrirlo directamente en el
   navegador, el `<script>` se ejecuta en el mismo origen que el resto de
   la aplicación — XSS almacenado same-origin.

   Se comprobó lo mismo subiendo `.html` (se sirve como `text/html`, el
   script corre igual) y `.txt` (se acepta igualmente, sin ejecutar nada
   por sí solo pero confirmando la ausencia total de whitelist).

## Impacto

Cualquier usuario autenticado puede alojar contenido 100% controlado por
él (HTML/JS arbitrario) en el mismo origen que la aplicación legítima.
Combinado con el hecho de que las cookies de sesión no son `httponly`
(ver [`../Stored_XSS_Session_Hijack`](../Stored_XSS_Session_Hijack/explanation.md)),
esto es un vector directo de robo de sesión de cualquier otro usuario al
que se le pueda hacer abrir el enlace — por ejemplo, posteando la URL del
propio avatar en un hilo del foro.

## Remediación

- Restaurar una whitelist estricta de extensiones/tipos MIME permitidos
  para avatares (p. ej. solo `image/png`, `image/jpeg`), validando el
  contenido real del fichero (magic bytes), no solo la extensión.
- Servir siempre los ficheros subidos por usuarios desde un **origen
  distinto** (o sin origen, p. ej. un bucket con `Content-Disposition:
  attachment` y `Content-Type` forzado), nunca desde el mismo dominio que
  la aplicación.
- Para SVGs en particular: o se prohíben, o se sanitizan eliminando
  `<script>` y manejadores de evento antes de servirlos — los SVG son
  XML y pueden contener JavaScript ejecutable igual que un HTML.
