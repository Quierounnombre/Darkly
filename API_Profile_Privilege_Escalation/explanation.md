# Privilege Escalation vía PATCH /api/profile

## Resumen

`PATCH /api/profile` permite a un usuario autenticado actualizar su propio
perfil, y entre los campos aceptados está `role`. El servidor no comprueba
en ningún momento que el rol solicitado sea igual o inferior al rol actual
del usuario — solo valida que el valor pertenezca a la lista de roles
conocidos (`visitor`, `student`, `cadet`, `staff`, `god`, ver
`Resources/api_schema_leak.json`). El resultado es una escalada de
privilegios horizontal→vertical de libro.

## Vector de entrada

En `/staff` (listado en `robots.txt`, por tanto "descubrible") se leía:

```
Cadet access required. Try
PATCH /api/profile
with the right fields
...
<!-- also: PATCH /api/profile accepts a "role" field. the API schema documents which values are valid. -->
```

Es literalmente una pista de la propia aplicación.

## Explotación

1. Autenticarse como cualquier usuario de bajo privilegio (aquí, `jdoe`,
   `student`) — basta una sesión forjada con el secreto filtrado, ver
   [`../JWT_Forgery_Impersonation`](../JWT_Forgery_Impersonation/explanation.md).
2. `PATCH /api/profile` con body `{"role":"cadet"}`.
   - Pedir `staff` o `god` directamente es rechazado con
     `{"error":"role not assignable"}` — solo se permite subir a `cadet`
     desde el endpoint de perfil.
3. Reusar la MISMA cookie de sesión contra `GET /staff/dashboard`. La ruta
   valida el rol **real almacenado en la base de datos** (no el rol que
   venía en el JWT original), así que ya se concede acceso y se muestra:

   ```
   🔓 Cadet+ access granted — internal staff flag: FLAG{just_p4tch_y0ur_0wn_r0l3_lol}
   ```

## Impacto

Cualquier cuenta, sin importar su rol original, puede auto-promocionarse a
`cadet` y acceder al panel de staff (gestión de estudiantes, actividad de
evaluación, salud de la plataforma) sin autorización.

## Bonus / dato colateral

La respuesta de `PATCH /api/profile` devuelve el objeto de usuario
**completo**, incluido un campo `pw_hint` (hash MD5) que no debería
exponerse nunca a través de esta API — ver nota en `notas.md` bajo "JDOE",
pendiente de explotar del todo.

## Remediación

- Excluir `role` (y cualquier campo de autorización) de los campos
  editables por el propio usuario vía `PATCH /api/profile`; los cambios de
  rol deben pasar por un endpoint de administración separado, con su propio
  control de acceso basado en el rol ACTUAL del solicitante.
- Aplicar el principio de mínimo privilegio con una lista explícita de
  transiciones de rol permitidas (y quién puede ejecutarlas), no solo una
  lista de valores válidos.
- No devolver el objeto de usuario completo en la respuesta de un PATCH;
  devolver solo los campos relevantes y nunca campos sensibles como
  `pw_hint`, `recovery_code` o `private_note`.
