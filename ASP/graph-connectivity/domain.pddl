(define (domain graph-connectivity)
  (:requirements :strips :typing :negative-preconditions :existential-preconditions)
  (:types node)
  (:predicates
    (edge ?x - node ?y - node)
    (link ?x - node ?y - node)
    (connected))
  (:derived (connected)
    (exists (?x - node ?y - node) (edge ?x ?y)))
  (:action build
    :parameters (?x - node ?y - node)
    :precondition (and (link ?x ?y) (not (edge ?x ?y)))
    :effect (edge ?x ?y))
)
