;; EnvironmentalDAO Fund Contract
;; Conservation funding platform supporting climate projects through community governance

;; Define the governance token
(define-fungible-token env-dao-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-project-not-found (err u104))

;; Token metadata
(define-data-var token-name (string-ascii 32) "EnvDAO Token")
(define-data-var token-symbol (string-ascii 10) "ENVDAO")
(define-data-var token-decimals uint u6)

;; Fund and project tracking
(define-data-var total-fund uint u0)
(define-data-var next-project-id uint u1)

;; Community contributions tracking
(define-map community-funds principal uint)

;; Environmental project registry
(define-map environmental-projects uint {
  title: (string-ascii 100),
  category: (string-ascii 50),
  funding-required: uint,
  funds-raised: uint,
  project-owner: principal,
  status: (string-ascii 20),
  created-at: uint
})

;; Function 1: Fund Environmental Projects
;; Community members can contribute STX to support environmental initiatives
;; Contributors receive governance tokens based on their contribution
(define-public (fund-environmental-project (project-id uint) (amount uint))
  (begin
    (asserts! (> amount u0) err-invalid-amount)
    
    ;; Verify project exists
    (let ((project-data (unwrap! (map-get? environmental-projects project-id) err-project-not-found)))
      
      ;; Transfer STX from contributor to contract
      (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
      
      ;; Update contributor's total contributions
      (map-set community-funds tx-sender
               (+ (default-to u0 (map-get? community-funds tx-sender)) amount))
      
      ;; Update total fund pool
      (var-set total-fund (+ (var-get total-fund) amount))
      
      ;; Update project funding
      (map-set environmental-projects project-id
               (merge project-data {
                 funds-raised: (+ (get funds-raised project-data) amount)
               }))
      
      ;; Mint governance tokens (1:1 ratio for voting power)
      (try! (ft-mint? env-dao-token amount tx-sender))
      
      ;; Log funding event
      (print {
        event: "project-funded",
        project-id: project-id,
        contributor: tx-sender,
        amount: amount,
        total-raised: (+ (get funds-raised project-data) amount)
      })
      
      (ok true))))

;; Function 2: Register Environmental Project
;; Allows environmental organizations to register projects for community funding
(define-public (register-environmental-project 
                (title (string-ascii 100)) 
                (category (string-ascii 50)) 
                (funding-required uint))
  (begin
    (asserts! (> funding-required u0) err-invalid-amount)
    
    ;; Get current project ID
    (let ((project-id (var-get next-project-id)))
      
      ;; Register new environmental project
      (map-set environmental-projects project-id {
        title: title,
        category: category,
        funding-required: funding-required,
        funds-raised: u0,
        project-owner: tx-sender,
        status: "active",
        created-at: stacks-block-height
      })
      
      ;; Increment project ID counter
      (var-set next-project-id (+ project-id u1))
      
      ;; Log project registration
      (print {
        event: "project-registered",
        project-id: project-id,
        title: title,
        category: category,
        owner: tx-sender,
        funding-goal: funding-required
      })
      
      (ok project-id))))

;; Read-only functions for transparency and data access

;; Get total community fund
(define-read-only (get-total-fund)
  (ok (var-get total-fund)))

;; Get individual contributor's total contributions
(define-read-only (get-contributor-funds (contributor principal))
  (ok (default-to u0 (map-get? community-funds contributor))))

;; Get environmental project details
(define-read-only (get-project-details (project-id uint))
  (ok (map-get? environmental-projects project-id)))

;; Get governance token balance
(define-read-only (get-governance-tokens (account principal))
  (ok (ft-get-balance env-dao-token account)))

;; Get next available project ID
(define-read-only (get-next-project-id)
  (ok (var-get next-project-id)))

;; Get token information
(define-read-only (get-token-name)
  (ok (var-get token-name)))

(define-read-only (get-token-symbol)
  (ok (var-get token-symbol)))

(define-read-only (get-token-decimals)
  (ok (var-get token-decimals)))