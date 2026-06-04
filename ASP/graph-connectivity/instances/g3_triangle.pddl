(define (problem g3) (:domain graph-connectivity)
  (:objects n1 n2 n3 - node)
  (:init (link n1 n2) (link n2 n3) (link n1 n3))
  (:goal (connected)))
