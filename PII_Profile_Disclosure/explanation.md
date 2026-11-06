# PII expuesta en páginas de perfil públicas

## Resumen

`GET /profile/{user_id}` no exige ninguna autenticación — ni siquiera una
cookie de sesión cualquiera — para devolver el email del usuario en texto
plano. Combinado con que los ids de usuario se filtran en múltiples
sitios de la app (HTML del foro, respuestas de API, etc., ver
`JWT_Forgery_Impersonation/Resources/deploy_log_comment.txt`), cualquier
visitante anónimo puede resolver `id → email` para cualquier cuenta
conocida.

## Explotación

```
curl -s http://localhost:4942/profile/z4p1cnx47mfy50f
```

Sin cookie, sin headers de autenticación, sin nada — la respuesta incluye:

```html
<span style="color:var(--text-3);">Email</span>
<span class="mono" style="font-size:11px;">jdoe@student.42.tech</span>
```

## Impacto

- Enumeración de emails reales de estudiantes/staff a partir de sus ids
  (que ya están filtrados en el HTML del foro y en varias respuestas de
  API), sin necesidad de ninguna cuenta ni sesión.
- Base para ataques de phishing dirigido o para alimentar diccionarios de
  `md5(email)` contra el fallo de
  [`../Password_Reset_MD5_Token`](../Password_Reset_MD5_Token/explanation.md)
  — ambos fallos se combinan perfectamente: este da el email, el otro
  convierte ese email en una toma de cuenta completa.
- No hay flag asociada; es un hallazgo informativo de severidad baja por
  sí mismo, pero multiplica el impacto de otros fallos ya documentados.

## Remediación

- Exigir autenticación para ver cualquier página de perfil, propio o
  ajeno.
- Aunque se permita ver perfiles públicos (p. ej. para un directorio de
  estudiantes), nunca incluir el email en la vista pública — mostrar solo
  campos no sensibles (nombre, avatar, nivel, campus).
- Tratar el email como dato sensible en todo el sistema: no debería
  aparecer en ninguna respuesta que no requiera que el solicitante sea el
  propio usuario o un rol con permiso explícito.
