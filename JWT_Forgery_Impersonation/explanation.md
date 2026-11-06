# JWT Forgery → Impersonación de cuenta

## Resumen

Las sesiones de la app FastAPI (puerto 4942) son JWT (`header.payload.signature`,
HS256) guardados en una cookie `session` con `httponly=false`. El payload
(`sub`, `login`, `role`, `exp`) solo está **firmado**, nunca cifrado, así que
cualquiera puede leerlo con solo decodificar base64. El problema real es que
el **secreto de firma quedó filtrado**.

## Vector de entrada

En el HTML del foro hay un comentario de deploy log (ver
`Resources/deploy_log_comment.txt`):

```
v1.2.0 — sophie — initial platform. jwt secret was "42". wil changed it to "42network". progress.
```

Con ese secreto se puede recalcular el HMAC-SHA256 de cualquier payload y
**forjar un token nuevo y válido** para cualquier `sub` (id de usuario) que
exista en la base de datos — sin conocer su contraseña y sin pasar por
`/login`.

Los ids de usuario (incluido el de `sophie`, rol `god`) se obtuvieron del HTML
del foro, donde cada post expone el id del autor.

## Explotación

1. Construir `header` y `payload` propios (`sub`, `login`, `role`, `exp`).
2. Firmar `base64url(header).base64url(payload)` con HMAC-SHA256 y el secreto
   `42network`.
3. Pegar el token resultante en la cookie `session` (vía DevTools o
   `document.cookie = "session=<token>"`, ya que no es `httponly`).
4. Visitar `/admin` → la app ya cree que somos `sophie` (rol `god`).

Nota: `/staff/dashboard` **revalida el rol real guardado en la base de
datos**, así que un rol forjado en el token no basta por sí solo para esa
ruta en concreto — ver [`../API_Profile_Privilege_Escalation`](../API_Profile_Privilege_Escalation/explanation.md)
para ese otro vector. Pero sí basta para impersonar completamente a un
usuario existente (incluido un `god`) en el resto de la app, como `/admin`.

## Impacto

Compromiso total de cualquier cuenta de la plataforma (incluida la de
administración) sin necesidad de contraseña, phishing, ni fuerza bruta —
solo con el secreto de firma filtrado y un id de usuario válido.

## Remediación

- No reutilizar/loguear nunca el secreto de firma en comentarios, logs o
  control de versiones; rotarlo inmediatamente si se filtra.
- Usar un secreto aleatorio de alta entropía (p. ej. 256 bits) generado por
  usuario de despliegue, nunca un valor memorable como `"42network"`.
- Marcar la cookie de sesión como `httponly`, `secure` y `SameSite=Strict`
  (ya hay un ticket interno #4201 abierto para esto, ver
  `Resources/deploy_log_comment.txt`).
- Revalidar siempre permisos sensibles contra la base de datos en servidor,
  nunca confiar en claims del JWT para autorización (el caso de
  `/staff/dashboard` es el patrón correcto; hay que aplicarlo en todas partes,
  incluido `/admin`).
