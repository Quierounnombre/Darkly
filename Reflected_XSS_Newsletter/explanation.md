# Reflected XSS en /newsletter

## Resumen

`POST /newsletter` acepta cualquier string en el campo `email`, sin
ninguna validación de formato, y redirige a
`GET /newsletter?email=...&msg=subscribed`. Esa página renderiza el
banner `"You're now subscribed with: ___"` incrustando el valor de
`email` **sin escapar** — a diferencia del atributo `value="..."` del
propio input del formulario, que sí está correctamente escapado. Es
decir, hay dos sitios que reflejan el mismo parámetro y solo uno de ellos
tiene el fallo.

Los propios desarrolladores lo reconocen en comentarios HTML (ver
`Resources/html_comments.txt`):

> wil: the "subscribed with: ___" banner echoes your email straight back.
> sophie: unescaped?? wil: define "unescaped".
>
> emilie: someone subscribed with a `<script>` tag last week. wil: bold
> of them. it worked.

## Explotación

```
POST /newsletter
email=<script>alert(document.domain)</script>
```

→ `302` a
`/newsletter?email=%3Cscript%3Ealert(document.domain)%3C/script%3E&msg=subscribed`
→ el banner de esa página renderiza:

```html
<div class="alert alert-success">You're now subscribed with: <script>alert(document.domain)</script></div>
```

El script se ejecuta en el navegador de quien abra ese enlace.

## Impacto

XSS reflejado clásico: un atacante puede construir un enlace a
`/newsletter?email=<payload>&msg=subscribed` y distribuirlo (phishing,
foro, email) para ejecutar JavaScript arbitrario en el navegador de
cualquier víctima que lo abra, en el contexto de la aplicación legítima
— robo de cookies no-`httponly`, acciones en nombre de la víctima, etc.
No se encontró ninguna flag asociada a este vector específico; es un
hallazgo informativo/de impacto medio por sí mismo, aunque se podría
encadenar con el robo de cookies de sesión igual que en
[`../Stored_XSS_Session_Hijack`](../Stored_XSS_Session_Hijack/explanation.md)
si se consigue que una víctima con sesión privilegiada abra el enlace.

## Remediación

- Escapar siempre el valor de `email` al renderizarlo en HTML (usar el
  autoescapado del motor de plantillas de forma consistente — el propio
  código ya lo hace bien en el atributo `value`, solo falta aplicarlo
  también en el texto del banner).
- Validar el formato de email en el servidor antes de aceptar la
  suscripción; un string que no parece un email no debería ni llegar a
  guardarse.
- Añadir una Content-Security-Policy que limite la ejecución de scripts
  inline, como defensa adicional si un escape se olvida en el futuro.
