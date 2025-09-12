(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_DATASET_NOT_FOUND (err u101))
(define-constant ERR_INSUFFICIENT_FUNDS (err u102))
(define-constant ERR_LICENSE_EXPIRED (err u103))
(define-constant ERR_ALREADY_LICENSED (err u104))
(define-constant ERR_INVALID_LICENSE_TYPE (err u105))
(define-constant ERR_DATASET_ALREADY_EXISTS (err u106))
(define-constant ERR_INVALID_RATING (err u107))
(define-constant ERR_ALREADY_RATED (err u108))
(define-constant ERR_NO_ACCESS_HISTORY (err u109))
(define-constant ERR_SUBSCRIPTION_EXISTS (err u110))
(define-constant ERR_NO_ACTIVE_SUBSCRIPTION (err u111))
(define-constant ERR_INSUFFICIENT_SUBSCRIPTION_BALANCE (err u112))

(define-data-var next-dataset-id uint u1)
(define-data-var platform-fee-rate uint u250)

(define-map datasets
  uint
  {
    creator: principal,
    name: (string-ascii 64),
    description: (string-ascii 256),
    size-mb: uint,
    data-hash: (buff 32),
    commercial-price: uint,
    research-price: uint,
    created-at: uint,
    total-revenue: uint
  })

(define-map dataset-licenses
  {dataset-id: uint, licensee: principal}
  {
    license-type: (string-ascii 32),
    expires-at: uint,
    purchased-at: uint,
    price-paid: uint
  })

(define-map user-licenses
  principal
  (list 50 uint))

(define-map license-usage
  {dataset-id: uint, licensee: principal}
  {
    download-count: uint,
    last-accessed: uint,
    usage-quota: uint
  })

(define-map creator-earnings
  principal
  uint)

(define-map dataset-ratings
  {dataset-id: uint, rater: principal}
  {
    rating: uint,
    comment: (string-ascii 256),
    rated-at: uint
  })

(define-map dataset-reputation
  uint
  {
    total-ratings: uint,
    rating-sum: uint,
    average-rating: uint
  })

(define-map dataset-subscriptions
  {dataset-id: uint, subscriber: principal}
  {
    monthly-price: uint,
    balance: uint,
    auto-renew: bool,
    created-at: uint,
    last-payment: uint,
    is-active: bool
  })

(define-map subscription-usage
  {dataset-id: uint, subscriber: principal}
  {
    monthly-downloads: uint,
    total-downloads: uint,
    current-period-start: uint
  })

(define-public (mint-dataset 
  (name (string-ascii 64))
  (description (string-ascii 256))
  (size-mb uint)
  (data-hash (buff 32))
  (commercial-price uint)
  (research-price uint))
  (let ((dataset-id (var-get next-dataset-id)))
    (asserts! (> commercial-price u0) ERR_INVALID_LICENSE_TYPE)
    (asserts! (> research-price u0) ERR_INVALID_LICENSE_TYPE)
    (asserts! (> size-mb u0) ERR_INVALID_LICENSE_TYPE)
    (asserts! (is-none (map-get? datasets dataset-id)) ERR_DATASET_ALREADY_EXISTS)
    (map-set datasets dataset-id {
      creator: tx-sender,
      name: name,
      description: description,
      size-mb: size-mb,
      data-hash: data-hash,
      commercial-price: commercial-price,
      research-price: research-price,
      created-at:stacks-block-height,
      total-revenue: u0
    })
    (var-set next-dataset-id (+ dataset-id u1))
    (ok dataset-id)))

(define-public (purchase-license 
  (dataset-id uint)
  (license-type (string-ascii 32))
  (duration-blocks uint))
  (let ((dataset (unwrap! (map-get? datasets dataset-id) ERR_DATASET_NOT_FOUND))
        (price (if (is-eq license-type "commercial")
                  (get commercial-price dataset)
                  (get research-price dataset)))
        (expires-at (+ stacks-block-height duration-blocks))
        (platform-fee (/ (* price (var-get platform-fee-rate)) u10000))
        (creator-payment (- price platform-fee)))
    (asserts! (or (is-eq license-type "commercial") (is-eq license-type "research")) ERR_INVALID_LICENSE_TYPE)
    (asserts! (is-none (map-get? dataset-licenses {dataset-id: dataset-id, licensee: tx-sender})) ERR_ALREADY_LICENSED)
    (try! (stx-transfer? price tx-sender CONTRACT_OWNER))
    (map-set dataset-licenses 
      {dataset-id: dataset-id, licensee: tx-sender}
      {
        license-type: license-type,
        expires-at: expires-at,
        purchased-at:stacks-block-height,
        price-paid: price
      })
    (map-set license-usage
      {dataset-id: dataset-id, licensee: tx-sender}
      {
        download-count: u0,
        last-accessed: u0,
        usage-quota: (if (is-eq license-type "commercial") u1000 u100)
      })
    (let ((current-licenses (default-to (list) (map-get? user-licenses tx-sender))))
      (map-set user-licenses tx-sender (unwrap-panic (as-max-len? (append current-licenses dataset-id) u50))))
    (map-set creator-earnings 
      (get creator dataset)
      (+ (default-to u0 (map-get? creator-earnings (get creator dataset))) creator-payment))
    (map-set datasets dataset-id
      (merge dataset {total-revenue: (+ (get total-revenue dataset) price)}))
    (ok true)))

