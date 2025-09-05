(define-constant err-unauthorized (err u401))
(define-constant err-insufficient-balance (err u402))
(define-constant err-invalid-amount (err u403))
(define-constant err-trade-not-found (err u404))
(define-constant err-self-trade (err u405))

(define-data-var total-supply uint u0)
(define-data-var next-trade-id uint u1)
(define-data-var credit-rate uint u100)
(define-data-var redemption-rate uint u50)

(define-map balances principal uint)
(define-map last-mint-block principal uint)

(define-map trade-offers uint
  {
    seller: principal,
    amount: uint,
    price: uint,
    active: bool
  }
)

(define-public (mint-credits (user principal))
  (let
    (
      (impact (contract-call? .impact-tracker get-user-impact user))
      (last-mint (default-to u0 (map-get? last-mint-block user)))
      (current-balance (default-to u0 (map-get? balances user)))
    )
    (match impact
      impact-data
      (let
        (
          (co2-saved (get co2-saved impact-data))
          (credits-to-mint (/ co2-saved (var-get credit-rate)))
        )
        (asserts! (> stacks-block-height last-mint) err-unauthorized)
        (asserts! (> credits-to-mint u0) err-invalid-amount)
        (map-set balances user (+ current-balance credits-to-mint))
        (map-set last-mint-block user stacks-block-height)
        (var-set total-supply (+ (var-get total-supply) credits-to-mint))
        (ok credits-to-mint)
      )
      err-unauthorized
    )
  )
)

(define-public (create-trade-offer (amount uint) (price uint))
  (let
    (
      (trade-id (var-get next-trade-id))
      (user-balance (default-to u0 (map-get? balances tx-sender)))
    )
    (asserts! (>= user-balance amount) err-insufficient-balance)
    (asserts! (> amount u0) err-invalid-amount)
    (asserts! (> price u0) err-invalid-amount)
    (map-set balances tx-sender (- user-balance amount))
    (map-set trade-offers trade-id
      {
        seller: tx-sender,
        amount: amount,
        price: price,
        active: true
      }
    )
    (var-set next-trade-id (+ trade-id u1))
    (ok trade-id)
  )
)

(define-public (buy-credits (trade-id uint))
  (let
    (
      (trade (unwrap! (map-get? trade-offers trade-id) err-trade-not-found))
      (buyer-balance (default-to u0 (map-get? balances tx-sender)))
    )
    (asserts! (get active trade) err-trade-not-found)
    (asserts! (not (is-eq tx-sender (get seller trade))) err-self-trade)
    (try! (stx-transfer? (get price trade) tx-sender (get seller trade)))
    (map-set balances tx-sender (+ buyer-balance (get amount trade)))
    (map-set trade-offers trade-id (merge trade { active: false }))
    (ok (get amount trade))
  )
)

(define-public (redeem-credits (amount uint))
  (let
    (
      (user-balance (default-to u0 (map-get? balances tx-sender)))
      (stx-reward (* amount (var-get redemption-rate)))
    )
    (asserts! (>= user-balance amount) err-insufficient-balance)
    (asserts! (> amount u0) err-invalid-amount)
    (map-set balances tx-sender (- user-balance amount))
    (var-set total-supply (- (var-get total-supply) amount))
    (try! (as-contract (stx-transfer? stx-reward tx-sender tx-sender)))
    (ok stx-reward)
  )
)

(define-read-only (get-balance (user principal))
  (default-to u0 (map-get? balances user))
)

(define-read-only (get-trade-offer (trade-id uint))
  (map-get? trade-offers trade-id)
)

(define-read-only (get-total-supply)
  (var-get total-supply)
)

(define-read-only (calculate-mintable-credits (user principal))
  (match (contract-call? .impact-tracker get-user-impact user)
    impact-data (ok (/ (get co2-saved impact-data) (var-get credit-rate)))
    err-unauthorized
  )
)