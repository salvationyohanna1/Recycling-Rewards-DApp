(define-constant err-unauthorized (err u301))
(define-constant err-invalid-input (err u302))
(define-constant err-not-found (err u303))

(define-data-var total-co2-saved uint u0)
(define-data-var total-energy-saved uint u0)
(define-data-var total-landfill-diverted uint u0)

(define-map user-impact principal
  {
    co2-saved: uint,
    energy-saved: uint,
    landfill-diverted: uint,
    trees-equivalent: uint,
    last-updated: uint
  }
)

(define-map material-impact-rates (string-ascii 20)
  {
    co2-per-kg: uint,
    energy-per-kg: uint,
    landfill-per-kg: uint
  }
)

(define-public (initialize-impact-rates)
  (begin
    (map-set material-impact-rates "plastic"
      { co2-per-kg: u1800, energy-per-kg: u2000, landfill-per-kg: u1000 })
    (map-set material-impact-rates "glass"
      { co2-per-kg: u500, energy-per-kg: u300, landfill-per-kg: u1000 })
    (map-set material-impact-rates "metal"
      { co2-per-kg: u2500, energy-per-kg: u4000, landfill-per-kg: u1000 })
    (map-set material-impact-rates "paper"
      { co2-per-kg: u900, energy-per-kg: u1500, landfill-per-kg: u1000 })
    (ok true)
  )
)

(define-public (record-impact (user principal) (material (string-ascii 20)) (weight-grams uint))
  (let
    (
      (rates (unwrap! (map-get? material-impact-rates material) err-not-found))
      (current-impact (default-to 
        { co2-saved: u0, energy-saved: u0, landfill-diverted: u0, trees-equivalent: u0, last-updated: u0 }
        (map-get? user-impact user)))
      (co2-impact (/ (* weight-grams (get co2-per-kg rates)) u1000))
      (energy-impact (/ (* weight-grams (get energy-per-kg rates)) u1000))
      (landfill-impact (/ (* weight-grams (get landfill-per-kg rates)) u1000))
      (trees-saved (/ co2-impact u21772))
    )
    (map-set user-impact user
      {
        co2-saved: (+ (get co2-saved current-impact) co2-impact),
        energy-saved: (+ (get energy-saved current-impact) energy-impact),
        landfill-diverted: (+ (get landfill-diverted current-impact) landfill-impact),
        trees-equivalent: (+ (get trees-equivalent current-impact) trees-saved),
        last-updated: stacks-block-height
      }
    )
    (var-set total-co2-saved (+ (var-get total-co2-saved) co2-impact))
    (var-set total-energy-saved (+ (var-get total-energy-saved) energy-impact))
    (var-set total-landfill-diverted (+ (var-get total-landfill-diverted) landfill-impact))
    (ok { co2: co2-impact, energy: energy-impact, landfill: landfill-impact, trees: trees-saved })
  )
)

(define-read-only (get-user-impact (user principal))
  (map-get? user-impact user)
)

(define-read-only (get-global-impact)
  {
    total-co2-saved: (var-get total-co2-saved),
    total-energy-saved: (var-get total-energy-saved),
    total-landfill-diverted: (var-get total-landfill-diverted)
  }
)

(define-read-only (calculate-potential-impact (material (string-ascii 20)) (weight-grams uint))
  (let
    (
      (rates (unwrap! (map-get? material-impact-rates material) err-not-found))
    )
    (ok {
      co2-saved: (/ (* weight-grams (get co2-per-kg rates)) u1000),
      energy-saved: (/ (* weight-grams (get energy-per-kg rates)) u1000),
      landfill-diverted: (/ (* weight-grams (get landfill-per-kg rates)) u1000)
    })
  )
)

(define-read-only (get-impact-leaderboard-position (user principal))
  (match (map-get? user-impact user)
    impact (get co2-saved impact)
    u0
  )
)
