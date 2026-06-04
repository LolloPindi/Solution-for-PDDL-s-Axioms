(define (problem g4) (:domain graph-connectivity)
  (:objects n1 n2 n3 n4 - node)
  (:init (link n1 n2) (link n2 n3) (link n3 n4) (link n4 n1) (link n1 n3))
  (:goal (connected)))
