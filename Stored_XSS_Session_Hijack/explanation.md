# Stored XSS → Secuestro de sesión del moderador

## Resumen

Cadena de 3 fallos encontrados vía comentarios HTML en la propia app:

1. **Sin sanitización.** El contenido de los posts del foro se guarda y
   renderiza en crudo. El propio código lo admite sin pudor:
   `<!-- note to self: the "HTML supported" label is not a joke. content goes straight into the DB. don't tell students. — wil -->`.
2. **Endpoint de debug olvidado.** `/api/collect` acepta `GET`/`POST` con un
   parámetro `c` y lo guarda en un log, sin autenticación. Un `GET
   /api/collect` sin parámetros devuelve TODO el log acumulado — público.
3. **Bot de moderación privilegiado.** Un bot (`User-Agent: HeadlessChrome`)
   abre automáticamente cada hilo nuevo del foro usando una sesión real.
   Esa sesión tiene cookie `session` (JWT del moderador) y una cookie
   `flag` adicional, y ninguna de las dos es `httponly`.

## Explotación

1. Publicar un hilo trampa (`POST /forum/new`) cuyo `content` sea un
   `<script>` que exfiltre `document.cookie` hacia el propio endpoint de
   debug (ver `Resources/payload.html`):

   ```html
   <script>fetch("/api/collect?c="+encodeURIComponent(document.cookie))</script>
   ```

2. A los pocos segundos, el bot de moderación abre el hilo nuevo con su
   sesión privilegiada → el script se ejecuta en el contexto del bot →
   sus cookies (`session` + `flag`) quedan registradas en el log de
   `/api/collect`.
3. Leer el log con un simple `GET /api/collect` (sin autenticación) y
   extraer la cookie `flag` (ver `Resources/captured_log_excerpt.json`,
   captura real):

   ```
   flag=FLAG{xss_st0r3d_1s_n0t_4_f34tur3_w1l}
   ```

## Impacto

- Exfiltración de la sesión JWT real del **moderador**, reutilizable para
  impersonarlo sin forjar nada.
- Exposición pública de un flag "secreto" guardado en una cookie no
  `httponly`, vía un endpoint de debug sin autenticación.
- Cualquier estudiante puede ejecutar JavaScript arbitrario en el contexto
  de cualquier otro usuario (incluido staff) que abra un hilo del foro —
  XSS persistente, no solo reflejado.

## Remediación

- Sanitizar/escapar siempre el contenido generado por usuarios antes de
  renderizarlo (o usar una lista blanca estricta de tags si el "HTML
  supported" es un requisito real de producto), tanto en el guardado como
  en el render.
- Eliminar `/api/collect` de producción (es un endpoint de debug);
  cualquier endpoint de logging debe exigir autenticación/autorización y
  nunca devolver el log completo a quien lo pida.
- Marcar **todas** las cookies de sesión (y cualquier cookie sensible como
  `flag`) como `httponly`, `secure` y `SameSite=Strict` (había un ticket
  interno #4201 abierto para esto, nunca resuelto).
- El bot de moderación no debería navegar contenido no confiable con una
  sesión privilegiada real; si necesita previsualizar posts, debe hacerlo
  en un contexto aislado, sin cookies de sesión válidas.
