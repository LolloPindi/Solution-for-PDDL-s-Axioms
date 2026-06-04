(define (problem g4d) (:domain graph-connectivity)
  (:objects n1 n2 n3 n4 - node)
  (:init (link n1 n2) (link n3 n4))
  (:goal (connected)))
