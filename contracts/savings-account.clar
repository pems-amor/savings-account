;; ------------------------------
;; Savings Account with Interest
;; ------------------------------

(define-constant ERR_INSUFFICIENT_BALANCE u100)
(define-constant ERR_ZERO_AMOUNT u101)

;; Interest rate = 5% annualized (example)
;; We'll define rate per block (example: 5% / 2102400 blocks ~ blocks per year)
;; For simplicity, define rate and denom for fixed-point calc:

(define-constant INTEREST_RATE_PER_BLOCK u238) ;; e.g. 0.000238% per block (5% per year)
(define-constant RATE_DENOMINATOR u100000000) ;; scale denominator for decimals

;; Map to store user deposits: { amount: uint, last-update: uint }
(define-map deposits
  principal
  { amount: uint, last-update: uint })

;; -----------------------------------
;; Internal function: compute accrued interest
;; -----------------------------------
(define-read-only (compute-interest (principal principal))
  (let
    (
      ;; get deposit info, or default zeros
      (deposit-data (default-to { amount: u0, last-update: stacks-block-height } (map-get? deposits principal)))
      (amount (get amount deposit-data))
      (last-update (get last-update deposit-data))
      (blocks-passed (- stacks-block-height last-update))
    )
    ;; interest = blocks_passed * amount * rate / denom
    (ok (/ (* blocks-passed amount INTEREST_RATE_PER_BLOCK) RATE_DENOMINATOR))))

;; -----------------------------------
;; Deposit STX to savings
;; -----------------------------------
(define-data-var contract-balance uint u0) ;; store last known contract balance

(define-public (deposit (amount uint))
  (let (
        (prev-balance (var-get contract-balance))
        (new-balance (stx-get-balance (as-contract tx-sender))) ;; contract's balance after user sent STX
       )
    (if (or (<= amount u0) (< (- new-balance prev-balance) amount))
        (err ERR_ZERO_AMOUNT)
        (let ((deposit-data (default-to { amount: u0, last-update: stacks-block-height } (map-get? deposits tx-sender))))
          (let (
                 (interest (/ (* (- stacks-block-height (get last-update deposit-data)) (get amount deposit-data) INTEREST_RATE_PER_BLOCK) RATE_DENOMINATOR))
                 (new-amount (+ (get amount deposit-data) amount interest))
               )
            (begin
              (map-set deposits tx-sender { amount: new-amount, last-update: stacks-block-height })
              (var-set contract-balance new-balance)
              (ok true)))))))


;; -----------------------------------
;; Withdraw STX (principal + interest)
;; -----------------------------------
(define-public (withdraw (amount uint))
  (let ((deposit-data (default-to { amount: u0, last-update: stacks-block-height } (map-get? deposits tx-sender))))
    (let
      (
        (interest (/ (* (- stacks-block-height (get last-update deposit-data)) (get amount deposit-data) INTEREST_RATE_PER_BLOCK) RATE_DENOMINATOR))
        (total (+ (get amount deposit-data) interest))
      )
      (if (< total amount)
        (err ERR_INSUFFICIENT_BALANCE)
        (begin
          ;; update deposit amount (subtract withdrawn amount)
          (map-set deposits tx-sender { amount: (- total amount), last-update: stacks-block-height })
          ;; send STX out
          (stx-transfer? amount tx-sender tx-sender))))))

;; -----------------------------------
;; Claim interest only (leave principal)
;; -----------------------------------
(define-public (claim-interest)
  (let ((deposit-data (default-to { amount: u0, last-update: stacks-block-height } (map-get? deposits tx-sender))))
    (let ((interest (/ (* (- stacks-block-height (get last-update deposit-data)) (get amount deposit-data) INTEREST_RATE_PER_BLOCK) RATE_DENOMINATOR)))
      (if (<= interest u0)
        (err ERR_ZERO_AMOUNT)
        (begin
          ;; update deposit with last-update = current block (interest paid out)
          (map-set deposits tx-sender { amount: (get amount deposit-data), last-update: stacks-block-height })
          ;; send interest STX out
          (stx-transfer? interest tx-sender tx-sender))))))

;; -----------------------------------
;; Read-only: Get deposit info and accrued interest
;; -----------------------------------
(define-read-only (get-deposit (user principal))
  (ok (default-to { amount: u0, last-update: u0 } (map-get? deposits user))))

(define-read-only (get-accrued-interest (user principal))
  (compute-interest user))