(define-public (access-dataset (dataset-id uint))
  (let ((license (unwrap! (map-get? dataset-licenses {dataset-id: dataset-id, licensee: tx-sender}) ERR_NOT_AUTHORIZED))
        (usage (unwrap! (map-get? license-usage {dataset-id: dataset-id, licensee: tx-sender}) ERR_NOT_AUTHORIZED)))
    (asserts! (> (get expires-at license) stacks-block-height) ERR_LICENSE_EXPIRED)
    (asserts! (> (get usage-quota usage) (get download-count usage)) ERR_INSUFFICIENT_FUNDS)
    (map-set license-usage
      {dataset-id: dataset-id, licensee: tx-sender}
      (merge usage {
        download-count: (+ (get download-count usage) u1),
        last-accessed:stacks-block-height
      }))
    (ok true)))

(define-public (extend-license 
  (dataset-id uint)
  (additional-blocks uint))
  (let ((license (unwrap! (map-get? dataset-licenses {dataset-id: dataset-id, licensee: tx-sender}) ERR_NOT_AUTHORIZED))
        (dataset (unwrap! (map-get? datasets dataset-id) ERR_DATASET_NOT_FOUND))
        (extension-price (/ (* (get commercial-price dataset) additional-blocks) u4320))
        (platform-fee (/ (* extension-price (var-get platform-fee-rate)) u10000))
        (creator-payment (- extension-price platform-fee)))
    (try! (stx-transfer? extension-price tx-sender CONTRACT_OWNER))
    (map-set dataset-licenses
      {dataset-id: dataset-id, licensee: tx-sender}
      (merge license {expires-at: (+ (get expires-at license) additional-blocks)}))
    (map-set creator-earnings 
      (get creator dataset)
      (+ (default-to u0 (map-get? creator-earnings (get creator dataset))) creator-payment))
    (ok true)))

(define-public (withdraw-earnings)
  (let ((earnings (default-to u0 (map-get? creator-earnings tx-sender))))
    (asserts! (> earnings u0) ERR_INSUFFICIENT_FUNDS)
    (map-delete creator-earnings tx-sender)
    (try! (as-contract (stx-transfer? earnings tx-sender CONTRACT_OWNER)))
    (ok earnings)))

(define-public (update-platform-fee (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (<= new-rate u1000) ERR_INVALID_LICENSE_TYPE)
    (var-set platform-fee-rate new-rate)
    (ok true)))

(define-public (rate-dataset 
  (dataset-id uint)
  (rating uint)
  (comment (string-ascii 256)))
  (let ((dataset (unwrap! (map-get? datasets dataset-id) ERR_DATASET_NOT_FOUND))
        (existing-rating (map-get? dataset-ratings {dataset-id: dataset-id, rater: tx-sender}))
        (license-usage-data (map-get? license-usage {dataset-id: dataset-id, licensee: tx-sender}))
        (current-reputation (default-to {total-ratings: u0, rating-sum: u0, average-rating: u0} 
                           (map-get? dataset-reputation dataset-id))))
    (asserts! (>= rating u1) ERR_INVALID_RATING)
    (asserts! (<= rating u5) ERR_INVALID_RATING)
    (asserts! (is-none existing-rating) ERR_ALREADY_RATED)
    (asserts! (is-some license-usage-data) ERR_NO_ACCESS_HISTORY)
    (asserts! (> (get download-count (unwrap-panic license-usage-data)) u0) ERR_NO_ACCESS_HISTORY)
    (map-set dataset-ratings 
      {dataset-id: dataset-id, rater: tx-sender}
      {
        rating: rating,
        comment: comment,
        rated-at: stacks-block-height
      })
    (let ((new-total (+ (get total-ratings current-reputation) u1))
          (new-sum (+ (get rating-sum current-reputation) rating)))
      (map-set dataset-reputation dataset-id {
        total-ratings: new-total,
        rating-sum: new-sum,
        average-rating: (/ (* new-sum u100) new-total)
      }))
    (ok true)))

