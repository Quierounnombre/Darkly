# Password Reset Token predecible (MD5 del email)

## Resumen

El flujo de "Forgot your password?" genera un link de reset
(`/reset-password?email=...&token=...`) donde el `token` no es un valor
aleatorio de un solo uso generado y guardado server-side, sino
**literalmente `md5(email)`** — el mismo valor, siempre, para el mismo
email, sin secreto ni componente temporal.

## Vector de entrada

Un estudiante lo describió entero en un post del foro (ver
`Resources/forum_leak.txt`):

> "the token is literally the md5 of my email address [...] Anyone could
> reset anyone's account this way — and once they're in, your account
> recovery code is just sitting there on your profile settings page."

## Explotación

1. Elegir una víctima cuyo email se conoce (los emails de estudiantes
   siguen el patrón `username@student.42.tech`, visible en varios sitios
   de la app).
2. Calcular `token = md5(email)` localmente, sin tocar el servidor:

   ```
   md5("thanos@student.42.tech") = 7c983aa3101755740f5fc820637a43d9
   ```

3. `POST /reset-password/confirm` con `email`, `token` y una
   `new_password` elegida por el atacante → `302` con
   `location: /login?success=Password+updated`. El servidor nunca valida
   que el "poseedor" del token haya recibido realmente un email; solo
   comprueba que `md5(email) == token`.
4. `POST /login` con el email de la víctima y la contraseña recién
   impuesta por el atacante → sesión válida como esa víctima.
5. `GET /profile/me/settings` → la tarjeta "Account recovery code" muestra
   en claro:

   ```
   FLAG{r3s3t_t0k3n_w4s_just_md5_lol}
   ```

El token es de un solo uso (una vez consumido, un segundo intento con el
mismo token devuelve `error=Invalid+token`), pero como es **determinista y
recalculable** en cualquier momento a partir solo del email, la propiedad
de "un solo uso" no aporta ninguna protección real.

## Impacto

Compromiso total de cualquier cuenta cuyo email se conozca, sin acceso al
buzón de correo, sin contraseña previa y sin necesidad de fuerza bruta —
el "secreto" del reset es público en la práctica (es una función
determinista de un dato no secreto).

## Remediación

- Generar el token de reset con un generador aleatorio criptográficamente
  seguro (p. ej. 32 bytes de `secrets.token_urlsafe`), nunca derivado de
  datos conocidos/adivinables como el email.
- Guardar el token (o un hash del mismo) server-side junto con su fecha de
  expiración, y validar contra ese almacenamiento — nunca recalcularlo a
  partir del email en el momento de la confirmación.
- Enviar el token únicamente por email a la dirección registrada; el link
  "funcionó al instante, sin email" en el reporte del estudiante ya es en
  sí mismo una señal de que el flujo no depende de la posesión del correo.
- No mostrar nunca secretos sensibles (como el "recovery code" aquí) en
  texto plano en una página de ajustes accesible tras cualquier sesión
  válida.
