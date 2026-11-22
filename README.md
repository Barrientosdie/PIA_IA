# Dominio PDDL: `cloud-deploy`

Proyecto final de planificación. Modela el lanzamiento a producción de microservicios con un pipeline CI/CD.

## Archivos
- `domain.pddl`: predicados y acciones.
- `problem.pddl`: lanzar `api-gateway`, que depende de `auth-service`.
- `plan.txt`: plan de 13 pasos encontrado con Pyperplan (BFS).
- `DISENO.md`: documentación del proceso de diseño.

## Cómo reproducir
1. Abrir https://editor.planning.domains/ y pegar `domain.pddl` y `problem.pddl`.
2. Elegir un planificador y presionar *Solve*.
3. O por terminal: `pip install pyperplan && pyperplan -s bfs domain.pddl problem.pddl`.
