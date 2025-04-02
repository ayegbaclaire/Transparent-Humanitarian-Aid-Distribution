;; Resource Tracking Contract
;; This contract monitors movement of supplies and funds

(define-data-var admin principal tx-sender)

;; Data structure for resources
(define-map resources
  { id: (string-ascii 36) }  ;; Unique identifier for each resource batch
  {
    resource-type: (string-ascii 20),  ;; e.g., "FOOD", "MEDICINE", "FUNDS"
    quantity: uint,
    unit: (string-ascii 10),
    source: (string-utf8 100),
    current-location: (string-utf8 100),
    status: (string-ascii 20),  ;; e.g., "IN_TRANSIT", "DELIVERED", "DISTRIBUTED"
    last-updated: uint
  }
)

;; Data structure for resource movement history
(define-map resource-history
  {
    resource-id: (string-ascii 36),
    timestamp: uint
  }
  {
    from-location: (string-utf8 100),
    to-location: (string-utf8 100),
    status: (string-ascii 20),
    updated-by: principal
  }
)

;; Public function to register a new resource batch
(define-public (register-resource
    (id (string-ascii 36))
    (resource-type (string-ascii 20))
    (quantity uint)
    (unit (string-ascii 10))
    (source (string-utf8 100))
    (location (string-utf8 100)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? resources { id: id })) (err u100))
    (ok (map-set resources
      { id: id }
      {
        resource-type: resource-type,
        quantity: quantity,
        unit: unit,
        source: source,
        current-location: location,
        status: "REGISTERED",
        last-updated: block-height
      }
    ))
  )
)

;; Public function to update resource status and location
(define-public (update-resource-status
    (id (string-ascii 36))
    (new-location (string-utf8 100))
    (new-status (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (match (map-get? resources { id: id })
      resource (begin
        ;; Record history
        (map-set resource-history
          {
            resource-id: id,
            timestamp: block-height
          }
          {
            from-location: (get current-location resource),
            to-location: new-location,
            status: new-status,
            updated-by: tx-sender
          }
        )
        ;; Update current status
        (ok (map-set resources
          { id: id }
          (merge resource {
            current-location: new-location,
            status: new-status,
            last-updated: block-height
          })
        ))
      )
      (err u404)
    )
  )
)

;; Read-only function to get resource details
(define-read-only (get-resource-details (id (string-ascii 36)))
  (map-get? resources { id: id })
)

;; Function to transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
