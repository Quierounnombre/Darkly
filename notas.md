# Darkly — Guide

## JDOE
**Info:** jdoe account vulnerable to rockyou.txt
**URL:** http://localhost:4942/forum/6viy7xi64gxpan3

## PASS_RESET
**Info:** Confirmado — al resetear contraseña, 100% te deja cambiarla.
**URLs:**
- http://localhost:4942/forum/r8y1ib6ub8g47u2
- http://localhost:4942/reset-password?email=<STUDENT_EMAIL>&token=7c983aa3101755740f5fc820637a43d9
**Flag location:** http://localhost:4942/profile/me/settings
**Flag:** `r3s3t_t0k3n_w4s_just_md5_lol`

## Backend Exposed
**Info:** Backend expuesto en puerto 8090
**URL:** http://localhost:8090/

## API
**Info:** API con método POST
**URLs:**
- http://localhost:4942/api/telemetry/heartbeat
- http://localhost:4942/api/users
- http://localhost:4942/api/collect

## Exfiltration & XSS
**Info:** Posible XSS vía forum custom HTML — inyección de script propio que devuelve documentos/datos. Confirmado con 3 scripts distintos (no es fluke).
**URL:** http://localhost:4942/forum/jzznlscxag3op86

## Staff Panel Unprotected
**Info:** Acceso directo a zona de staff — encontrado vía robots.txt
**URLs:**
- http://localhost:4942/staff
- http://localhost:4942/robots.txt
