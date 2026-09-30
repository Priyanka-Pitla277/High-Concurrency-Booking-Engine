CREATE DATABASE IF NOT EXISTS bookmyshow_assignment;
USE bookmyshow_assignment;

-- ==========================
-- 1. Theatre and venue tables
-- ==========================

CREATE TABLE theatres (
    theatre_id BIGINT NOT NULL AUTO_INCREMENT,
    theatre_name VARCHAR(150) NOT NULL,
    city VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (theatre_id),
    KEY idx_city (city)
);

CREATE TABLE screens (
    screen_id BIGINT NOT NULL AUTO_INCREMENT,
    theatre_id BIGINT NOT NULL,
    screen_name VARCHAR(50) NOT NULL,
    total_seats INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (screen_id),
    UNIQUE KEY uq_screen_name_per_theatre (theatre_id, screen_name),
    CONSTRAINT fk_screen_theatre
        FOREIGN KEY (theatre_id) REFERENCES theatres(theatre_id)
        ON DELETE CASCADE
);

-- ==========================
-- 2. Movie and show tables
-- ==========================

CREATE TABLE movies (
    movie_id BIGINT NOT NULL AUTO_INCREMENT,
    title VARCHAR(200) NOT NULL,
    language VARCHAR(50) NOT NULL,
    duration_minutes INT NOT NULL,
    genre VARCHAR(80) DEFAULT NULL,
    release_date DATE DEFAULT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (movie_id),
    KEY idx_title (title)
);

CREATE TABLE shows (
    show_id BIGINT NOT NULL AUTO_INCREMENT,
    movie_id BIGINT NOT NULL,
    screen_id BIGINT NOT NULL,
    show_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    status ENUM('ACTIVE', 'CANCELLED') NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (show_id),
    UNIQUE KEY uq_movie_screen_date_time (movie_id, screen_id, show_date, start_time),
    KEY idx_show_date_screen (show_date, screen_id),
    CONSTRAINT fk_show_movie
        FOREIGN KEY (movie_id) REFERENCES movies(movie_id),
    CONSTRAINT fk_show_screen
        FOREIGN KEY (screen_id) REFERENCES screens(screen_id)
);

-- =========================================
-- 3. Seat inventory and per-show availability
-- =========================================

CREATE TABLE seats (
    seat_id BIGINT NOT NULL AUTO_INCREMENT,
    screen_id BIGINT NOT NULL,
    seat_row CHAR(1) NOT NULL,
    seat_number SMALLINT NOT NULL,
    seat_class ENUM('NORMAL', 'PREMIUM', 'VIP') NOT NULL DEFAULT 'NORMAL',
    PRIMARY KEY (seat_id),
    UNIQUE KEY uq_screen_row_number (screen_id, seat_row, seat_number),
    CONSTRAINT fk_seat_screen
        FOREIGN KEY (screen_id) REFERENCES screens(screen_id)
        ON DELETE CASCADE
);

