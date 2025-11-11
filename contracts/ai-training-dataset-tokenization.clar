(define-constant ERR_EXISTS u100)
(define-constant ERR_NOT_FOUND u101)
(define-constant ERR_UNAUTHORIZED u102)

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
