CREATE TABLE theatre (
    theatre_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (theatre_id),

    INDEX idx_theatre_city (city),
    INDEX idx_theatre_name_city (name, city)
) ENGINE = InnoDB;

CREATE TABLE screen (
    screen_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    theatre_id BIGINT UNSIGNED NOT NULL,
    name VARCHAR(100) NOT NULL,

    PRIMARY KEY (screen_id),

    CONSTRAINT fk_screen_theatre
        FOREIGN KEY (theatre_id)
        REFERENCES theatre(theatre_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT uq_screen_theatre_name
        UNIQUE (theatre_id, name),

    INDEX idx_screen_theatre (theatre_id)
) ENGINE = InnoDB;

CREATE TABLE seat (
    seat_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    screen_id BIGINT UNSIGNED NOT NULL,
    row_label VARCHAR(10) NOT NULL,
    seat_number INT UNSIGNED NOT NULL,
    seat_type VARCHAR(30) NOT NULL DEFAULT 'REGULAR',

    PRIMARY KEY (seat_id),

    CONSTRAINT fk_seat_screen
        FOREIGN KEY (screen_id)
        REFERENCES screen(screen_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT uq_seat_position
        UNIQUE (screen_id, row_label, seat_number),

    CONSTRAINT chk_seat_number
        CHECK (seat_number > 0),

    CONSTRAINT chk_seat_type
        CHECK (seat_type IN ('REGULAR', 'PREMIUM', 'RECLINER')),

    INDEX idx_seat_screen (screen_id)
) ENGINE = InnoDB;

CREATE TABLE movie (
    movie_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    duration_minutes SMALLINT UNSIGNED NOT NULL,
    language VARCHAR(50) NOT NULL,
    release_date DATE NOT NULL,

    PRIMARY KEY (movie_id),

    CONSTRAINT chk_movie_duration
        CHECK (duration_minutes > 0),

    INDEX idx_movie_title (title),
    INDEX idx_movie_release_date (release_date)
) ENGINE = InnoDB;

CREATE TABLE show (
    show_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    movie_id BIGINT UNSIGNED NOT NULL,
    screen_id BIGINT UNSIGNED NOT NULL,
    show_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (show_id),

    CONSTRAINT fk_show_movie
        FOREIGN KEY (movie_id)
        REFERENCES movie(movie_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_show_screen
        FOREIGN KEY (screen_id)
        REFERENCES screen(screen_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_show_time
        CHECK (end_time > start_time),

    CONSTRAINT uq_show_screen_datetime
        UNIQUE (screen_id, show_date, start_time),

    INDEX idx_show_screen_date_time
        (screen_id, show_date, start_time),

    INDEX idx_show_movie_date
        (movie_id, show_date),

    INDEX idx_show_date
        (show_date)
) ENGINE = InnoDB;

CREATE TABLE show_seat (
    show_seat_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    show_id BIGINT UNSIGNED NOT NULL,
    seat_id BIGINT UNSIGNED NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    price DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (show_seat_id),

    CONSTRAINT fk_show_seat_show
        FOREIGN KEY (show_id)
        REFERENCES show(show_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_show_seat_seat
        FOREIGN KEY (seat_id)
        REFERENCES seat(seat_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT uq_show_seat
        UNIQUE (show_id, seat_id),

    CONSTRAINT chk_show_seat_status
        CHECK (status IN ('AVAILABLE', 'HELD', 'BOOKED')),

    CONSTRAINT chk_show_seat_price
        CHECK (price >= 0),

    INDEX idx_show_seat_show_status
        (show_id, status),

    INDEX idx_show_seat_seat
        (seat_id)
) ENGINE = InnoDB;

CREATE TABLE seat_hold (
    hold_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    show_seat_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NOT NULL,
    hold_token VARCHAR(100) NOT NULL,
    expires_at DATETIME NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    /*
     * Only ACTIVE holds produce a value.
     * EXPIRED/RELEASED/CONVERTED produce NULL.
     *
     * MySQL allows multiple NULL values in a UNIQUE index,
     * but only one non-NULL value.
     */
    active_show_seat_id BIGINT UNSIGNED
        GENERATED ALWAYS AS (
            CASE
                WHEN status = 'ACTIVE' THEN show_seat_id
                ELSE NULL
            END
        ) STORED,

    PRIMARY KEY (hold_id),

    CONSTRAINT fk_seat_hold_show_seat
        FOREIGN KEY (show_seat_id)
        REFERENCES show_seat(show_seat_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT uq_hold_token
        UNIQUE (hold_token),

    CONSTRAINT uq_active_show_seat
        UNIQUE (active_show_seat_id),

    CONSTRAINT chk_seat_hold_status
        CHECK (
            status IN ('ACTIVE', 'EXPIRED', 'RELEASED', 'CONVERTED')
        ),

    INDEX idx_seat_hold_expiry
        (status, expires_at),

    INDEX idx_seat_hold_show_seat
        (show_seat_id)
) ENGINE = InnoDB;

CREATE TABLE booking (
    booking_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    show_id BIGINT UNSIGNED NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    total_amount DECIMAL(10,2) NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (booking_id),

    CONSTRAINT fk_booking_show
        FOREIGN KEY (show_id)
        REFERENCES show(show_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT chk_booking_status
        CHECK (
            status IN (
                'PENDING',
                'CONFIRMED',
                'FAILED',
                'CANCELLED',
                'EXPIRED'
            )
        ),

    CONSTRAINT chk_booking_total
        CHECK (total_amount >= 0),

    INDEX idx_booking_user
        (user_id),

    INDEX idx_booking_show_status
        (show_id, status),

    INDEX idx_booking_created_at
        (created_at)
) ENGINE = InnoDB;

CREATE TABLE booking_seat (
    booking_seat_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    booking_id BIGINT UNSIGNED NOT NULL,
    show_seat_id BIGINT UNSIGNED NOT NULL,
    price DECIMAL(10,2) NOT NULL,

    PRIMARY KEY (booking_seat_id),

    CONSTRAINT fk_booking_seat_booking
        FOREIGN KEY (booking_id)
        REFERENCES booking(booking_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_booking_seat_show_seat
        FOREIGN KEY (show_seat_id)
        REFERENCES show_seat(show_seat_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT uq_booking_show_seat
        UNIQUE (booking_id, show_seat_id),

    CONSTRAINT chk_booking_seat_price
        CHECK (price >= 0),

    INDEX idx_booking_seat_show_seat
        (show_seat_id),

    INDEX idx_booking_seat_booking
        (booking_id)
) ENGINE = InnoDB;

CREATE TABLE payment (
    payment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    booking_id BIGINT UNSIGNED NOT NULL,
    provider VARCHAR(50) NOT NULL,
    provider_payment_id VARCHAR(150) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'CREATED',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (payment_id),

    CONSTRAINT fk_payment_booking
        FOREIGN KEY (booking_id)
        REFERENCES booking(booking_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT uq_provider_payment
        UNIQUE (provider, provider_payment_id),

    CONSTRAINT chk_payment_amount
        CHECK (amount >= 0),

    CONSTRAINT chk_payment_status
        CHECK (
            status IN ('CREATED', 'SUCCESS', 'FAILED')
        ),

    INDEX idx_payment_booking
        (booking_id),

    INDEX idx_payment_status
        (status)
) ENGINE = InnoDB;