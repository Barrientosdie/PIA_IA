;; Problema: lanzar a producción "api-gateway", que depende de "auth-service".
(define (problem lanzamiento-produccion)
  (:domain cloud-deploy)

  (:objects
    auth-service api-gateway - service
    prod - environment
    auth-db gateway-db - database)

  (:init
    (code-committed auth-service)
    (code-committed api-gateway)
    (uses-db auth-service auth-db)
    (uses-db api-gateway gateway-db)
    (db-in-env auth-db prod)
    (db-in-env gateway-db prod)
    (env-ready prod)
    (no-dependencies auth-service)
    (depends-on api-gateway auth-service))

  ;; Meta: la puerta de enlace atiende usuarios en producción.
  ;; Implica desplegar antes auth-service (dependencia), así que el plan es largo.
  (:goal (live api-gateway prod))
)
