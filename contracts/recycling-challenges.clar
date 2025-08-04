(define-constant challenge-not-found (err u201))
(define-constant challenge-expired (err u202))
(define-constant challenge-full (err u203))
(define-constant already-joined (err u204))
(define-constant challenge-not-active (err u205))
(define-constant not-challenge-participant (err u206))
(define-constant challenge-not-ended (err u207))
(define-constant owner-only (err u208))

(define-data-var next-challenge-id uint u1)
(define-data-var total-challenges uint u0)

(define-map challenges uint
  {
    title: (string-ascii 50),
    description: (string-ascii 100),
    target-material: (string-ascii 20),
    target-weight: uint,
    bonus-reward: uint,
    max-participants: uint,
    current-participants: uint,
    start-height: uint,
    end-height: uint,
    creator: principal,
    active: bool,
    winner: (optional principal)
  }
)

(define-map challenge-participants {challenge-id: uint, participant: principal}
  {
    total-weight: uint,
    actions-count: uint,
    joined-at: uint,
    completed: bool
  }
)

(define-public (create-challenge 
  (title (string-ascii 50))
  (description (string-ascii 100))
  (target-material (string-ascii 20))
  (target-weight uint)
  (bonus-reward uint)
  (max-participants uint)
  (duration-blocks uint))
  (let
    (
      (challenge-id (var-get next-challenge-id))
      (end-height (+ stacks-block-height duration-blocks))
    )
    (asserts! (is-eq tx-sender (unwrap-panic (get-contract-owner))) owner-only)
    (map-set challenges challenge-id
      {
        title: title,
        description: description,
        target-material: target-material,
        target-weight: target-weight,
        bonus-reward: bonus-reward,
        max-participants: max-participants,
        current-participants: u0,
        start-height: stacks-block-height,
        end-height: end-height,
        creator: tx-sender,
        active: true,
        winner: none
      }
    )
    (var-set next-challenge-id (+ challenge-id u1))
    (var-set total-challenges (+ (var-get total-challenges) u1))
    (ok challenge-id)
  )
)

(define-public (join-challenge (challenge-id uint))
  (let
    (
      (challenge (unwrap! (map-get? challenges challenge-id) challenge-not-found))
      (participant-key {challenge-id: challenge-id, participant: tx-sender})
    )
    (asserts! (get active challenge) challenge-not-active)
    (asserts! (< stacks-block-height (get end-height challenge)) challenge-expired)
    (asserts! (< (get current-participants challenge) (get max-participants challenge)) challenge-full)
    (asserts! (is-none (map-get? challenge-participants participant-key)) already-joined)
    (map-set challenge-participants participant-key
      {
        total-weight: u0,
        actions-count: u0,
        joined-at: stacks-block-height,
        completed: false
      }
    )
    (map-set challenges challenge-id
      (merge challenge {current-participants: (+ (get current-participants challenge) u1)})
    )
    (ok true)
  )
)

(define-public (record-challenge-progress (challenge-id uint) (weight uint) (material (string-ascii 20)))
  (let
    (
      (challenge (unwrap! (map-get? challenges challenge-id) challenge-not-found))
      (participant-key {challenge-id: challenge-id, participant: tx-sender})
      (participant-data (unwrap! (map-get? challenge-participants participant-key) not-challenge-participant))
    )
    (asserts! (get active challenge) challenge-not-active)
    (asserts! (< stacks-block-height (get end-height challenge)) challenge-expired)
    (asserts! (is-eq material (get target-material challenge)) (err u999))
    (let
      (
        (new-total-weight (+ (get total-weight participant-data) weight))
        (new-actions-count (+ (get actions-count participant-data) u1))
        (completed (>= new-total-weight (get target-weight challenge)))
      )
      (map-set challenge-participants participant-key
        (merge participant-data
          {
            total-weight: new-total-weight,
            actions-count: new-actions-count,
            completed: completed
          }
        )
      )
      (ok completed)
    )
  )
)

(define-public (complete-challenge (challenge-id uint))
  (let
    (
      (challenge (unwrap! (map-get? challenges challenge-id) challenge-not-found))
    )
    (asserts! (is-eq tx-sender (get creator challenge)) owner-only)
    (asserts! (>= stacks-block-height (get end-height challenge)) challenge-not-ended)
    (asserts! (get active challenge) challenge-not-active)
    (let
      (
        (winner (find-challenge-winner challenge-id))
      )
      (map-set challenges challenge-id
        (merge challenge {active: false, winner: winner})
      )
      (ok winner)
    )
  )
)

(define-read-only (find-challenge-winner (challenge-id uint))
  (some tx-sender)
)

(define-read-only (get-challenge (challenge-id uint))
  (map-get? challenges challenge-id)
)

(define-read-only (get-participant-progress (challenge-id uint) (participant principal))
  (map-get? challenge-participants {challenge-id: challenge-id, participant: participant})
)

(define-read-only (get-challenge-stats)
  {
    total-challenges: (var-get total-challenges),
    next-challenge-id: (var-get next-challenge-id)
  }
)

(define-read-only (is-challenge-active (challenge-id uint))
  (match (map-get? challenges challenge-id)
    challenge (and (get active challenge) (< stacks-block-height (get end-height challenge)))
    false
  )
)

(define-read-only (get-contract-owner)
  (some 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
)
