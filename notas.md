# Darkly — Guide

## JDOE
**Info:** jdoe account vulnerable to rockyou.txt
**URL:** http://localhost:4942/forum/6viy7xi64gxpan3

## Backend Exposed
**Info:** Backend expuesto en puerto 8090
**URL:** 
- http://localhost:8090/
- http://localhost:8090/_/#/login

## Newsletter
**Info:** may be breached?? it eats any string
**URL:** 
- http://localhost:4942/newsletter

## API
**Info:** API con método POST
**URLs:**
- http://localhost:4942/api/telemetry/heartbeat
- http://localhost:4942/api/users
- http://localhost:4942/api/collect
- http://localhost:4942/api/grades
- http://localhost:4942/staff/dashboard
- GET /api/grades?student={id}

## Exfiltration & XSS
**Info:** Posible XSS vía forum custom HTML — inyección de script propio que devuelve documentos/datos. Confirmado con 3 scripts distintos (no es fluke).
**URL:** http://localhost:4942/forum/jzznlscxag3op86

## Staff Panel Unprotected
**Info:** Acceso directo a zona de staff — encontrado vía robots.txt
**URLs:**
- http://localhost:4942/staff
- http://localhost:4942/robots.txt

# Confirmed attacks

## PASS_RESET
**Info:** Confirmado — al resetear contraseña, 100% te deja cambiarla.
**URLs:**
- http://localhost:4942/forum/r8y1ib6ub8g47u2
- http://localhost:4942/reset-password?email=<STUDENT_EMAIL>&token=7c983aa3101755740f5fc820637a43d9
**Flag location:** http://localhost:4942/profile/me/settings
**Flag:** `r3s3t_t0k3n_w4s_just_md5_lol`

## API PATCH PRIVILEDGE SCALATION
**Info:** Usa el script de api_profile para cambiar permisos a distintos perfiles, remember to refresh the cookie in the script.
**URL:**
- http://localhost:4942/staff
- http://localhost:4942/api/profile This one is the attacked one
**Flag:** FLAG{just_p4tch_y0ur_0wn_r0l3_lol}

## JWT FORGED
**Info:** Los tokens de sesión son 3 partes en base64 `header.payload.signature`. El payload NO está cifrado,
solo firmado — se puede leer el `sub`/`login`/`role` de cualquier token sin conocer el secreto.
El secreto de firma sigue siendo uno de los históricos filtrados en el comentario HTML del deploy log:
`"42"` → `"42network"`. Verificado offline recalculando el HMAC-SHA256 de un token real y comparando
la firma — "42network" coincide. Informacion sacada del comentario:
v1.2.0 — sophie  — initial platform. jwt secret was "42". wil changed it to "42network". progress.

Con el secreto se puede **forjar un token nuevo para cualquier `sub` existente** (ej. el de `thanos`,
sacado de un token viejo en `scripts/patch_api_profile.sh`) sin conocer su contraseña ni pasar por /login.
Un `sub` que no existe en la DB es rechazado (302 a /login), así que el servidor sí valida que el usuario
exista — pero si existe, te autentica como esa persona sin más.

El `role` del token **no** se confía en todos los endpoints: `/staff/dashboard` revalida el rol real en
servidor y devuelve 403 "Insufficient privileges" para cualquier rol forjado (cadet/staff/admin/root) —
o sea, esto da *impersonación de cuenta*, no un salto automático de privilegios.

**Cómo usarlo en el navegador:** la cookie `session` tiene `httponly=false`, así que se puede pegar el
token forjado directo en DevTools → Application → Cookies, o por consola:
`document.cookie = "session=<token>; path=/"` y recargar.

**Script:** `scripts/forge_jwt.sh [role] [sub] [login]`

**Walkthrough al Flag:** En el forum el html tiene el ID del usuario que puso un post. De ahi saque el de Sophi.
Con el forjado me impersono en ese user y aparece el panel de Admin donde esta el Flag.

**Flag:** `FLAG{md5_1s_4_n4m3pl4t3_n0t_4_l0ck}`