# IDOR en GET /api/grades?student={id}

## Resumen

`GET /api/grades?student={id}` devuelve los registros de notas del
estudiante indicado por `id`, pero el servidor nunca comprueba que ese
`id` pertenezca al usuario autenticado que hace la petición. Es un IDOR
(*Insecure Direct Object Reference*) de libro: el control de acceso
depende enteramente de que el cliente "se porte bien" y solo pida su
propio id.

## Explotación

1. Autenticarse como cualquier estudiante de bajo privilegio (aquí,
   `jdoe`).
2. En vez de `?student={mi_id}`, pedir el id de **otro** estudiante
   cualquiera (p. ej. `thanos`, `sf6wtjycbyev4ah`).
3. El servidor devuelve el array completo de notas de `thanos` —
   proyecto, nota, fechas — sin ningún error de autorización.

Se repitió la prueba contra varios ids de la lista filtrada en el HTML del
foro (ver `JWT_Forgery_Impersonation/Resources/deploy_log_comment.txt`)
y todos respondieron igual: acceso total sin relación con la cuenta
autenticada.

## Sobre el campo `flag` del propio endpoint

Cada registro de `grades` tiene un campo `flag`, pensado aparentemente
para premiar proyectos concretos. En la práctica, al recorrer todas las
cuentas conocidas solo el registro del **propio** atacante (`jdoe`) tenía
ese campo no vacío — y coincidía con una flag ya capturada por otra vía
(`FLAG{md5_1s_4_n4m3pl4t3_n0t_4_l0ck}`, ver `JWT_Forgery_Impersonation/`).
Es decir: este IDOR concreto no filtra una flag *nueva* de otras cuentas
(los registros de `thanos`, `benjamin`, etc. tenían `flag` vacío en el
momento de la prueba) — su impacto real es la exposición masiva de datos
académicos ajenos (notas, proyectos completados, progreso), no una flag
específica. Por eso esta carpeta no incluye un fichero `flag` propio.

## Impacto

- Exposición de datos académicos de cualquier estudiante a cualquier otro
  estudiante autenticado — notas, proyectos, progreso.
- Podría usarse para enumerar sistemáticamente el id de cada estudiante
  (son ids de PocketBase, no secuenciales, pero ya están filtrados en
  varios sitios de la app) y construir un dump completo de calificaciones
  de todo el campus.

## Remediación

- Validar en el servidor que el `student` solicitado coincide con el
  `sub` de la sesión autenticada, o que el solicitante tiene un rol con
  permiso explícito para ver notas ajenas (p. ej. `staff`/`god`).
- Aplicar reglas de acceso a nivel de colección en PocketBase (`grades`)
  en vez de confiar en que el proxy de la API FastAPI filtre correctamente
  — defensa en profundidad.
- No devolver nunca un campo `flag`/secreto dentro de una respuesta de API
  de datos de negocio normal (notas); si es un mecanismo de "logro", debe
  vivir en un endpoint propio con su propio control de acceso.
