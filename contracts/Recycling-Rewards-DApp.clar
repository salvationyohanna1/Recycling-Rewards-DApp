(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-not-authorized (err u105))
(define-constant err-invalid-status (err u106))

(define-data-var total-recycling-actions uint u0)
(define-data-var total-rewards-distributed uint u0)
(define-data-var reward-rate uint u10)

(define-map recycling-centers principal 
  {
    name: (string-ascii 50),
    location: (string-ascii 100),
    active: bool,
    total-verifications: uint
  }
)

(define-map user-profiles principal
  {
    total-actions: uint,
    total-rewards: uint,
    reputation-score: uint,
    joined-at: uint
  }
)

(define-map recycling-actions uint
  {
    user: principal,
    center: principal,
    material-type: (string-ascii 20),
    weight: uint,
    reward-amount: uint,
    verified: bool,
    timestamp: uint,
    verification-hash: (string-ascii 64)
  }
)

(define-map pending-verifications uint
  {
    action-id: uint,
    verifier: principal,
    submitted-at: uint
  }
)

(define-data-var next-action-id uint u1)

(define-public (register-recycling-center (name (string-ascii 50)) (location (string-ascii 100)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? recycling-centers tx-sender)) err-already-exists)
    (ok (map-set recycling-centers tx-sender
      {
        name: name,
        location: location,
        active: true,
        total-verifications: u0
      }
    ))
  )
)

(define-public (register-user)
  (begin
    (asserts! (is-none (map-get? user-profiles tx-sender)) err-already-exists)
    (ok (map-set user-profiles tx-sender
      {
        total-actions: u0,
        total-rewards: u0,
        reputation-score: u100,
        joined-at: stacks-block-height
      }
    ))
  )
)

(define-public (submit-recycling-action (material-type (string-ascii 20)) (weight uint) (verification-hash (string-ascii 64)))
  (let
    (
      (action-id (var-get next-action-id))
      (user-profile (unwrap! (map-get? user-profiles tx-sender) err-not-found))
      (reward-amount (calculate-reward weight material-type))
    )
    (map-set recycling-actions action-id
      {
        user: tx-sender,
        center: contract-owner,
        material-type: material-type,
        weight: weight,
        reward-amount: reward-amount,
        verified: false,
        timestamp: stacks-block-height,
        verification-hash: verification-hash
      }
    )
    (var-set next-action-id (+ action-id u1))
    (var-set total-recycling-actions (+ (var-get total-recycling-actions) u1))
    (ok action-id)
  )
)

(define-public (verify-recycling-action (action-id uint))
  (let
    (
      (action (unwrap! (map-get? recycling-actions action-id) err-not-found))
      (center (unwrap! (map-get? recycling-centers tx-sender) err-not-authorized))
      (user-profile (unwrap! (map-get? user-profiles (get user action)) err-not-found))
    )
    (asserts! (get active center) err-not-authorized)
    (asserts! (not (get verified action)) err-invalid-status)
    (map-set recycling-actions action-id (merge action { verified: true }))
    (map-set recycling-centers tx-sender 
      (merge center { total-verifications: (+ (get total-verifications center) u1) })
    )
    (try! (distribute-reward (get user action) (get reward-amount action)))
    (ok true)
  )
)

(define-public (distribute-reward (user principal) (amount uint))
  (let
    (
      (user-profile (unwrap! (map-get? user-profiles user) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (stx-transfer? amount tx-sender user))
    (map-set user-profiles user
      (merge user-profile 
        {
          total-rewards: (+ (get total-rewards user-profile) amount),
          total-actions: (+ (get total-actions user-profile) u1),
          reputation-score: (+ (get reputation-score user-profile) u10)
        }
      )
    )
    (var-set total-rewards-distributed (+ (var-get total-rewards-distributed) amount))
    (ok amount)
  )
)

(define-public (update-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-rate u0) err-invalid-amount)
    (var-set reward-rate new-rate)
    (ok new-rate)
  )
)

(define-public (deactivate-recycling-center (center principal))
  (let
    (
      (center-data (unwrap! (map-get? recycling-centers center) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set recycling-centers center (merge center-data { active: false })))
  )
)

(define-public (fund-contract)
  (stx-transfer? u1000000 tx-sender (as-contract tx-sender))
)

(define-read-only (calculate-reward (weight uint) (material-type (string-ascii 20)))
  (let
    (
      (base-reward (* weight (var-get reward-rate)))
      (material-multiplier (get-material-multiplier material-type))
    )
    (* base-reward material-multiplier)
  )
)

(define-read-only (get-material-multiplier (material-type (string-ascii 20)))
  (if (is-eq material-type "plastic")
    u2
    (if (is-eq material-type "glass")
      u3
      (if (is-eq material-type "metal")
        u4
        (if (is-eq material-type "paper")
          u1
          u1
        )
      )
    )
  )
)

(define-read-only (get-recycling-action (action-id uint))
  (map-get? recycling-actions action-id)
)

(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles user)
)

(define-read-only (get-recycling-center (center principal))
  (map-get? recycling-centers center)
)

(define-read-only (get-contract-stats)
  {
    total-actions: (var-get total-recycling-actions),
    total-rewards: (var-get total-rewards-distributed),
    reward-rate: (var-get reward-rate),
    next-action-id: (var-get next-action-id)
  }
)

(define-read-only (get-user-reputation (user principal))
  (match (map-get? user-profiles user)
    profile (get reputation-score profile)
    u0
  )
)

(define-read-only (calculate-user-level (reputation uint))
  (if (>= reputation u1000)
    "Gold"
    (if (>= reputation u500)
      "Silver"
      (if (>= reputation u100)
        "Bronze"
        "Beginner"
      )
    )
  )
)

(define-read-only (is-action-verified (action-id uint))
  (match (map-get? recycling-actions action-id)
    action (get verified action)
    false
  )
)

(define-read-only (get-total-user-rewards (user principal))
  (match (map-get? user-profiles user)
    profile (get total-rewards profile)
    u0
  )
)
