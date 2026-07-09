(define (domain hybrid-robot)
  (:requirements :strips :typing :derived-predicates)
  
  (:types robot)
  
  (:predicates
    (moving ?r - robot)
    (has-battery ?r - robot)
    (solar-panel ?r - robot)
    (needs-maintenance ?r - robot)
    (is-powered ?r - robot)
  )

  (:derived (is-powered ?r - robot)
    (or (has-battery ?r) (solar-panel ?r))
  )

  ; NUOVA AZIONE: Ripara il robot, togliendo lo stato di manutenzione
  (:action repair
    :parameters (?r - robot)
    :precondition (needs-maintenance ?r)
    :effect (not (needs-maintenance ?r))
  )

  (:action start-moving
    :parameters (?r - robot)
    :precondition (is-powered ?r)
    :effect (moving ?r)
  )
)