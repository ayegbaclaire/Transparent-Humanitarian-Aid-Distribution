;; Recipient Verification Contract
;; This contract validates the eligibility of aid beneficiaries

(define-data-var admin principal tx-sender)

;; Data structure for recipients
(define-map recipients
  { id: (string-ascii 36) }  ;; Unique identifier for each recipient
  {
    verified: bool,
    name: (string-utf8 100),
    location: (string-utf8 100),
    needs-category: (string-ascii 20),
    registration-time: uint,
    last-verification: uint
  }
)

;; Public function to register a new recipient
(define-public (register-recipient
    (id (string-ascii 36))
    (name (string-utf8 100))
    (location (string-utf8 100))
    (needs-category (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? recipients { id: id })) (err u100))
    (ok (map-set recipients
      { id: id }
      {
        verified: false,
        name: name,
        location: location,
        needs-category: needs-category,
        registration-time: block-height,
        last-verification: u0
      }
    ))
  )
)

;; Public function to verify a recipient
(define-public (verify-recipient (id (string-ascii 36)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? recipients { id: id })
      recipient (ok (map-set recipients
                    { id: id }
                    (merge recipient {
                      verified: true,
                      last-verification: block-height
                    })
                  ))
      (err u404)
    )
  )
)

;; Read-only function to check if a recipient is verified
(define-read-only (is-recipient-verified (id (string-ascii 36)))
  (match (map-get? recipients { id: id })
    recipient (ok (get verified recipient))
    (err u404)
  )
)

;; Read-only function to get recipient details
(define-read-only (get-recipient-details (id (string-ascii 36)))
  (map-get? recipients { id: id })
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
