(define (problem test-01)
  (:domain hybrid-robot)
  
  (:objects
    rob1 rob2 - robot
  )
  
  (:init
    ; Rob1 è solare ma richiede manutenzione (Fatto statico)
    (solar-panel rob1)
    (needs-maintenance rob1)
    
    ; Rob2 ha la batteria ed è sano
    (has-battery rob2)
  )
  
  (:goal (and (moving rob1) (moving rob2) (not (needs-maintenance rob1))))
)