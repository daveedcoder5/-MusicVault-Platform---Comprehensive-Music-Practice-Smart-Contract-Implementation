;; MusicVault - Decentralized Music Practice Platform
;; A comprehensive blockchain-based music platform that tracks practice sessions,
;; rewards musical progress, and builds musician communities

;; Contract constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-insufficient-tokens (err u105))
(define-constant err-lesson-not-available (err u106))
(define-constant err-invalid-tempo (err u107))

;; Token constants
(define-constant token-name "MusicVault Harmony Token")
(define-constant token-symbol "MHT")
(define-constant token-decimals u6)
(define-constant token-max-supply u1800000000000) ;; 1.8 million tokens with 6 decimals

;; Reward amounts (in micro-tokens)
(define-constant reward-practice-session u45000000) ;; 45 MHT
(define-constant reward-song-mastery u80000000) ;; 80 MHT
(define-constant reward-lesson-teaching u95000000) ;; 95 MHT
(define-constant reward-performance u120000000) ;; 120 MHT
(define-constant reward-composition u100000000) ;; 100 MHT

;; Data variables
(define-data-var total-supply uint u0)
(define-data-var next-musician-id uint u1)
(define-data-var next-lesson-id uint u1)
(define-data-var next-performance-id uint u1)

;; Token balances
(define-map token-balances principal uint)

;; Musical instruments
(define-map instruments
  uint
  {
    name: (string-ascii 32),
    category: (string-ascii 16), ;; "string", "wind", "percussion", "keyboard"
    difficulty-level: uint, ;; 1-5
    learning-curve: uint, ;; 1-10
    price-range: uint, ;; 1-5
    verified: bool
  }
)

;; Musician profiles
(define-map musician-profiles
  principal
  {
    username: (string-ascii 32),
    skill-level: uint, ;; 1-10
    primary-instrument: uint,
    practice-hours: uint,
    songs-mastered: uint,
    lessons-taught: uint,
    performances-given: uint,
    compositions-created: uint,
    reputation-score: uint,
    join-date: uint,
    last-activity: uint
  }
)

;; Practice sessions
(define-map practice-sessions
  { musician: principal, session-date: uint }
  {
    instrument-id: uint,
    duration-minutes: uint,
    song-practiced: (string-ascii 128),
    technique-focus: (string-ascii 64),
    tempo-bpm: uint,
    practice-quality: uint, ;; 1-10
    notes: (string-ascii 300),
    recording-hash: (optional (buff 32)),
    metronome-used: bool
  }
)

;; Song repertoire
(define-map song-repertoire
  { musician: principal, song-title: (string-ascii 128) }
  {
    composer: (string-ascii 64),
    genre: (string-ascii 32),
    difficulty-level: uint, ;; 1-5
    mastery-level: uint, ;; 1-100
    first-learned: uint,
    last-practiced: uint,
    practice-count: uint,
    performance-ready: bool
  }
)

;; Music lessons
(define-map music-lessons
  uint
  {
    teacher: principal,
    instrument-id: uint,
    lesson-title: (string-ascii 128),
    description: (string-ascii 500),
    skill-level-target: uint, ;; 1-5
    duration-minutes: uint,
    lesson-fee: uint,
    max-students: uint,
    current-students: uint,
    scheduled-time: uint,
    lesson-content: (string-ascii 1000),
    completed: bool
  }
)

;; Lesson enrollments
(define-map lesson-enrollments
  { lesson-id: uint, student: principal }
  {
    enrollment-date: uint,
    attendance-confirmed: bool,
    progress-rating: uint, ;; 1-10
    feedback: (string-ascii 300),
    skill-improvement: bool
  }
)

;; Musical performances
(define-map performances
  uint
  {
    performer: principal,
    performance-title: (string-ascii 128),
    venue: (string-ascii 64),
    performance-type: (string-ascii 32), ;; "solo", "ensemble", "competition"
    song-list: (string-ascii 500),
    duration-minutes: uint,
    audience-size: uint,
    performance-date: uint,
    recording-hash: (optional (buff 32)),
    public: bool
  }
)

;; Musical compositions
(define-map compositions
  uint
  {
    composer: principal,
    title: (string-ascii 128),
    genre: (string-ascii 32),
    instruments-used: (string-ascii 200),
    tempo-bpm: uint,
    time-signature: (string-ascii 8),
    key-signature: (string-ascii 8),
    duration-minutes: uint,
    composition-date: uint,
    sheet-music-hash: (optional (buff 32)),
    audio-hash: (optional (buff 32)),
    public: bool
  }
)

