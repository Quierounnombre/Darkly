# XML Entity Expansion ("Billion Laughs") en /agenda/import

## Resumen

`POST /agenda/import` parsea el XML subido con `xml.etree.ElementTree`
(stdlib de Python), que expande entidades internas definidas en el propio
documento sin ningún límite de profundidad/tamaño. Es la base del ataque
clásico "Billion Laughs": entidades que se referencian entre sí
multiplican su tamaño final exponencialmente con cada nivel de anidación.

Esto es un vector **distinto** al de
[`../XXE_SSRF_Internal_Config`](../XXE_SSRF_Internal_Config/explanation.md):
aquel usa una entidad **externa** (`SYSTEM "http://..."`) para forzar al
servidor a hacer una petición HTTP y filtrar su respuesta (SSRF). Este
usa solo entidades **internas**, sin tocar red ni filesystem, y el
objetivo es agotar CPU/memoria del proceso que parsea el XML.

## Explotación (a escala segura)

```xml
<?xml version="1.0"?>
<!DOCTYPE agenda [
  <!ENTITY a "lol">
  <!ENTITY b "&a;&a;&a;&a;&a;">
  <!ENTITY c "&b;&b;&b;&b;&b;">
]>
<agenda>
  <event>
    <title>&c;</title>
    <date>2042-01-15</date>
  </event>
</agenda>
```

`&c;` se expande a `&b;` repetido 5 veces, y cada `&b;` se expande a
`&a;` repetido 5 veces → título final de 5×5×3 = 75 caracteres
(`lollollol...`), confirmado en ~0.09s. Con más niveles de anidación
(cada nivel multiplica, no suma) el tamaño final crece exponencialmente
— el ataque "Billion Laughs" clásico usa ~9 niveles de `&entN;&entN;...`
×10 para llegar a ~10⁹ caracteres y agotar memoria/CPU en segundos.

**Deliberadamente no se ejecutó esa versión a gran escala** contra el
laboratorio compartido — provocar una denegación de servicio real no
aporta más evidencia que confirmar el mecanismo a pequeña escala, y sí
tiene coste (tirar el servicio para cualquier otra prueba en curso). El
PoC de arriba basta para demostrar que el parser no tiene ningún límite
de expansión.

## Sobre `SYSTEM "file://..."`

A diferencia de las entidades externas vía HTTP (que SÍ funcionan, ver
el otro hallazgo de XXE), `SYSTEM "file:///etc/hostname"` fue probado y
el servidor devuelve un error — la lectura de ficheros locales por esta
vía está bloqueada. No está claro si es por el parser, por una capa
intermedia, o pura casualidad de cómo se construye la URL de la entidad;
no se investigó más a fondo porque no aporta un nuevo vector de impacto
una vez que el SSRF vía HTTP ya es explotable.

## Impacto

Denegación de servicio (agotamiento de CPU/memoria) para cualquier
usuario autenticado que pueda llegar a `/agenda/import`, sin necesidad de
ningún otro fallo. No se encontró ninguna flag asociada a este vector en
concreto.

## Remediación

- La remediación es la misma que para el XXE/SSRF: sustituir
  `xml.etree.ElementTree` por `defusedxml`, que deshabilita por defecto
  tanto entidades externas como la expansión excesiva de entidades
  internas (hay protección específica contra "billion laughs" integrada).
- Si no se puede migrar de inmediato, fijar límites explícitos de
  tamaño de entrada y de profundidad/cantidad de expansión de entidades
  en el parser actual.
- Aplicar límites de tiempo/memoria por petición a nivel de
  infraestructura (timeout, límite de recursos del proceso) como defensa
  en profundidad adicional.
