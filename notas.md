# Guide

-> #Finding

-> ##Info

-> ##URL or additional notes

-> Flags

# JDOE
## Data
jdoe account vulnerable to rockyou.txt
## URLs
http://localhost:4942/forum/6viy7xi64gxpan3

# PASS_RESET
## Data
Posible vuln due to pass reset?
Confirmado, cuando reseteas contraseña 100% te deja cambiarla
## URLs
http://localhost:4942/forum/r8y1ib6ub8g47u2
http://localhost:4942/reset-password?email='AÑADA AQUI SU ESTUDIANTE'&token=7c983aa3101755740f5fc820637a43d9
## FLAGS
http://localhost:4942/profile/me/settings
r3s3t_t0k3n_w4s_just_md5_lol

# Backend Exposed
## Data
El backend esta expuesto en el puerto 8090
## URLs
http://localhost:8090/

# API?
## Data
Por aquí hay una API, metodo POST
## URLs
http://localhost:4942/api/telemetry/heartbeat
http://localhost:4942/api/users
http://localhost:4942/api/collect

# EXFILTRATION AND XSS
## Data
Se puede realizar XSS y exfiltración añadiendo en el forum custom html, puedes introducir un script propio y que te devuelva documentos y datos.
## URLs
http://localhost:4942/forum/jzznlscxag3op86
(This is a custom forum with 3 scripts to ensure it is not a fluke)

# STAFF FRONT DESPROTEGIDO
## Data
Se puede acceder a la zona de staff directamente, obtenido mirando el robots.txt
## URLs
http://localhost:4942/staff
http://localhost:4942/robots.txt