CREATE TABLE show_seat_inventory (
    show_id BIGINT NOT NULL,
    seat_id BIGINT NOT NULL,
    status ENUM('AVAILABLE', 'HELD', 'BOOKED') NOT NULL DEFAULT 'AVAILABLE',
    hold_expires_at DATETIME NULL,
    version INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (show_id, seat_id),
    KEY idx_show_status (show_id, status),
    KEY idx_hold_expires (hold_expires_at),
    CONSTRAINT fk_inventory_show
        FOREIGN KEY (show_id) REFERENCES shows(show_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_inventory_seat
        FOREIGN KEY (seat_id) REFERENCES seats(seat_id)
        ON DELETE CASCADE
);

-- ==========================
-- 4. User and booking tables
-- ==========================

CREATE TABLE users (
    user_id BIGINT NOT NULL AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_user_email (email),
    UNIQUE KEY uq_user_phone (phone)
);

CREATE TABLE bookings (
    booking_id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    show_id BIGINT NOT NULL,
    booking_code VARCHAR(30) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    status ENUM('PENDING', 'HOLD', 'CONFIRMED', 'FAILED', 'CANCELLED', 'EXPIRED')
        NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (booking_id),
    UNIQUE KEY uq_booking_code (booking_code),
    KEY idx_show_user (show_id, user_id),
    CONSTRAINT fk_booking_user
        FOREIGN KEY (user_id) REFERENCES users(user_id),
    CONSTRAINT fk_booking_show
        FOREIGN KEY (show_id) REFERENCES shows(show_id)
);

CREATE TABLE booking_seats (
    booking_id BIGINT NOT NULL,
    show_id BIGINT NOT NULL,
    seat_id BIGINT NOT NULL,
    seat_price DECIMAL(10,2) NOT NULL,
    status ENUM('HELD', 'BOOKED', 'CANCELLED') NOT NULL DEFAULT 'HELD',
    PRIMARY KEY (booking_id, seat_id),
    KEY idx_show_seat (show_id, seat_id),
    CONSTRAINT fk_bookingseat_booking
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_bookingseat_show
        FOREIGN KEY (show_id) REFERENCES shows(show_id),
    CONSTRAINT fk_bookingseat_seat
        FOREIGN KEY (seat_id) REFERENCES seats(seat_id)
);

-- ==========================
-- 5. Payment and webhook tables
-- ==========================

CREATE TABLE payments (
    payment_id BIGINT NOT NULL AUTO_INCREMENT,
    booking_id BIGINT NOT NULL,
    payment_reference VARCHAR(100) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    provider VARCHAR(50) NOT NULL,
    status ENUM('INITIATED', 'AUTHORIZED', 'CAPTURED', 'FAILED', 'REFUNDED')
        NOT NULL DEFAULT 'INITIATED',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (payment_id),
    UNIQUE KEY uq_payment_reference (payment_reference),
    KEY idx_booking_id (booking_id),
    CONSTRAINT fk_payment_booking
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

CREATE TABLE payment_webhooks (
    webhook_id BIGINT NOT NULL AUTO_INCREMENT,
    payment_id BIGINT NOT NULL,
    provider_event_id VARCHAR(100) NOT NULL,
    event_type VARCHAR(80) NOT NULL,
    payload_hash CHAR(64) NOT NULL,
    processed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (webhook_id),
    UNIQUE KEY uq_payment_provider_event (payment_id, provider_event_id),
    KEY idx_payment_id (payment_id),
    CONSTRAINT fk_webhook_payment
        FOREIGN KEY (payment_id) REFERENCES payments(payment_id)
);

-- ==========================
-- 6. Sample data
-- ==========================

INSERT INTO theatres (theatre_name, city, address)
VALUES
('INOX Phoenix', 'Bengaluru', '24, Brigade Road, Bengaluru'),
('PVR Orion', 'Bengaluru', 'Orion Mall, Rajajinagar, Bengaluru');

INSERT INTO screens (theatre_id, screen_name, total_seats)
VALUES
(1, 'Screen 1', 20),
(1, 'Screen 2', 20),
(2, 'Screen 1', 18);

INSERT INTO movies (title, language, duration_minutes, genre, release_date)
VALUES
('Dune: Part Two', 'English', 166, 'Sci-Fi', '2024-03-01'),
('Salaar', 'Telugu', 175, 'Action', '2023-12-22'),
('Interstellar', 'English', 169, 'Sci-Fi', '2014-11-07');

INSERT INTO shows (movie_id, screen_id, show_date, start_time, end_time, status)
VALUES
(1, 1, '2026-10-01', '12:30:00', '15:16:00', 'ACTIVE'),
(1, 1, '2026-10-01', '18:30:00', '21:16:00', 'ACTIVE'),
(2, 2, '2026-10-01', '14:00:00', '16:55:00', 'ACTIVE'),
(3, 3, '2026-10-01', '19:00:00', '21:49:00', 'ACTIVE');

INSERT INTO seats (screen_id, seat_row, seat_number, seat_class)
VALUES
(1, 'A', 1, 'NORMAL'),
(1, 'A', 2, 'NORMAL'),
(1, 'A', 3, 'NORMAL'),
(1, 'A', 4, 'NORMAL'),
(1, 'A', 5, 'NORMAL'),
(1, 'B', 1, 'NORMAL'),
(1, 'B', 2, 'NORMAL'),
(1, 'B', 3, 'NORMAL'),
(1, 'B', 4, 'NORMAL'),
(1, 'B', 5, 'NORMAL'),
(1, 'C', 1, 'PREMIUM'),
(1, 'C', 2, 'PREMIUM'),
(1, 'C', 3, 'PREMIUM'),
(1, 'C', 4, 'PREMIUM'),
(1, 'C', 5, 'PREMIUM');

INSERT INTO show_seat_inventory (show_id, seat_id, status, hold_expires_at, version)
VALUES
(1, 1, 'AVAILABLE', NULL, 0),
(1, 2, 'AVAILABLE', NULL, 0),
(1, 3, 'AVAILABLE', NULL, 0),
(1, 4, 'AVAILABLE', NULL, 0),
(1, 5, 'AVAILABLE', NULL, 0),
(1, 6, 'AVAILABLE', NULL, 0),
(1, 7, 'AVAILABLE', NULL, 0),
(1, 8, 'AVAILABLE', NULL, 0),
(1, 9, 'AVAILABLE', NULL, 0),
(1, 10, 'AVAILABLE', NULL, 0),
(1, 11, 'AVAILABLE', NULL, 0),
(1, 12, 'AVAILABLE', NULL, 0),
(1, 13, 'AVAILABLE', NULL, 0),
(1, 14, 'AVAILABLE', NULL, 0),
(1, 15, 'AVAILABLE', NULL, 0),
(2, 1, 'HELD', DATE_ADD(NOW(), INTERVAL 4 MINUTE), 1),
(2, 2, 'BOOKED', NULL, 2),
(2, 3, 'AVAILABLE', NULL, 0);

INSERT INTO users (name, email, phone)
VALUES
('Riya Sharma', 'riya@example.com', '9876543210'),
('Arjun Verma', 'arjun@example.com', '9876543211');

INSERT INTO bookings (user_id, show_id, booking_code, total_amount, status)
VALUES
(1, 1, 'BK-1001', 1200.00, 'CONFIRMED'),
(2, 2, 'BK-1002', 950.00, 'HOLD');

INSERT INTO booking_seats (booking_id, show_id, seat_id, seat_price, status)
VALUES
(1, 1, 1, 400.00, 'BOOKED'),
(1, 1, 2, 400.00, 'BOOKED'),
(1, 1, 3, 400.00, 'BOOKED');

INSERT INTO payments (booking_id, payment_reference, amount, provider, status)
VALUES
(1, 'PAY-REF-101', 1200.00, 'RAZORPAY', 'CAPTURED');

INSERT INTO payment_webhooks (payment_id, provider_event_id, event_type, payload_hash, processed_at)
VALUES
(1, 'evt_9001', 'payment.captured', SHA2('payment.captured|PAY-REF-101|1200.00', 256), NOW());

-- =======================================
-- 7. P2 query: list shows for a given date
-- =======================================

SELECT
    t.theatre_id,
    t.theatre_name,
    s.show_id,
    m.title AS movie_title,
    s.show_date,
    s.start_time,
    s.end_time,
    sc.screen_name
FROM shows s
JOIN screens sc
    ON sc.screen_id = s.screen_id
JOIN theatres t
    ON t.theatre_id = sc.theatre_id
JOIN movies m
    ON m.movie_id = s.movie_id
WHERE t.theatre_id = 1
  AND s.show_date = '2026-10-01'
  AND s.status = 'ACTIVE'
ORDER BY s.start_time, m.title;

-- =======================================
-- 8. Seat hold concurrency pattern
-- =======================================

-- SELECT *
-- FROM show_seat_inventory
-- WHERE show_id = 1 AND seat_id = 1
-- FOR UPDATE;

-- UPDATE show_seat_inventory
-- SET status = 'HELD',
--     hold_expires_at = DATE_ADD(NOW(), INTERVAL 5 MINUTE),
--     version = version + 1
-- WHERE show_id = 1
--   AND seat_id = 1
--   AND status = 'AVAILABLE';
