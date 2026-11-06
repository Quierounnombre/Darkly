# Open Redirect en /redirect?next=

## Resumen

`GET /redirect?next=<url>` hace un `307 Temporary Redirect` directo a lo
que sea que venga en `next`, sin validar que sea una URL propia o esté en
una lista blanca de dominios de confianza.

El endpoint existe legítimamente para el botón "Sign in with Google" de
`/login`, que enlaza a
`/redirect?next=https://accounts.google.com` — pero al no restringir el
destino, sirve igual para cualquier URL externa.

## Explotación

```
GET /redirect?next=https://evil.example.com
```

```http
HTTP/1.1 307 Temporary Redirect
location: https://evil.example.com
```

El navegador salta automáticamente al dominio del atacante.

## Impacto

Phishing clásico vía open redirect: un enlace con pinta de confianza
(`darkly.42...fr/redirect?next=...`, dominio legítimo) puede llevar a
cualquier sitio controlado por un atacante — útil para robar credenciales
haciendo pasar una página falsa de login por "parte de la plataforma", o
para saltarse filtros de email/chat que solo comprueban el dominio del
enlace. No se encontró ninguna flag asociada; es un hallazgo informativo
de severidad media.

## Remediación

- Restringir `next` a una lista blanca explícita de destinos permitidos
  (p. ej. solo `https://accounts.google.com/...` para el flujo de login
  con Google), rechazando cualquier otro valor.
- Alternativamente, no aceptar URLs absolutas en `next`: solo paths
  relativos dentro del propio dominio (`/dashboard`, `/profile`, etc.).
- Si se necesita redirigir a proveedores OAuth externos, usar la
  configuración del propio flujo OAuth (`redirect_uri` fijo del lado del
  servidor) en vez de un parámetro de redirección genérico y abierto.
