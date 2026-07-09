; PDDL domain problem: NO axioms integration! The axioms have been COMPLETELY moved into the ASP file.

(define (domain dntp)
  (:requirements :strips :typing :equality :negative-preconditions :disjunctive-preconditions :conditional-effects :existential-preconditions)
  (:types
    node - object
    primary secondary - node
  )
  (:predicates
    (conn  ?x - node ?y - node)
    (close ?x - node ?y - node)
    (rem   ?x - node ?y - node)
    (full  ?x - secondary)
    (buildable ?x - node ?y - node)
    (mutable   ?x - node ?y - node)
    (le        ?x - node ?y - node)
  )

  (:action insP
    :parameters (?s - secondary ?p - primary)
    :precondition (and (buildable ?s ?p) (not (conn ?s ?p)) (not (rem ?s ?p)) (not (full ?s)))
    :effect (and (conn ?s ?p) (not (close ?s ?p)) (full ?s)))
  (:action insS
    :parameters (?s1 - secondary ?s2 - secondary)
    :precondition (and (le ?s1 ?s2) (buildable ?s1 ?s2) (not (conn ?s1 ?s2)) (not (rem ?s1 ?s2)) (not (full ?s1)) (not (full ?s2)))
    :effect (and (conn ?s1 ?s2) (not (close ?s1 ?s2)) (full ?s1) (full ?s2)))
  (:action delP
    :parameters (?s - secondary ?p - primary)
    :precondition (and (conn ?s ?p) (mutable ?s ?p) (not (close ?s ?p)) (full ?s))
    :effect (and (not (conn ?s ?p)) (rem ?s ?p) (not (full ?s))))
  (:action delS
    :parameters (?s1 - secondary ?s2 - secondary)
    :precondition (and (le ?s1 ?s2) (conn ?s1 ?s2) (mutable ?s1 ?s2) (not (close ?s1 ?s2)) (full ?s1) (full ?s2))
    :effect (and (not (conn ?s1 ?s2)) (rem ?s1 ?s2) (not (full ?s1)) (not (full ?s2))))
  (:action sw
    :parameters (?u - secondary ?v - node ?vp - node)
    :precondition (and (not (= ?u ?v)) (not (= ?u ?vp)) (not (= ?v ?vp))
      (imply (le ?u ?v)  (and (conn ?u ?v) (close ?u ?v)))
      (imply (le ?v ?u)  (and (conn ?v ?u) (close ?v ?u)))
      (imply (le ?u ?vp) (and (conn ?u ?vp) (not (close ?u ?vp))))
      (imply (le ?vp ?u) (and (conn ?vp ?u) (not (close ?vp ?u)))))
    :effect (and
      (when (le ?u ?v)  (not (close ?u ?v)))
      (when (le ?v ?u)  (not (close ?v ?u)))
      (when (le ?u ?vp) (close ?u ?vp))
      (when (le ?vp ?u) (close ?vp ?u))))
)