;; Music theory assessments
(define-map theory-assessments
  { musician: principal, theory-area: (string-ascii 32) }
  {
    knowledge-level: uint, ;; 1-100
    assessment-date: uint,
    topics-mastered: uint,
    assessor: (optional principal),
    verified: bool
  }
)

;; Helper function to get or create musician profile
(define-private (get-or-create-profile (musician principal))
  (match (map-get? musician-profiles musician)
    profile profile
    {
      username: "",
      skill-level: u1,
      primary-instrument: u1,
      practice-hours: u0,
      songs-mastered: u0,
      lessons-taught: u0,
      performances-given: u0,
      compositions-created: u0,
      reputation-score: u100,
      join-date: stacks-block-height,
      last-activity: stacks-block-height
    }
  )
)

;; Token functions
(define-read-only (get-name)
  (ok token-name)
)

(define-read-only (get-symbol)
  (ok token-symbol)
)

(define-read-only (get-decimals)
  (ok token-decimals)
)

(define-read-only (get-balance (user principal))
  (ok (default-to u0 (map-get? token-balances user)))
)

(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

(define-private (mint-tokens (recipient principal) (amount uint))
  (let (
    (current-balance (default-to u0 (map-get? token-balances recipient)))
    (new-balance (+ current-balance amount))
    (new-total-supply (+ (var-get total-supply) amount))
  )
    (asserts! (<= new-total-supply token-max-supply) err-invalid-input)
    (map-set token-balances recipient new-balance)
    (var-set total-supply new-total-supply)
    (ok amount)
  )
)

(define-public (transfer (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (let (
    (sender-balance (default-to u0 (map-get? token-balances sender)))
  )
    (asserts! (is-eq tx-sender sender) err-unauthorized)
    (asserts! (>= sender-balance amount) err-insufficient-tokens)
    (try! (mint-tokens recipient amount))
    (map-set token-balances sender (- sender-balance amount))
    (print {action: "transfer", sender: sender, recipient: recipient, amount: amount, memo: memo})
    (ok true)
  )
)

;; Instrument management
(define-public (add-instrument (name (string-ascii 32)) (category (string-ascii 16))
                              (difficulty-level uint) (learning-curve uint) (price-range uint))
  (let (
    (instrument-id (var-get next-musician-id))
  )
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> (len category) u0) err-invalid-input)
    (asserts! (and (>= difficulty-level u1) (<= difficulty-level u5)) err-invalid-input)
    (asserts! (and (>= learning-curve u1) (<= learning-curve u10)) err-invalid-input)
    (asserts! (and (>= price-range u1) (<= price-range u5)) err-invalid-input)
    
    (map-set instruments instrument-id {
      name: name,
      category: category,
      difficulty-level: difficulty-level,
      learning-curve: learning-curve,
      price-range: price-range,
      verified: false
    })
    
    (var-set next-musician-id (+ instrument-id u1))
    (print {action: "instrument-added", instrument-id: instrument-id, name: name})
    (ok instrument-id)
  )
)

;; Practice session logging
(define-public (log-practice-session (instrument-id uint) (duration-minutes uint) (song-practiced (string-ascii 128))
                                    (technique-focus (string-ascii 64)) (tempo-bpm uint) (practice-quality uint)
                                    (notes (string-ascii 300)) (metronome-used bool))
  (let (
    (instrument (unwrap! (map-get? instruments instrument-id) err-not-found))
    (session-date (/ stacks-block-height u144)) ;; Daily grouping
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> duration-minutes u0) err-invalid-input)
    (asserts! (> (len song-practiced) u0) err-invalid-input)
    (asserts! (and (>= tempo-bpm u40) (<= tempo-bpm u300)) err-invalid-tempo)
    (asserts! (and (>= practice-quality u1) (<= practice-quality u10)) err-invalid-input)
    
    (map-set practice-sessions {musician: tx-sender, session-date: session-date} {
      instrument-id: instrument-id,
      duration-minutes: duration-minutes,
      song-practiced: song-practiced,
      technique-focus: technique-focus,
      tempo-bpm: tempo-bpm,
      practice-quality: practice-quality,
      notes: notes,
      recording-hash: none,
      metronome-used: metronome-used
    })
    
    ;; Update musician profile
    (map-set musician-profiles tx-sender
      (merge profile {
        practice-hours: (+ (get practice-hours profile) (/ duration-minutes u60)),
        reputation-score: (+ (get reputation-score profile) u5),
        last-activity: stacks-block-height
      })
    )
    
    ;; Award practice reward
    (try! (mint-tokens tx-sender reward-practice-session))
    
    ;; Award bonus for high quality practice
    (if (>= practice-quality u8)
      (begin
        (try! (mint-tokens tx-sender u20000000)) ;; 20 MHT bonus
        true
      )
      true
    )
    
    (print {action: "practice-session-logged", musician: tx-sender, duration: duration-minutes, quality: practice-quality})
    (ok true)
  )
)