(define-public (subscribe-to-dataset 
  (dataset-id uint)
  (monthly-price uint)
  (prepaid-months uint)
  (auto-renew bool))
  (let ((dataset (unwrap! (map-get? datasets dataset-id) ERR_DATASET_NOT_FOUND))
        (existing-subscription (map-get? dataset-subscriptions {dataset-id: dataset-id, subscriber: tx-sender}))
        (total-payment (* monthly-price prepaid-months))
        (platform-fee (/ (* total-payment (var-get platform-fee-rate)) u10000))
        (creator-payment (- total-payment platform-fee)))
    (asserts! (> monthly-price u0) ERR_INVALID_LICENSE_TYPE)
    (asserts! (> prepaid-months u0) ERR_INVALID_LICENSE_TYPE)
    (asserts! (is-none existing-subscription) ERR_SUBSCRIPTION_EXISTS)
    (try! (stx-transfer? total-payment tx-sender CONTRACT_OWNER))
    (map-set dataset-subscriptions 
      {dataset-id: dataset-id, subscriber: tx-sender}
      {
        monthly-price: monthly-price,
        balance: prepaid-months,
        auto-renew: auto-renew,
        created-at: stacks-block-height,
        last-payment: stacks-block-height,
        is-active: true
      })
    (map-set subscription-usage
      {dataset-id: dataset-id, subscriber: tx-sender}
      {
        monthly-downloads: u0,
        total-downloads: u0,
        current-period-start: stacks-block-height
      })
    (map-set creator-earnings 
      (get creator dataset)
      (+ (default-to u0 (map-get? creator-earnings (get creator dataset))) creator-payment))
    (map-set datasets dataset-id
      (merge dataset {total-revenue: (+ (get total-revenue dataset) total-payment)}))
    (ok true)))

(define-public (access-dataset-subscription (dataset-id uint))
  (let ((subscription (unwrap! (map-get? dataset-subscriptions {dataset-id: dataset-id, subscriber: tx-sender}) ERR_NO_ACTIVE_SUBSCRIPTION))
        (usage (unwrap! (map-get? subscription-usage {dataset-id: dataset-id, subscriber: tx-sender}) ERR_NO_ACTIVE_SUBSCRIPTION))
        (blocks-per-month u4320)
        (current-period-elapsed (- stacks-block-height (get current-period-start usage)))
        (is-new-period (>= current-period-elapsed blocks-per-month)))
    (asserts! (get is-active subscription) ERR_NO_ACTIVE_SUBSCRIPTION)
    (asserts! (> (get balance subscription) u0) ERR_INSUFFICIENT_SUBSCRIPTION_BALANCE)
    (if is-new-period
      (let ((new-balance (- (get balance subscription) u1)))
        (map-set dataset-subscriptions
          {dataset-id: dataset-id, subscriber: tx-sender}
          (merge subscription {balance: new-balance, is-active: (> new-balance u0)}))
        (map-set subscription-usage
          {dataset-id: dataset-id, subscriber: tx-sender}
          {
            monthly-downloads: u1,
            total-downloads: (+ (get total-downloads usage) u1),
            current-period-start: stacks-block-height
          }))
      (map-set subscription-usage
        {dataset-id: dataset-id, subscriber: tx-sender}
        (merge usage {
          monthly-downloads: (+ (get monthly-downloads usage) u1),
          total-downloads: (+ (get total-downloads usage) u1)
        })))
    (ok true)))

(define-public (cancel-subscription (dataset-id uint))
  (let ((subscription (unwrap! (map-get? dataset-subscriptions {dataset-id: dataset-id, subscriber: tx-sender}) ERR_NO_ACTIVE_SUBSCRIPTION)))
    (asserts! (get is-active subscription) ERR_NO_ACTIVE_SUBSCRIPTION)
    (map-set dataset-subscriptions
      {dataset-id: dataset-id, subscriber: tx-sender}
      (merge subscription {is-active: false, auto-renew: false}))
    (ok true)))

(define-public (renew-subscription 
  (dataset-id uint)
  (additional-months uint))
  (let ((subscription (unwrap! (map-get? dataset-subscriptions {dataset-id: dataset-id, subscriber: tx-sender}) ERR_NO_ACTIVE_SUBSCRIPTION))
        (dataset (unwrap! (map-get? datasets dataset-id) ERR_DATASET_NOT_FOUND))
        (renewal-payment (* (get monthly-price subscription) additional-months))
        (platform-fee (/ (* renewal-payment (var-get platform-fee-rate)) u10000))
        (creator-payment (- renewal-payment platform-fee)))
    (asserts! (> additional-months u0) ERR_INVALID_LICENSE_TYPE)
    (try! (stx-transfer? renewal-payment tx-sender CONTRACT_OWNER))
    (map-set dataset-subscriptions
      {dataset-id: dataset-id, subscriber: tx-sender}
      (merge subscription {
        balance: (+ (get balance subscription) additional-months),
        is-active: true,
        last-payment: stacks-block-height
      }))
    (map-set creator-earnings 
      (get creator dataset)
      (+ (default-to u0 (map-get? creator-earnings (get creator dataset))) creator-payment))
    (ok true)))

