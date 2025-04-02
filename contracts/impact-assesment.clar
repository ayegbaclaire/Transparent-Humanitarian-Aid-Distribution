;; Impact Assessment Contract
;; This contract measures effectiveness of assistance programs

(define-data-var admin principal tx-sender)

;; Data structure for programs
(define-map programs
  { id: (string-ascii 36) }  ;; Unique program ID
  {
    name: (string-utf8 100),
    description: (string-utf8 500),
    start-time: uint,
    end-time: uint,
    status: (string-ascii 20),  ;; e.g., "ACTIVE", "COMPLETED", "CANCELLED"
    target-metrics: (list 10 (string-ascii 50))
  }
)

;; Data structure for impact metrics
(define-map impact-metrics
  {
    program-id: (string-ascii 36),
    metric-name: (string-ascii 50)
  }
  {
    value: uint,
    last-updated: uint,
    updated-by: principal
  }
)

;; Public function to register a new program
(define-public (register-program
    (id (string-ascii 36))
    (name (string-utf8 100))
    (description (string-utf8 500))
    (target-metrics (list 10 (string-ascii 50))))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? programs { id: id })) (err u100))
    (ok (map-set programs
      { id: id }
      {
        name: name,
        description: description,
        start-time: block-height,
        end-time: u0,
        status: "ACTIVE",
        target-metrics: target-metrics
      }
    ))
  )
)

;; Public function to update program status
(define-public (update-program-status
    (id (string-ascii 36))
    (new-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? programs { id: id })
      program (ok (map-set programs
                { id: id }
                (merge program {
                  status: new-status,
                  end-time: (if (is-eq new-status "COMPLETED") block-height (get end-time program))
                })
              ))
      (err u404)
    )
  )
)

;; Public function to record impact metric
(define-public (record-metric
    (program-id (string-ascii 36))
    (metric-name (string-ascii 50))
    (value uint))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-some (map-get? programs { id: program-id })) (err u404))
    (ok (map-set impact-metrics
      {
        program-id: program-id,
        metric-name: metric-name
      }
      {
        value: value,
        last-updated: block-height,
        updated-by: tx-sender
      }
    ))
  )
)

;; Read-only function to get program details
(define-read-only (get-program-details (id (string-ascii 36)))
  (map-get? programs { id: id })
)

;; Read-only function to get metric value
(define-read-only (get-metric-value (program-id (string-ascii 36)) (metric-name (string-ascii 50)))
  (map-get? impact-metrics { program-id: program-id, metric-name: metric-name })
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
