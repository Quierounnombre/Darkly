# XXE → SSRF: fuga de configuración interna

## Resumen

`/agenda/import` acepta un fichero XML y lo parsea con `xml.etree`
(stdlib de Python), que por defecto **no** deshabilita las entidades
externas. Esto permite una inyección XXE clásica: una `<!ENTITY>` externa
puede apuntar a cualquier URL, y el propio servidor hace la petición y
devuelve el resultado incrustado en la respuesta.

`/internal/config` está pensado para ser accesible solo desde `localhost`
— pero como la petición SSRF la hace el propio servidor (que SÍ es
localhost desde su propio punto de vista), la restricción queda sin
efecto. Es el patrón típico de "XXE usado como pivote SSRF para saltarse
un bind a localhost".

## Vector de entrada

Comentarios HTML en la página de `/agenda` (ver `found_things.txt`):

```
<!-- emilie: the importer parses any XML you upload, entities and all. wil: we call that "flexible". -->
<!-- emilie: i filed a ticket to use defusedxml. wil: i filed it under "wontfix". -->
<!-- NOTE: /internal/config restricted to localhost only. do not expose. -->
```

Son, otra vez, pistas dejadas por los propios desarrolladores en el código
servido al cliente.

## Explotación

1. Conseguir cualquier sesión autenticada (estudiante, cadete... cualquiera
   vale — aquí se usa una forjada con el secreto filtrado, ver
   [`../JWT_Forgery_Impersonation`](../JWT_Forgery_Impersonation/explanation.md)).
2. Construir un XML con un DOCTYPE que declare una entidad externa apuntando
   al recurso interno que queremos leer (ver `Resources/xxe_payload.xml`):

   ```xml
   <?xml version="1.0"?>
   <!DOCTYPE agenda [<!ENTITY xxe SYSTEM "http://localhost:4942/internal/config">]>
   <agenda>
     <event>
       <title>&xxe;</title>
       <date>2042-01-15</date>
     </event>
   </agenda>
   ```
3. Subirlo a `POST /agenda/import` (`multipart/form-data`, campo `file`).
4. El servidor resuelve `&xxe;` haciendo él mismo la petición a
   `/internal/config`, y el contenido de esa respuesta aparece embebido como
   el "título" del evento importado — de un solo golpe se filtra el secreto
   JWT, las credenciales de superusuario de PocketBase, la versión de la
   app y la flag (ver `Resources/leaked_config.json`, salida real capturada).

## Impacto

Fuga total de configuración interna sensible en una sola petición:
- Secreto de firma de los JWT de sesión (habilita
  [`../JWT_Forgery_Impersonation`](../JWT_Forgery_Impersonation/explanation.md)).
- Credenciales de superusuario de PocketBase (acceso administrativo directo
  al backend en el puerto 8090).
- Metadatos internos (versión de la app, campus).

Además, el mismo mecanismo SSRF podría usarse para alcanzar cualquier otro
servicio interno solo accesible desde `localhost` (bases de datos,
metadatos de cloud, etc.), no solo `/internal/config`.

## Remediación

- Sustituir `xml.etree.ElementTree` por `defusedxml` (ya había un ticket
  abierto para esto — cerrado como "wontfix", ver el comentario HTML).
  `defusedxml` deshabilita por defecto la resolución de entidades externas
  y DTDs.
- Nunca confiar en el origen de una petición ("es localhost, así que es de
  confianza") cuando ese origen puede ser forzado por un atacante vía SSRF.
  `/internal/config` debería exigir su propia autenticación/autorización,
  no solo filtrar por IP de origen.
- Validar y limitar los tipos de contenido/esquemas XML aceptados en
  cualquier importador de ficheros.
