# WIP — sin flag confirmada todavía

Scripts y pistas de vectores que no han llegado a dar una flag completa, así
que no tienen carpeta de breach propia todavía (la estructura de entrega
exige un `flag` real por carpeta). Ver `notas.md` en la raíz para el detalle
de cada uno.

- `quick.sh` — fuerza bruta con `ffuf` + rockyou.txt contra el superusuario
  de PocketBase (`wil@42.fr`) en `/api/collections/_superusers/auth-with-password`.
- `log_with_user_into_db.sh` — auto-registro de usuarios directamente en
  PocketBase (`POST /api/collections/users/records`) y lectura de
  `grades` con un token de usuario normal; pendiente de confirmar si esto
  da acceso a algo que no se pueda ver ya por otra vía.

Cuando alguno de estos dé una flag real, se le crea su propia carpeta
`{Breach name}/` con `exploit.sh` + `explanation.md` + `flag` + `Resources/`,
igual que el resto.
