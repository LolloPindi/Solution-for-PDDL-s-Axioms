; NOTE: THIS FILE IS DEFINED SOLELY FOR TESTING PURPOSES. THE ACTUAL FILE IS domain_dntp_noaxioms
(define (domain dntp)
  (:requirements :strips :typing :equality :negative-preconditions :disjunctive-preconditions :conditional-effects)

  (:types 
    node - object 
    primary secondary - node
  )

  (:predicates
    ;; FLUENTS
    (conn  ?x - node ?y - node)        ; line {x,y} exists
    (close ?x - node ?y - node)        ; line {x,y} is closed
    (rem   ?x - node ?y - node)        ; line {x,y} removed
    (full  ?x - secondary)             ; degree(s) = 3 where s is secondary

    ;; STATIC 
    (buildable ?x - node ?y - node)    ; {x,y} in E*
    (mutable   ?x - node ?y - node)    ; {x,y} is mutable
    (le        ?x - node ?y - node)    ; total canon ordering
    ;; (exEdge    ?x - node ?y - node) ; useless? yes

    ;; DERIVED FLUENTS
    (RAD)  
    (RESTORE)
    (RESTORE1-primaryFall)
    (RESTORE3-edgeFall)
    (RC          ?x - node ?y - node)                     ; reachable close   
    (RCO         ?x - node ?y - node)                     ; reachable open-close (useless)
    (RCO-EX      ?x - node ?y - node ?w - node)           ; reachable open-close excluding node ?w
    (RCO-noE     ?x - node ?y - node ?w - node ?z - node) ; reachable open-closed excluding edge (?w ?z)
  )

  ;; AXIOMS
  (:derived (RAD)
    (and 
      ;; Each secondary has a primary
      (forall (?s - secondary)
        (exists (?p - primary)
          (and
            (RC ?s ?p))))
      ;; Each connected component has a single primary
      (forall (?p1 - primary ?p2 - primary)
        (imply
          (and (le ?p1 ?p2) (not (= ?p1 ?p2)))
          (not (RC ?p1 ?p2))))
    )
  )

  (:derived (RC ?x - node ?y - node)
    (and
      (le ?x ?y)
      (or
        ;; Case base
        (and 
             ;; (le ?x ?y)
             (conn ?x ?y)
             (close ?x ?y))

        ;; Recursive case
        (exists (?u - node)
          (and
            (not (= ?u ?x))

            (or
              (and 
                   ;; (exEdge ?x ?u)
                   (le ?x ?u)
                   (conn ?x ?u)
                   (close ?x ?u))
              (and 
                   ;; (exEdge ?u ?x)
                   (le ?u ?x)
                   (conn ?u ?x)
                   (close ?u ?x)))

            (or
              (and (le ?u ?y)
                   (RC ?u ?y))
              (and (le ?y ?u)
                   (RC ?y ?u))))))))

  (:derived (RESTORE)
    (and
      (RESTORE1-primaryFall)
      (RESTORE3-edgeFall)
    ))

  ;; PREVIOUS VERSION
  ;;(:derived (RESTORE1-primaryFall)
  ;;  (forall (?v - secondary ?p - primary)
  ;;    (imply
  ;;      (RC ?v ?p)
  ;;      (exists (?p2 - primary)
  ;;        (and
  ;;          (not (= ?p2 ?p))
  ;;
  ;;          (RCO ?v ?p2))))))

  (:derived (RESTORE1-primaryFall)
    (forall (?z - primary)            
      (forall (?x - secondary)
        (exists (?y - primary)
          (and
            (not (= ?y ?z))
            (RCO-EX ?x ?y ?z))))))

  (:derived (RESTORE3-edgeFall)
    (forall (?w - secondary ?z - primary)
      (imply
        (and (le ?w ?z) (conn ?w ?z))
        (forall (?x - secondary)
          (exists (?y - primary)
            (RCO-noE ?x ?y ?w ?z))))))

  ;; x could be a secondary?
  (:derived (RCO-EX ?x - node ?y - node ?z - node)
    (and
      (le ?x ?y)

      (not (= ?x ?z))
      (not (= ?y ?z))

      (or
        (conn ?x ?y)

        (exists (?u - secondary)
          (and
            (not (= ?u ?x))
            (not (= ?u ?z))
            ;;(not (= ?u ?y)) ;;optimisation?

            (or
              (and (le ?x ?u) (conn ?x ?u))
              (and (le ?u ?x) (conn ?u ?x)))

            (or
              (and (le ?u ?y) (RCO-EX ?u ?y ?z))
              (and (le ?y ?u) (RCO-EX ?y ?u ?z))))))))

  (:derived (RCO-noE ?x - node ?y - node ?w - node ?z - node)
    (and
      (le ?x ?y) (le ?w ?z)
      (or
        ;; Case base
        (and
          (le ?x ?y) ;; redundant?
          (conn ?x ?y)
          (not (and (= ?x ?w) (= ?y ?z))))

        ;; Recursive case
        ;; my note: it is not probably necessary to restrict to secondary
        ;; neverthless, it is not a problem
        (exists (?u - secondary) ;; No primary along the path
          (and
            (not (= ?u ?x))

            (or
              (and
                (le ?x ?u)
                (conn ?x ?u)
                ;; if A < U => link (A,U), then test that A != C and U != D ((C,D) forbidden)
                (not (and (= ?x ?w) (= ?u ?z))))

              (and
                (le ?u ?x)
                (conn ?u ?x)
                ;; if U < A => link (U,A), then test that U != C and A != D ((C,D) forbidden)
                (not (and (= ?u ?w) (= ?x ?z))))
            )

            ;; enforce canonical order in RC-noE based on U < B or B < U
            ;; C < D enforced in the precondition
            (or
              (and (le ?u ?y)
                   (RCO-noE ?u ?y ?w ?z))
              (and (le ?y ?u)
                   (RCO-noE ?y ?u ?w ?z))))))))

  ;; Insert a new open line {s,p}
  (:action insP
    :parameters (?s - secondary ?p - primary)
    :precondition (and
      (RAD)
      (RESTORE)
      (buildable ?s ?p)
      (not (conn ?s ?p))
      (not (rem ?s ?p))
      (not (full ?s)))
    :effect (and
      (conn ?s ?p)
      (not (close ?s ?p))
      (full ?s))
  )

  ;; Insert a new open line {s,s'} where s < s'
  (:action insS
    :parameters (?s1 - secondary ?s2 - secondary)
    :precondition (and
      (RAD)
      (RESTORE)
      (le ?s1 ?s2)
      (buildable ?s1 ?s2)
      (not (conn ?s1 ?s2))
      (not (rem ?s1 ?s2))
      (not (full ?s1))
      (not (full ?s2)))
    :effect (and
      (conn ?s1 ?s2)
      (not (close ?s1 ?s2))
      (full ?s1)
      (full ?s2))
  )

  ;; Delete an existing open line {s,p}
  (:action delP
    :parameters (?s - secondary ?p - primary)
    :precondition (and
      (RAD)
      (RESTORE)
      (conn ?s ?p)
      (mutable ?s ?p)
      (not (close ?s ?p))
      (full ?s))
    :effect (and
      (not (conn ?s ?p))
      (rem ?s ?p)
      (not (full ?s)))
  )

  ;; Delete an existing open line {s,s'} where s < s'
  (:action delS
    :parameters (?s1 - secondary ?s2 - secondary)
    :precondition (and
      (RAD)
      (RESTORE)
      (le ?s1 ?s2)
      (conn ?s1 ?s2)
      (mutable ?s1 ?s2)
      (not (close ?s1 ?s2))
      (full ?s1) (full ?s2))
    :effect (and
      (not (conn ?s1 ?s2))
      (rem ?s1 ?s2)
      (not (full ?s1))
      (not (full ?s2)))
  )

  ;; Close {u,v'} and open {u,v}
  (:action sw
    :parameters (?u - secondary ?v - node ?vp - node)

    :precondition (and
      (RAD)
      (RESTORE)
      (not (= ?u ?v)) (not (= ?u ?vp)) (not (= ?v ?vp))
      (imply (le ?u ?v)  (and (conn ?u ?v) (close ?u ?v)))
      (imply (le ?v ?u)  (and (conn ?v ?u) (close ?v ?u)))
      (imply (le ?u ?vp) (and (conn ?u ?vp) (not (close ?u ?vp))))
      (imply (le ?vp ?u) (and (conn ?vp ?u) (not (close ?vp ?u))))
    )

    :effect (and
      (when (le ?u ?v)  (not (close ?u ?v)))
      (when (le ?v ?u)  (not (close ?v ?u)))
      (when (le ?u ?vp) (close ?u ?vp))
      (when (le ?vp ?u) (close ?vp ?u))
    )
  )

)