(define-read-only (get-dataset (dataset-id uint))
  (map-get? datasets dataset-id))

(define-read-only (get-license (dataset-id uint) (licensee principal))
  (map-get? dataset-licenses {dataset-id: dataset-id, licensee: licensee}))

(define-read-only (get-license-usage (dataset-id uint) (licensee principal))
  (map-get? license-usage {dataset-id: dataset-id, licensee: licensee}))

(define-read-only (get-user-licenses (user principal))
  (default-to (list) (map-get? user-licenses user)))

(define-read-only (get-creator-earnings (creator principal))
  (default-to u0 (map-get? creator-earnings creator)))

(define-read-only (get-platform-fee-rate)
  (var-get platform-fee-rate))

(define-read-only (get-next-dataset-id)
  (var-get next-dataset-id))

(define-read-only (check-license-validity (dataset-id uint) (licensee principal))
  (match (map-get? dataset-licenses {dataset-id: dataset-id, licensee: licensee})
    license (> (get expires-at license) stacks-block-height)
    false))

(define-read-only (get-license-time-remaining (dataset-id uint) (licensee principal))
  (match (map-get? dataset-licenses {dataset-id: dataset-id, licensee: licensee})
    license (if (> (get expires-at license) stacks-block-height)
              (some (- (get expires-at license) stacks-block-height))
              none)
    none))

(define-read-only (calculate-license-price (dataset-id uint) (license-type (string-ascii 32)) (duration-blocks uint))
  (match (map-get? datasets dataset-id)
    dataset (let ((base-price (if (is-eq license-type "commercial")
                               (get commercial-price dataset)
                               (get research-price dataset))))
              (some (* base-price (/ duration-blocks u4320))))
    none))

(define-read-only (get-dataset-rating (dataset-id uint) (rater principal))
  (map-get? dataset-ratings {dataset-id: dataset-id, rater: rater}))

(define-read-only (get-dataset-reputation (dataset-id uint))
  (default-to {total-ratings: u0, rating-sum: u0, average-rating: u0} 
             (map-get? dataset-reputation dataset-id)))

(define-read-only (get-dataset-average-rating (dataset-id uint))
  (match (map-get? dataset-reputation dataset-id)
    reputation (some (get average-rating reputation))
    none))

(define-read-only (get-top-rated-datasets (min-rating uint))
  (let ((reputation-1 (get-dataset-reputation u1))
        (reputation-2 (get-dataset-reputation u2))
        (reputation-3 (get-dataset-reputation u3))
        (reputation-4 (get-dataset-reputation u4))
        (reputation-5 (get-dataset-reputation u5)))
    (filter is-highly-rated 
           (list 
             {id: u1, avg: (get average-rating reputation-1)}
             {id: u2, avg: (get average-rating reputation-2)}
             {id: u3, avg: (get average-rating reputation-3)}
             {id: u4, avg: (get average-rating reputation-4)}
             {id: u5, avg: (get average-rating reputation-5)}))))

(define-private (is-highly-rated (dataset-info {id: uint, avg: uint}))
  (>= (get avg dataset-info) u400))

(define-read-only (get-subscription (dataset-id uint) (subscriber principal))
  (map-get? dataset-subscriptions {dataset-id: dataset-id, subscriber: subscriber}))

(define-read-only (get-subscription-usage (dataset-id uint) (subscriber principal))
  (map-get? subscription-usage {dataset-id: dataset-id, subscriber: subscriber}))

(define-read-only (check-subscription-active (dataset-id uint) (subscriber principal))
  (match (map-get? dataset-subscriptions {dataset-id: dataset-id, subscriber: subscriber})
    subscription (and (get is-active subscription) (> (get balance subscription) u0))
    false))

(define-read-only (get-subscription-time-remaining (dataset-id uint) (subscriber principal))
  (match (map-get? dataset-subscriptions {dataset-id: dataset-id, subscriber: subscriber})
    subscription (if (and (get is-active subscription) (> (get balance subscription) u0))
                   (some (get balance subscription))
                   none)
    none))

(define-read-only (calculate-subscription-cost (monthly-price uint) (months uint))
  (some (* monthly-price months)))
