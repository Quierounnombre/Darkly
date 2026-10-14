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
