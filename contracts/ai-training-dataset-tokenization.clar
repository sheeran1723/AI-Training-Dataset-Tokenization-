(define-constant ERR_EXISTS u100)
(define-constant ERR_NOT_FOUND u101)
(define-constant ERR_UNAUTHORIZED u102)
(define-constant ERR_INVALID_PRICE u103)

(define-data-var next-id uint u0)

(define-map datasets
  uint
  {
    owner: principal,
    uri: (string-ascii 256),
    price: uint,
    active: bool
  })

(define-public (create-dataset (uri (string-ascii 256)) (price uint))
  (let ((new-id (+ (var-get next-id) u1)))
    (begin
      (var-set next-id new-id)
      (map-set datasets new-id {
        owner: tx-sender,
        uri: uri,
        price: price,
        active: true
      })
      (ok new-id))))

 

(define-read-only (get-dataset (id uint))
  (map-get? datasets id))

(define-public (update-price (id uint) (price uint))
  (match (map-get? datasets id)
    dataset
    (if (is-eq (get owner dataset) tx-sender)
        (begin
          (map-set datasets id {
            owner: (get owner dataset),
            uri: (get uri dataset),
            price: price,
            active: (get active dataset)
          })
          (ok true))
        (err ERR_UNAUTHORIZED))
    (err ERR_NOT_FOUND)))

(define-public (purchase-dataset (id uint))
  (match (map-get? datasets id)
    dataset
    (let ((price (get price dataset))
          (owner (get owner dataset)))
      (if (> price u0)
          (begin
            (try! (stx-transfer? price tx-sender owner))
            (map-set datasets id {
              owner: tx-sender,
              uri: (get uri dataset),
              price: price,
              active: (get active dataset)
            })
            (ok true))
          (err ERR_INVALID_PRICE)))
    (err ERR_NOT_FOUND)))