;; Song mastery tracking
(define-public (update-song-mastery (song-title (string-ascii 128)) (composer (string-ascii 64))
                                   (genre (string-ascii 32)) (difficulty-level uint) (mastery-level uint))
  (let (
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len song-title) u0) err-invalid-input)
    (asserts! (> (len composer) u0) err-invalid-input)
    (asserts! (and (>= difficulty-level u1) (<= difficulty-level u5)) err-invalid-input)
    (asserts! (and (>= mastery-level u1) (<= mastery-level u100)) err-invalid-input)
    
    (map-set song-repertoire {musician: tx-sender, song-title: song-title} {
      composer: composer,
      genre: genre,
      difficulty-level: difficulty-level,
      mastery-level: mastery-level,
      first-learned: stacks-block-height,
      last-practiced: stacks-block-height,
      practice-count: u1,
      performance-ready: (>= mastery-level u80)
    })
    
    ;; Award song mastery if high level
    (if (>= mastery-level u90)
      (begin
        (try! (mint-tokens tx-sender reward-song-mastery))
        (map-set musician-profiles tx-sender
          (merge profile {
            songs-mastered: (+ (get songs-mastered profile) u1),
            reputation-score: (+ (get reputation-score profile) u15)
          })
        )
        true
      )
      (begin
        (map-set musician-profiles tx-sender (merge profile {last-activity: stacks-block-height}))
        true
      )
    )
    
    (print {action: "song-mastery-updated", musician: tx-sender, song-title: song-title, mastery: mastery-level})
    (ok true)
  )
)

;; Music lesson creation
(define-public (create-music-lesson (instrument-id uint) (lesson-title (string-ascii 128))
                                   (description (string-ascii 500)) (skill-level-target uint)
                                   (duration-minutes uint) (lesson-fee uint) (max-students uint)
                                   (lesson-content (string-ascii 1000)))
  (let (
    (lesson-id (var-get next-lesson-id))
    (instrument (unwrap! (map-get? instruments instrument-id) err-not-found))
    (teacher-profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len lesson-title) u0) err-invalid-input)
    (asserts! (> (len description) u0) err-invalid-input)
    (asserts! (and (>= skill-level-target u1) (<= skill-level-target u5)) err-invalid-input)
    (asserts! (> duration-minutes u0) err-invalid-input)
    (asserts! (> max-students u0) err-invalid-input)
    (asserts! (>= (get reputation-score teacher-profile) u180) err-unauthorized)
    
    (map-set music-lessons lesson-id {
      teacher: tx-sender,
      instrument-id: instrument-id,
      lesson-title: lesson-title,
      description: description,
      skill-level-target: skill-level-target,
      duration-minutes: duration-minutes,
      lesson-fee: lesson-fee,
      max-students: max-students,
      current-students: u0,
      scheduled-time: (+ stacks-block-height u720), ;; Future scheduling
      lesson-content: lesson-content,
      completed: false
    })
    
    ;; Update teacher profile
    (map-set musician-profiles tx-sender
      (merge teacher-profile {
        lessons-taught: (+ (get lessons-taught teacher-profile) u1),
        reputation-score: (+ (get reputation-score teacher-profile) u20),
        last-activity: stacks-block-height
      })
    )
    
    ;; Award lesson teaching reward
    (try! (mint-tokens tx-sender reward-lesson-teaching))
    
    (var-set next-lesson-id (+ lesson-id u1))
    (print {action: "music-lesson-created", lesson-id: lesson-id, teacher: tx-sender, instrument-id: instrument-id})
    (ok lesson-id)
  )
)

