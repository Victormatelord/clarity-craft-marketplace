;; CraftTide Marketplace Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-listing-exists (err u101))
(define-constant err-invalid-price (err u102))
(define-constant err-listing-not-found (err u103))
(define-constant err-not-seller (err u104))
(define-constant err-insufficient-funds (err u105))

;; Data vars
(define-data-var platform-fee uint u25) ;; 2.5% fee in basis points

;; Data maps
(define-map listings
    principal
    {
        item-id: uint,
        title: (string-ascii 100),
        description: (string-utf8 500),
        price: uint,
        seller: principal,
        active: bool
    }
)

(define-map seller-stats
    principal
    {
        items-sold: uint,
        total-sales: uint,
        reputation-score: uint
    }
)

;; Public functions
(define-public (list-item (item-id uint) (title (string-ascii 100)) (description (string-utf8 500)) (price uint))
    (let ((listing {
            item-id: item-id,
            title: title,
            description: description,
            price: price,
            seller: tx-sender,
            active: true
        }))
        (asserts! (> price u0) err-invalid-price)
        (if (is-none (map-get? listings tx-sender))
            (begin
                (map-set listings tx-sender listing)
                (ok true))
            err-listing-exists)
    )
)

(define-public (purchase-item (seller principal))
    (let (
        (listing (unwrap! (map-get? listings seller) err-listing-not-found))
        (price (get price listing))
        (fee (/ (* price (var-get platform-fee)) u1000))
    )
        (asserts! (get active listing) err-listing-not-found)
        (try! (stx-transfer? price tx-sender seller))
        (try! (stx-transfer? fee seller contract-owner))
        (map-set listings seller (merge listing { active: false }))
        (update-seller-stats seller price)
        (ok true)
    )
)

(define-public (update-listing (new-price uint))
    (let ((listing (unwrap! (map-get? listings tx-sender) err-listing-not-found)))
        (asserts! (> new-price u0) err-invalid-price)
        (map-set listings tx-sender (merge listing { price: new-price }))
        (ok true)
    )
)

(define-public (remove-listing)
    (let ((listing (unwrap! (map-get? listings tx-sender) err-listing-not-found)))
        (map-delete listings tx-sender)
        (ok true)
    )
)

;; Private functions
(define-private (update-seller-stats (seller principal) (sale-amount uint))
    (let (
        (current-stats (default-to
            { items-sold: u0, total-sales: u0, reputation-score: u0 }
            (map-get? seller-stats seller)
        ))
    )
        (map-set seller-stats
            seller
            {
                items-sold: (+ (get items-sold current-stats) u1),
                total-sales: (+ (get total-sales current-stats) sale-amount),
                reputation-score: (+ (get reputation-score current-stats) u1)
            }
        )
    )
)

;; Read only functions
(define-read-only (get-listing (seller principal))
    (ok (map-get? listings seller))
)

(define-read-only (get-seller-stats (seller principal))
    (ok (map-get? seller-stats seller))
)