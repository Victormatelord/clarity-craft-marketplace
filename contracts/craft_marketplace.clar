;; CraftTide Marketplace Contract - Enhanced Version

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-listing-exists (err u101))
(define-constant err-invalid-price (err u102))
(define-constant err-listing-not-found (err u103))
(define-constant err-not-seller (err u104))
(define-constant err-insufficient-funds (err u105))
(define-constant err-expired-listing (err u106))
(define-constant err-invalid-category (err u107))

;; Data vars
(define-data-var platform-fee uint u25) ;; 2.5% fee in basis points

;; Data maps
(define-map listings
    {seller: principal, item-id: uint}
    {
        title: (string-ascii 100),
        description: (string-utf8 500),
        price: uint,
        category: (string-ascii 20),
        expiry: uint,
        active: bool
    }
)

(define-map seller-stats
    principal
    {
        items-sold: uint,
        total-sales: uint,
        reputation-score: uint,
        total-ratings: uint
    }
)

;; Events
(define-data-var next-event-id uint u0)

(define-map marketplace-events
    uint
    {
        event-type: (string-ascii 20),
        seller: principal,
        item-id: uint,
        price: uint,
        timestamp: uint
    }
)

;; Public functions
(define-public (list-item (item-id uint) 
                         (title (string-ascii 100)) 
                         (description (string-utf8 500)) 
                         (price uint)
                         (category (string-ascii 20))
                         (expiry uint))
    (let ((listing {
            title: title,
            description: description,
            price: price,
            category: category,
            expiry: (+ block-height expiry),
            active: true
        }))
        (asserts! (> price u0) err-invalid-price)
        (asserts! (is-valid-category category) err-invalid-category)
        (if (is-none (map-get? listings {seller: tx-sender, item-id: item-id}))
            (begin
                (map-set listings {seller: tx-sender, item-id: item-id} listing)
                (create-marketplace-event "LIST" tx-sender item-id price)
                (ok true))
            err-listing-exists)
    )
)

(define-public (purchase-item (seller principal) (item-id uint))
    (let (
        (listing (unwrap! (map-get? listings {seller: seller, item-id: item-id}) err-listing-not-found))
        (price (get price listing))
        (fee (/ (* price (var-get platform-fee)) u1000))
    )
        (asserts! (get active listing) err-listing-not-found)
        (asserts! (<= block-height (get expiry listing)) err-expired-listing)
        (try! (stx-transfer? price tx-sender seller))
        (try! (stx-transfer? fee seller contract-owner))
        (map-set listings {seller: seller, item-id: item-id} 
            (merge listing { active: false }))
        (update-seller-stats seller price)
        (create-marketplace-event "PURCHASE" seller item-id price)
        (ok true)
    )
)

;; Private functions
(define-private (is-valid-category (category (string-ascii 20)))
    (let ((valid-categories (list "art" "crafts" "supplies" "tools" "other")))
        (default-to false (some (lambda (valid) (is-eq category valid)) valid-categories))
    )
)

(define-private (create-marketplace-event 
    (event-type (string-ascii 20)) 
    (seller principal) 
    (item-id uint) 
    (price uint))
    (let ((event-id (var-get next-event-id)))
        (map-set marketplace-events
            event-id
            {
                event-type: event-type,
                seller: seller,
                item-id: item-id,
                price: price,
                timestamp: block-height
            }
        )
        (var-set next-event-id (+ event-id u1))
    )
)

;; Read only functions
(define-read-only (get-listing (seller principal) (item-id uint))
    (ok (map-get? listings {seller: seller, item-id: item-id}))
)

(define-read-only (get-seller-stats (seller principal))
    (ok (map-get? seller-stats seller))
)

(define-read-only (get-event (event-id uint))
    (ok (map-get? marketplace-events event-id))
)
