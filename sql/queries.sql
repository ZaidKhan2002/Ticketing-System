-- P2:
-- List all shows at a given theatre on a given date,
-- including movie, screen and timings.

SELECT
    s.show_id,
    m.title AS movie,
    sc.name AS screen,
    s.show_date,
    s.start_time,
    s.end_time
FROM `show` s
JOIN movie m
    ON s.movie_id = m.movie_id
JOIN screen sc
    ON s.screen_id = sc.screen_id
WHERE sc.theatre_id = 1
  AND s.show_date = '2026-10-01'
ORDER BY s.start_time;

-- List all seats for a given show with their current status and price.

SELECT
    ss.show_seat_id,
    s.row_label,
    s.seat_number,
    s.seat_type,
    ss.status,
    ss.price
FROM show_seat ss
JOIN seat s
    ON ss.seat_id = s.seat_id
WHERE ss.show_id = 10005
ORDER BY s.row_label, s.seat_number;

-- List active holds with movie, show and seat details.

SELECT
    sh.hold_id,
    sh.user_id,
    m.title AS movie,
    s.show_date,
    s.start_time,
    st.row_label,
    st.seat_number,
    sh.expires_at
FROM seat_hold sh
JOIN show_seat ss
    ON sh.show_seat_id = ss.show_seat_id
JOIN seat st
    ON ss.seat_id = st.seat_id
JOIN show s
    ON ss.show_id = s.show_id
JOIN movie m
    ON s.movie_id = m.movie_id
WHERE sh.status = 'ACTIVE'
ORDER BY sh.expires_at;

-- Find active holds whose expiry time has passed.

SELECT
    hold_id,
    show_seat_id,
    user_id,
    expires_at
FROM seat_hold
WHERE status = 'ACTIVE'
  AND expires_at <= NOW();

-- Release seats whose active holds have expired.

UPDATE show_seat ss
JOIN seat_hold sh
    ON sh.show_seat_id = ss.show_seat_id
SET ss.status = 'AVAILABLE'
WHERE sh.status = 'ACTIVE'
  AND sh.expires_at <= NOW();

-- Get all seats associated with a booking.

SELECT
    bs.booking_seat_id,
    bs.show_seat_id,
    st.row_label,
    st.seat_number,
    st.seat_type,
    bs.price
FROM booking_seat bs
JOIN show_seat ss
    ON bs.show_seat_id = ss.show_seat_id
JOIN seat st
    ON ss.seat_id = st.seat_id
WHERE bs.booking_id = 90001
ORDER BY st.row_label, st.seat_number;

-- Get payment details for a booking.

SELECT
    p.payment_id,
    p.booking_id,
    p.provider,
    p.provider_payment_id,
    p.amount,
    p.status,
    p.created_at,
    p.updated_at
FROM payment p
WHERE p.booking_id = 90001;

-- Find bookings that are still waiting for payment.

SELECT
    b.booking_id,
    b.user_id,
    b.show_id,
    b.total_amount,
    b.status,
    p.payment_id,
    p.provider,
    p.status AS payment_status
FROM booking b
LEFT JOIN payment p
    ON b.booking_id = p.booking_id
WHERE b.status = 'PENDING'
ORDER BY b.created_at;

-- Find confirmed bookings without a successful payment.

SELECT
    b.booking_id,
    b.status AS booking_status,
    p.payment_id,
    p.status AS payment_status,
    b.total_amount
FROM booking b
LEFT JOIN payment p
    ON b.booking_id = p.booking_id
WHERE b.status = 'CONFIRMED'
  AND (p.payment_id IS NULL OR p.status <> 'SUCCESS');

-- List failed payments.

SELECT
    p.payment_id,
    p.booking_id,
    p.provider,
    p.provider_payment_id,
    p.amount,
    p.status,
    p.created_at
FROM payment p
WHERE p.status = 'FAILED'
ORDER BY p.created_at DESC;

-- Check whether a payment webhook has already been received.

SELECT
    payment_id,
    booking_id,
    provider,
    provider_payment_id,
    status
FROM payment
WHERE provider = 'RAZORPAY'
  AND provider_payment_id = 'pay_demo_10001';