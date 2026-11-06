# Contraseña débil en la cuenta jdoe

## Resumen

La cuenta `jdoe@student.42.tech` usa una contraseña (`abc123`) presente
cerca de la cabeza de `rockyou.txt` — rompible en segundos con un
diccionario mínimo, sin necesidad de fuerza bruta masiva ni de explotar
ningún otro fallo de la app. Ver `Resources/forum_hint.txt` para la pista
que apuntaba a esto.

## Explotación

1. `POST /login` con `identity=jdoe@student.42.tech` y
   `password=abc123` → `302 Found` con una cookie `session` válida. Toma
   de la cuenta completa, sin tocar ningún otro endpoint.
2. Para demostrar el alcance del takeover, se usa esa sesión en
   `PATCH /api/profile` (con un cambio inofensivo) — la respuesta
   confirma lectura/escritura total sobre el perfil: email, nombre,
   `pw_hint` (MD5, ver más abajo), `recovery_code`, `private_note`,
   avatar, rol...

## Nota sobre el campo `pw_hint`

El mismo `PATCH /api/profile` (ver también
[`../API_Profile_Privilege_Escalation`](../API_Profile_Privilege_Escalation/explanation.md))
devuelve un campo `pw_hint` que es un MD5 — en el caso de `jdoe`,
`e99a18c428cb38d5f260853678922e03`, que efectivamente es
`md5("abc123")`. Es decir: incluso sin el post del foro, este mismo campo
expuesto por otra vulnerabilidad ya habría permitido crackear la
contraseña offline contra rockyou.txt. Dos fallos independientes
(contraseña débil + exposición de su hash MD5 sin salt) se refuerzan
mutuamente.

## Sobre la flag de esta carpeta

Esta cuenta, en el estado actual del laboratorio, ya tiene el rol
`cadet` (quedó así tras las pruebas de
[`../API_Profile_Privilege_Escalation`](../API_Profile_Privilege_Escalation/explanation.md)
en una sesión anterior). Por eso, iniciar sesión como `jdoe` con la
contraseña crackeada da acceso directo a `/staff/dashboard` y su flag,
`FLAG{just_p4tch_y0ur_0wn_r0l3_lol}` — la MISMA flag que la del PATCH.

**Importante:** esto es incidental al estado actual de la cuenta, no una
propiedad intrínseca de "crackear la contraseña". En una instancia
recién desplegada, `jdoe` tiene rol `student` por defecto y este login no
desbloquearía por sí solo el panel de staff — haría falta encadenarlo con
la escalada de privilegios. Se documenta así, con honestidad, en vez de
inventar una flag "propia" que no existe para este vector en concreto.

## Impacto

Toma de control completa de la cuenta `jdoe` (datos personales, avatar,
rol, notas) sin pasar por ninguna otra vulnerabilidad — solo un
diccionario de contraseñas comunes.

## Remediación

- Exigir una política de complejidad de contraseña mínima en el registro
  y en el cambio de contraseña.
- Comprobar la contraseña elegida contra una base de datos de
  contraseñas filtradas (p. ej. API de HaveIBeenPwned) y rechazarla si
  aparece.
- Rate-limiting / bloqueo progresivo en `POST /login` tras varios
  intentos fallidos, para que un diccionario tarde en poder probarse.
- No derivar ni exponer nunca un hash de la contraseña real en una
  respuesta de API (`pw_hint`); si se necesita un "hint", debe ser algo
  elegido explícitamente por el usuario, nunca un hash de la contraseña.