;; Performance logging
(define-public (log-performance (performance-title (string-ascii 128)) (venue (string-ascii 64))
                               (performance-type (string-ascii 32)) (song-list (string-ascii 500))
                               (duration-minutes uint) (audience-size uint) (public bool))
  (let (
    (performance-id (var-get next-performance-id))
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len performance-title) u0) err-invalid-input)
    (asserts! (> (len venue) u0) err-invalid-input)
    (asserts! (> (len performance-type) u0) err-invalid-input)
    (asserts! (> duration-minutes u0) err-invalid-input)
    
    (map-set performances performance-id {
      performer: tx-sender,
      performance-title: performance-title,
      venue: venue,
      performance-type: performance-type,
      song-list: song-list,
      duration-minutes: duration-minutes,
      audience-size: audience-size,
      performance-date: stacks-block-height,
      recording-hash: none,
      public: public
    })
    
    ;; Update performer profile
    (map-set musician-profiles tx-sender
      (merge profile {
        performances-given: (+ (get performances-given profile) u1),
        reputation-score: (+ (get reputation-score profile) u25),
        last-activity: stacks-block-height
      })
    )
    
    ;; Award performance reward
    (try! (mint-tokens tx-sender reward-performance))
    
    (var-set next-performance-id (+ performance-id u1))
    (print {action: "performance-logged", performance-id: performance-id, performer: tx-sender, title: performance-title})
    (ok performance-id)
  )
)

;; Composition creation
(define-public (create-composition (title (string-ascii 128)) (genre (string-ascii 32))
                                  (instruments-used (string-ascii 200)) (tempo-bpm uint)
                                  (time-signature (string-ascii 8)) (key-signature (string-ascii 8))
                                  (duration-minutes uint) (public bool))
  (let (
    (composition-id (var-get next-performance-id)) ;; Reuse counter
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len title) u0) err-invalid-input)
    (asserts! (> (len genre) u0) err-invalid-input)
    (asserts! (and (>= tempo-bpm u40) (<= tempo-bpm u300)) err-invalid-tempo)
    (asserts! (> duration-minutes u0) err-invalid-input)
    
    (map-set compositions composition-id {
      composer: tx-sender,
      title: title,
      genre: genre,
      instruments-used: instruments-used,
      tempo-bpm: tempo-bpm,
      time-signature: time-signature,
      key-signature: key-signature,
      duration-minutes: duration-minutes,
      composition-date: stacks-block-height,
      sheet-music-hash: none,
      audio-hash: none,
      public: public
    })
    
    ;; Update composer profile
    (map-set musician-profiles tx-sender
      (merge profile {
        compositions-created: (+ (get compositions-created profile) u1),
        reputation-score: (+ (get reputation-score profile) u30),
        skill-level: (+ (get skill-level profile) u1),
        last-activity: stacks-block-height
      })
    )
    
    ;; Award composition reward
    (try! (mint-tokens tx-sender reward-composition))
    
    (var-set next-performance-id (+ composition-id u1))
    (print {action: "composition-created", composition-id: composition-id, composer: tx-sender, title: title})
    (ok composition-id)
  )
)

;; Read-only functions
(define-read-only (get-musician-profile (musician principal))
  (map-get? musician-profiles musician)
)

(define-read-only (get-instrument (instrument-id uint))
  (map-get? instruments instrument-id)
)

(define-read-only (get-practice-session (musician principal) (session-date uint))
  (map-get? practice-sessions {musician: musician, session-date: session-date})
)

(define-read-only (get-song-repertoire (musician principal) (song-title (string-ascii 128)))
  (map-get? song-repertoire {musician: musician, song-title: song-title})
)

(define-read-only (get-music-lesson (lesson-id uint))
  (map-get? music-lessons lesson-id)
)

(define-read-only (get-lesson-enrollment (lesson-id uint) (student principal))
  (map-get? lesson-enrollments {lesson-id: lesson-id, student: student})
)

(define-read-only (get-performance (performance-id uint))
  (map-get? performances performance-id)
)

(define-read-only (get-composition (composition-id uint))
  (map-get? compositions composition-id)
)

(define-read-only (get-theory-assessment (musician principal) (theory-area (string-ascii 32)))
  (map-get? theory-assessments {musician: musician, theory-area: theory-area})
)

;; Admin functions
(define-public (verify-instrument (instrument-id uint))
  (let (
    (instrument (unwrap! (map-get? instruments instrument-id) err-not-found))
  )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set instruments instrument-id (merge instrument {verified: true}))
    (print {action: "instrument-verified", instrument-id: instrument-id})
    (ok true)
  )
)

(define-public (update-musician-username (new-username (string-ascii 32)))
  (let (
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len new-username) u0) err-invalid-input)
    (map-set musician-profiles tx-sender (merge profile {username: new-username}))
    (print {action: "musician-username-updated", musician: tx-sender, username: new-username})
    (ok true)
  )
)