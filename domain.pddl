;; Dominio: cloud-deploy
;; Pipeline de despliegue (CI/CD) de microservicios a un entorno en la nube.
;; Diseño propio: modela el orden obligado test -> build -> push -> migrar BD -> deploy
;; -> health check -> tráfico, y la dependencia entre servicios (un servicio solo se
;; despliega cuando aquel del que depende ya está sano en el mismo entorno).
(define (domain cloud-deploy)
  (:requirements :strips :typing)

  (:types service environment database)

  (:predicates
    (code-committed ?s - service)                      ; el código está en el repo
    (tests-passed ?s - service)                        ; pruebas automáticas aprobadas
    (image-built ?s - service)                         ; imagen de contenedor construida
    (image-pushed ?s - service)                        ; imagen subida al registro
    (uses-db ?s - service ?d - database)               ; el servicio usa esa BD
    (db-in-env ?d - database ?e - environment)         ; la BD vive en ese entorno
    (env-ready ?e - environment)                       ; el entorno está aprovisionado
    (db-migrated ?s - service)                         ; migraciones del servicio aplicadas
    (no-dependencies ?s - service)                     ; servicio independiente
    (depends-on ?s - service ?dep - service)           ; ?s necesita a ?dep en operación
    (deployed ?s - service ?e - environment)           ; desplegado en el entorno
    (healthy ?s - service ?e - environment)            ; health check exitoso
    (live ?s - service ?e - environment))              ; recibe tráfico de usuarios

  ;; 1. Correr pruebas
  (:action run-tests
    :parameters (?s - service)
    :precondition (code-committed ?s)
    :effect (and (tests-passed ?s)
                 (not (code-committed ?s))))

  ;; 2. Construir la imagen (solo si las pruebas pasaron)
  (:action build-image
    :parameters (?s - service)
    :precondition (tests-passed ?s)
    :effect (image-built ?s))

  ;; 3. Subir la imagen al registro
  (:action push-image
    :parameters (?s - service)
    :precondition (image-built ?s)
    :effect (image-pushed ?s))

  ;; 4. Migrar la base de datos del servicio dentro del entorno
  (:action migrate-db
    :parameters (?s - service ?d - database ?e - environment)
    :precondition (and (image-pushed ?s)
                       (uses-db ?s ?d)
                       (db-in-env ?d ?e)
                       (env-ready ?e))
    :effect (db-migrated ?s))

  ;; 5a. Desplegar un servicio sin dependencias
  (:action deploy-independent
    :parameters (?s - service ?e - environment)
    :precondition (and (image-pushed ?s)
                       (db-migrated ?s)
                       (env-ready ?e)
                       (no-dependencies ?s))
    :effect (deployed ?s ?e))

  ;; 5b. Desplegar un servicio que depende de otro ya sano en el mismo entorno
  (:action deploy-dependent
    :parameters (?s ?dep - service ?e - environment)
    :precondition (and (image-pushed ?s)
                       (db-migrated ?s)
                       (env-ready ?e)
                       (depends-on ?s ?dep)
                       (healthy ?dep ?e))
    :effect (deployed ?s ?e))

  ;; 6. Verificar salud del servicio desplegado
  (:action health-check
    :parameters (?s - service ?e - environment)
    :precondition (deployed ?s ?e)
    :effect (healthy ?s ?e))

  ;; 7. Enrutar tráfico real al servicio sano
  (:action route-traffic
    :parameters (?s - service ?e - environment)
    :precondition (healthy ?s ?e)
    :effect (live ?s ?e))
)
