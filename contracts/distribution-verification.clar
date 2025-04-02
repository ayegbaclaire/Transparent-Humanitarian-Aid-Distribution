;; Distribution Verification Contract
;; This contract confirms aid reaches intended recipients

(define-data-var admin principal tx-sender)

;; Data structure for aid distributions
(define-map distributions
  { id: (string-ascii 36) }  ;; Unique distribution ID
  {
    resource-id: (string-ascii 36),
    recipient-id: (string-ascii 36),
    quantity: uint,
    distribution-time: uint,
    distributor: principal,
    verified: bool,
    verification-time: uint,
    verification-method: (string-ascii 20)  ;; e.g., "SIGNATURE", "BIOMETRIC", "PHOTO"
  }
)

;; Public function to record a distribution
(define-public (record-distribution
    (id (string-ascii 36))
    (resource-id (string-ascii 36))
    (recipient-id (string-ascii 36))
    (quantity uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? distributions { id: id })) (err u100))
    (ok (map-set distributions
      { id: id }
      {
        resource-id: resource-id,
        recipient-id: recipient-id,
        quantity: quantity,
        distribution-time: block-height,
        distributor: tx-sender,
        verified: false,
        verification-time: u0,
        verification-method: ""
      }
    ))
  )
)

;; Public function to verify a distribution
(define-public (verify-distribution
    (id (string-ascii 36))
    (verification-method (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? distributions { id: id })
      distribution (ok (map-set distributions
                    { id: id }
                    (merge distribution {
                      verified: true,
                      verification-time: block-height,
                      verification-method: verification-method
                    })
                  ))
      (err u404)
    )
  )
)

;; Read-only function to get distribution details
(define-read-only (get-distribution-details (id (string-ascii 36)))
  (map-get? distributions { id: id })
)

;; Read-only function to check if a distribution is verified
(define-read-only (is-distribution-verified (id (string-ascii 36)))
  (match (map-get? distributions { id: id })
    distribution (ok (get verified distribution))
    (err u404)
  )
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
