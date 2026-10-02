USE bookmyshow;

-- ============================================================
-- 1. THEATRES
-- ============================================================

INSERT INTO theatre
    (theatre_id, name, address, city)
VALUES
    (1, 'PVR Phoenix', 'Phoenix Marketcity, Kurla', 'Mumbai'),
    (2, 'INOX R City', 'R City Mall, Ghatkopar', 'Mumbai');


-- ============================================================
-- 2. SCREENS
-- ============================================================

INSERT INTO screen
    (screen_id, theatre_id, name)
VALUES
    (101, 1, 'Screen 1'),
    (102, 1, 'Screen 2'),
    (201, 2, 'Screen 1');


-- ============================================================
-- 3. SEATS
-- ============================================================

-- PVR Phoenix - Screen 1
INSERT INTO seat
    (seat_id, screen_id, row_label, seat_number, seat_type)
VALUES
    (1001, 101, 'A', 1, 'REGULAR'),
    (1002, 101, 'A', 2, 'REGULAR'),
    (1003, 101, 'A', 3, 'REGULAR'),
    (1004, 101, 'A', 4, 'PREMIUM'),
    (1005, 101, 'A', 5, 'PREMIUM');

-- PVR Phoenix - Screen 2
INSERT INTO seat
    (seat_id, screen_id, row_label, seat_number, seat_type)
VALUES
    (2001, 102, 'A', 1, 'REGULAR'),
    (2002, 102, 'A', 2, 'REGULAR'),
    (2003, 102, 'A', 3, 'REGULAR'),
    (2004, 102, 'A', 4, 'PREMIUM'),
    (2005, 102, 'A', 5, 'RECLINER');

-- INOX R City - Screen 1
INSERT INTO seat
    (seat_id, screen_id, row_label, seat_number, seat_type)
VALUES
    (3001, 201, 'A', 1, 'REGULAR'),
    (3002, 201, 'A', 2, 'REGULAR'),
    (3003, 201, 'A', 3, 'REGULAR'),
    (3004, 201, 'A', 4, 'PREMIUM'),
    (3005, 201, 'A', 5, 'RECLINER');


-- ============================================================
-- 4. MOVIES
-- ============================================================

INSERT INTO movie
    (movie_id, title, duration_minutes, language, release_date)
VALUES
    (1, 'Interstellar', 169, 'English', '2014-11-07'),
    (2, 'Inception', 148, 'English', '2010-07-16'),
    (3, 'The Dark Knight', 152, 'English', '2008-07-18');


-- ============================================================
-- 5. SHOWS
-- ============================================================

-- PVR Phoenix - Screen 1
INSERT INTO `show`
    (show_id, movie_id, screen_id, show_date, start_time, end_time)
VALUES
    (10001, 1, 101, '2026-10-01', '10:00:00', '12:49:00'),
    (10002, 2, 101, '2026-10-01', '14:00:00', '16:28:00'),
    (10003, 3, 101, '2026-10-01', '19:00:00', '21:32:00');

-- PVR Phoenix - Screen 2
INSERT INTO `show`
    (show_id, movie_id, screen_id, show_date, start_time, end_time)
VALUES
    (10004, 1, 102, '2026-10-01', '11:00:00', '13:49:00'),
    (10005, 2, 102, '2026-10-01', '19:30:00', '21:58:00');

-- PVR Phoenix - another date
INSERT INTO `show`
    (show_id, movie_id, screen_id, show_date, start_time, end_time)
VALUES
    (10006, 3, 101, '2026-10-02', '19:00:00', '21:32:00');

-- INOX R City
INSERT INTO `show`
    (show_id, movie_id, screen_id, show_date, start_time, end_time)
VALUES
    (20001, 1, 201, '2026-10-01', '18:00:00', '20:49:00'),
    (20002, 3, 201, '2026-10-02', '20:00:00', '22:32:00');


-- ============================================================
-- 6. SHOW SEATS
-- ============================================================

-- Show 10001 -> Screen 101
INSERT INTO show_seat
    (show_seat_id, show_id, seat_id, status, price)
VALUES
    (50001, 10001, 1001, 'AVAILABLE', 250.00),
    (50002, 10001, 1002, 'AVAILABLE', 250.00),
    (50003, 10001, 1003, 'AVAILABLE', 250.00),
    (50004, 10001, 1004, 'AVAILABLE', 350.00),
    (50005, 10001, 1005, 'AVAILABLE', 350.00);

-- Show 10002 -> Screen 101
INSERT INTO show_seat
    (show_seat_id, show_id, seat_id, status, price)
VALUES
    (50101, 10002, 1001, 'AVAILABLE', 250.00),
    (50102, 10002, 1002, 'AVAILABLE', 250.00),
    (50103, 10002, 1003, 'AVAILABLE', 250.00),
    (50104, 10002, 1004, 'AVAILABLE', 350.00),
    (50105, 10002, 1005, 'AVAILABLE', 350.00);

-- Show 10003 -> Screen 101
INSERT INTO show_seat
    (show_seat_id, show_id, seat_id, status, price)
VALUES
    (50201, 10003, 1001, 'BOOKED', 250.00),
    (50202, 10003, 1002, 'BOOKED', 250.00),
    (50203, 10003, 1003, 'AVAILABLE', 250.00),
    (50204, 10003, 1004, 'AVAILABLE', 350.00),
    (50205, 10003, 1005, 'AVAILABLE', 350.00);

-- Show 10004 -> Screen 102
INSERT INTO show_seat
    (show_seat_id, show_id, seat_id, status, price)
