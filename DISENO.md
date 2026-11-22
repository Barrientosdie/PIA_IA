# Proceso de diseño

## Escenario elegido
Un equipo debe poner en producción dos microservicios: `auth-service` y `api-gateway`. El gateway no puede salir hasta que `auth-service` esté sano en producción. Elegí este escenario por que el orden de un despliegue importa tanto como las acciones mismas.

## Predicados y por qué existen
| Predicado | Razón |
|---|---|
| `code-committed ?s` | Punto de partida del pipeline. |
| `tests-passed ?s` | Compuerta de calidad antes de construir. |
| `image-built ?s` / `image-pushed ?s` | Separan construir de publicar; son dos fallos distintos en la vida real. |
| `uses-db ?s ?d`, `db-in-env ?d ?e` | Relacionan servicio, base de datos y entorno para saber dónde migrar. |
| `env-ready ?e` | El entorno debe estar aprovisionado antes de migrar o desplegar. |
| `db-migrated ?s` | Evita desplegar código que espera un esquema que aún no existe. |
| `no-dependencies ?s`, `depends-on ?s ?dep` | Modelan la dependencia entre servicios. |
| `deployed`, `healthy`, `live` | Tres estados distintos: desplegado, verificado y recibiendo tráfico. |

## Acciones 
| Acción | Precondiciones | Efectos |
|---|---|---|
| `run-tests` | `code-committed` | + `tests-passed`, − `code-committed` |
| `build-image` | `tests-passed` | + `image-built` |
| `push-image` | `image-built` | + `image-pushed` |
| `migrate-db` | `image-pushed`, `uses-db`, `db-in-env`, `env-ready` | + `db-migrated` |
| `deploy-independent` | `image-pushed`, `db-migrated`, `env-ready`, `no-dependencies` | + `deployed` |
| `deploy-dependent` | lo anterior + `depends-on` y `healthy ?dep ?e` | + `deployed` |
| `health-check` | `deployed` | + `healthy` |
| `route-traffic` | `healthy` | + `live` |

(`deploy-independent` y `deploy-dependent` son dos esquemas del mismo paso: así evité usar precondiciones cuantificadas y mantuve el dominio en STRIPS puro con tipos.)

## Cómo llegué al esquema final
1. **Primera versión:** una sola acción `deploy` con todo junto. El plan salía en 2 pasos: trivial.
2. **Separé el pipeline** en prueba, construcción y publicación. Cada una produce un hecho que la siguiente necesita.
3. **Agregué `migrate-db`** como requisito de despliegue, porque desplegar sin migrar rompe el servicio.
4. **Agregué la dependencia entre servicios.** Un primer intento exigía solo `deployed ?dep`, pero un servicio desplegado puede estar caído; por eso la condición pasó a `healthy ?dep`.
5. **Separé `health-check` y `route-traffic`**, de modo que "desplegado" no es lo mismo que "con usuarios".
6. **Resultado:** plan óptimo de 13 pasos para la meta `(live api-gateway prod)`.

## Diferencia con dominios de inspiración
- **Air Cargo:** mueve objetos entre ubicaciones (carga, vuelo, descarga). Aquí no hay movimiento: lo que avanza es el *estado de un artefacto* a través de etapas.
- **Blocks World:** el plan depende de apilar y desapilar. Aquí no hay acciones inversas; las etapas solo avanzan.
- **Aporte propio:** dependencias entre objetos del mismo tipo (`depends-on`) y una compuerta de salud (`healthy`) como precondición cruzada entre servicios.