VALUES
    (50301, 10004, 2001, 'AVAILABLE', 250.00),
    (50302, 10004, 2002, 'AVAILABLE', 250.00),
    (50303, 10004, 2003, 'AVAILABLE', 250.00),
    (50304, 10004, 2004, 'AVAILABLE', 350.00),
    (50305, 10004, 2005, 'AVAILABLE', 500.00);

-- Show 10005 -> Screen 102
INSERT INTO show_seat
    (show_seat_id, show_id, seat_id, status, price)
VALUES
    (50401, 10005, 2001, 'AVAILABLE', 250.00),
    (50402, 10005, 2002, 'AVAILABLE', 250.00),
    (50403, 10005, 2003, 'AVAILABLE', 250.00),
    (50404, 10005, 2004, 'AVAILABLE', 350.00),
    (50405, 10005, 2005, 'AVAILABLE', 500.00);

-- Show 10006 -> Screen 101
INSERT INTO show_seat
    (show_seat_id, show_id, seat_id, status, price)
VALUES
    (50501, 10006, 1001, 'AVAILABLE', 250.00),
    (50502, 10006, 1002, 'AVAILABLE', 250.00),
    (50503, 10006, 1003, 'AVAILABLE', 250.00),
    (50504, 10006, 1004, 'AVAILABLE', 350.00),
    (50505, 10006, 1005, 'AVAILABLE', 350.00);

-- Show 20001 -> INOX R City Screen 1
INSERT INTO show_seat
    (show_seat_id, show_id, seat_id, status, price)
VALUES
    (50601, 20001, 3001, 'AVAILABLE', 250.00),
    (50602, 20001, 3002, 'AVAILABLE', 250.00),
    (50603, 20001, 3003, 'AVAILABLE', 250.00),
    (50604, 20001, 3004, 'AVAILABLE', 350.00),
    (50605, 20001, 3005, 'AVAILABLE', 500.00);

-- Show 20002 -> INOX R City Screen 1
INSERT INTO show_seat
    (show_seat_id, show_id, seat_id, status, price)
VALUES
    (50701, 20002, 3001, 'AVAILABLE', 250.00),
    (50702, 20002, 3002, 'AVAILABLE', 250.00),
    (50703, 20002, 3003, 'AVAILABLE', 250.00),
    (50704, 20002, 3004, 'AVAILABLE', 350.00),
    (50705, 20002, 3005, 'AVAILABLE', 500.00);


-- ============================================================
-- 7. BOOKINGS
-- ============================================================

-- Confirmed booking
INSERT INTO booking
    (booking_id, user_id, show_id, status, total_amount)
VALUES
    (90001, 10001, 10003, 'CONFIRMED', 500.00);

-- Pending booking
INSERT INTO booking
    (booking_id, user_id, show_id, status, total_amount)
VALUES
    (90002, 10002, 10005, 'PENDING', 600.00);

-- Cancelled booking
INSERT INTO booking
    (booking_id, user_id, show_id, status, total_amount)
VALUES
    (90003, 10003, 10001, 'CANCELLED', 250.00);


-- ============================================================
-- 8. BOOKING SEATS
-- ============================================================

-- Booking 90001 -> Show 10003 -> Seats A1, A2
INSERT INTO booking_seat
    (booking_seat_id, booking_id, show_seat_id, price)
VALUES
    (91001, 90001, 50201, 250.00),
    (91002, 90001, 50202, 250.00);

-- Booking 90002 -> Show 10005 -> Seats A1, A2
INSERT INTO booking_seat
    (booking_seat_id, booking_id, show_seat_id, price)
VALUES
    (91003, 90002, 50401, 250.00),
    (91004, 90002, 50402, 350.00);

-- Cancelled booking
INSERT INTO booking_seat
    (booking_seat_id, booking_id, show_seat_id, price)
VALUES
    (91005, 90003, 50001, 250.00);


-- ============================================================
-- 9. PAYMENTS
-- ============================================================

-- Successful payment
INSERT INTO payment
    (payment_id, booking_id, provider, provider_payment_id, amount, status)
VALUES
    (80001, 90001, 'RAZORPAY', 'pay_demo_10001', 500.00, 'SUCCESS');

-- Failed payment
INSERT INTO payment
    (payment_id, booking_id, provider, provider_payment_id, amount, status)
VALUES
    (80002, 90002, 'RAZORPAY', 'pay_demo_10002', 600.00, 'FAILED');

-- Failed payment attempt for cancelled booking
INSERT INTO payment
    (payment_id, booking_id, provider, provider_payment_id, amount, status)
VALUES
    (80003, 90003, 'RAZORPAY', 'pay_demo_10003', 250.00, 'FAILED');


-- ============================================================
-- 10. SEAT HOLDS
-- ============================================================

-- Active hold
INSERT INTO seat_hold
    (hold_id, show_seat_id, user_id, hold_token, expires_at, status)
VALUES
    (
        70001,
        50403,
        10002,
        'hold_demo_10001',
        DATE_ADD(NOW(), INTERVAL 5 MINUTE),
        'ACTIVE'
    );

-- Expired historical hold
INSERT INTO seat_hold
    (hold_id, show_seat_id, user_id, hold_token, expires_at, status)
VALUES
    (
        70002,
        50001,
        10003,
        'hold_demo_10002',
        DATE_SUB(NOW(), INTERVAL 10 MINUTE),
        'EXPIRED'
    );

-- Released historical hold
INSERT INTO seat_hold
    (hold_id, show_seat_id, user_id, hold_token, expires_at, status)
VALUES
    (
        70003,
        50601,
        10004,
        'hold_demo_10003',
        DATE_SUB(NOW(), INTERVAL 20 MINUTE),
        'RELEASED'
    );