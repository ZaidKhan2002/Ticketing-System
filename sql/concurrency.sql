-- Transaction: acquire a seat hold safely.

START TRANSACTION;

-- Step 1: Lock the seat row.
SELECT
    show_seat_id,
    status,
    price
FROM show_seat
WHERE show_seat_id = 50401
FOR UPDATE;

-- Step 2: Only an AVAILABLE seat can be held.
UPDATE show_seat
SET status = 'HELD'
WHERE show_seat_id = 50401
  AND status = 'AVAILABLE';

-- Step 3: Create the temporary hold.
INSERT INTO seat_hold (
    show_seat_id,
    user_id,
    hold_token,
    expires_at,
    status
)
VALUES (
    50401,
    10002,
    'hold_concurrency_demo_001',
    DATE_ADD(NOW(), INTERVAL 5 MINUTE),
    'ACTIVE'
);

COMMIT;

-- ============================================================
-- 2. CONCURRENT SEAT ACQUISITION
-- ============================================================
-- Scenario:
-- Two users attempt to hold the same seat at the same time.
--
-- User A and User B both target show_seat_id = 50401.
-- SELECT ... FOR UPDATE ensures that only one transaction
-- can modify the seat at a time.
--
-- IMPORTANT:
-- Run Transaction A and Transaction B in two separate
-- MySQL sessions/connections to observe the locking behavior.


-- ============================================================
-- TRANSACTION A
-- ============================================================

START TRANSACTION;

-- Lock the seat row.
SELECT
    show_seat_id,
    status,
    price
FROM show_seat
WHERE show_seat_id = 50401
FOR UPDATE;

-- If status = AVAILABLE, User A acquires the seat.
UPDATE show_seat
SET status = 'HELD'
WHERE show_seat_id = 50401
  AND status = 'AVAILABLE';

-- Create User A's hold.
INSERT INTO seat_hold (
    show_seat_id,
    user_id,
    hold_token,
    expires_at,
    status
)
VALUES (
    50401,
    10002,
    'hold_user_a_demo',
    DATE_ADD(NOW(), INTERVAL 5 MINUTE),
    'ACTIVE'
);

-- Commit releases the row lock.
COMMIT;


-- ============================================================
-- TRANSACTION B
-- ============================================================

START TRANSACTION;

-- User B attempts to lock the same seat.
-- If Transaction A is still active, this statement waits
-- until Transaction A commits or rolls back.
SELECT
    show_seat_id,
    status,
    price
FROM show_seat
WHERE show_seat_id = 50401
FOR UPDATE;

-- After acquiring the lock, User B sees the current status.
-- If the status is HELD, User B must NOT create a hold.

ROLLBACK;


-- ============================================================
-- 3. EXPIRED HOLD RELEASE
-- ============================================================
-- When a seat hold expires, the hold is marked EXPIRED and
-- the corresponding show_seat becomes AVAILABLE again.
--
-- Both changes are performed in the same transaction so that
-- the hold and seat state remain consistent.


START TRANSACTION;

-- Lock the hold first.
SELECT
    hold_id,
    show_seat_id,
    status,
    expires_at
FROM seat_hold
WHERE hold_id = 70004
  AND status = 'ACTIVE'
  AND expires_at <= NOW()
FOR UPDATE;


-- Mark the hold as expired.
UPDATE seat_hold
SET status = 'EXPIRED'
WHERE hold_id = 70004
  AND status = 'ACTIVE'
  AND expires_at <= NOW();


-- Release the corresponding seat.
UPDATE show_seat ss
JOIN seat_hold sh
    ON ss.show_seat_id = sh.show_seat_id
SET ss.status = 'AVAILABLE'
WHERE sh.hold_id = 70004
  AND sh.status = 'EXPIRED'
  AND ss.status = 'HELD';


COMMIT;

-- ============================================================
-- 4. CONVERT ACTIVE HOLD INTO BOOKING
-- ============================================================
-- A booking can only use a seat that is currently held by
-- the requesting user and whose hold has not expired.


START TRANSACTION;


-- Lock the seat.
SELECT
    ss.show_seat_id,
    ss.status,
    ss.price
FROM show_seat ss
WHERE ss.show_seat_id = 50401
FOR UPDATE;


-- Lock and validate the user's active hold.
SELECT
    hold_id,
    show_seat_id,
    user_id,
    status,
    expires_at
FROM seat_hold
WHERE show_seat_id = 50401
  AND user_id = 10002
  AND status = 'ACTIVE'
  AND expires_at > NOW()
FOR UPDATE;


-- Application verifies that the hold exists and belongs
-- to User 10002 before continuing.


-- Create the booking.
INSERT INTO booking (
    user_id,
    show_id,
    status,
    total_amount
)
SELECT
    10002,
    ss.show_id,
    'PENDING',
    ss.price
FROM show_seat ss
WHERE ss.show_seat_id = 50401;


-- Link the seat to the booking.
INSERT INTO booking_seat (
    booking_id,
    show_seat_id,
    price
)
SELECT
    LAST_INSERT_ID(),
    50401,
    price
FROM show_seat
WHERE show_seat_id = 50401;


-- The seat is now booked.
UPDATE show_seat
SET status = 'BOOKED'
WHERE show_seat_id = 50401
  AND status = 'HELD';


-- Convert the hold into historical state.
UPDATE seat_hold
SET status = 'CONVERTED'
WHERE show_seat_id = 50401
  AND user_id = 10002
  AND status = 'ACTIVE';


COMMIT;

-- ============================================================
-- 5. PAYMENT WEBHOOK IDEMPOTENCY
-- ============================================================
-- The same payment provider event may be delivered more than
-- once. The provider payment ID must therefore be unique.


-- First webhook.
INSERT INTO payment (
    booking_id,
    provider,
    provider_payment_id,
    amount,
    status
)
VALUES (
    90001,
    'RAZORPAY',
    'pay_concurrency_demo_001',
    500.00,
    'SUCCESS'
);


-- Duplicate webhook.
-- This must NOT create another payment record because
-- (provider, provider_payment_id) is UNIQUE.

INSERT INTO payment (
    booking_id,
    provider,
    provider_payment_id,
    amount,
    status
)
VALUES (
    90001,
    'RAZORPAY',
    'pay_concurrency_demo_001',
    500.00,
    'SUCCESS'
);

-- ============================================================
-- 6. CONFIRM BOOKING AFTER SUCCESSFUL PAYMENT
-- ============================================================

START TRANSACTION;

-- Lock the booking.
SELECT
    booking_id,
    status,
    total_amount
FROM booking
WHERE booking_id = 90001
FOR UPDATE;


-- Verify successful payment.
SELECT
    payment_id,
    booking_id,
    amount,
    status
FROM payment
WHERE booking_id = 90001
  AND status = 'SUCCESS'
FOR UPDATE;


-- Application verifies that a successful payment exists
-- and that the payment amount matches the booking amount.


UPDATE booking
SET status = 'CONFIRMED'
WHERE booking_id = 90001
  AND status = 'PENDING';


COMMIT;

-- ============================================================
-- 7. DEADLOCK CONSIDERATIONS
-- ============================================================
--
-- Multiple transactions should acquire locks in a consistent
-- order to reduce the possibility of deadlocks.
--
-- Example:
--
-- Transaction A:
--   Lock seat 50401
--   Lock seat 50402
--
-- Transaction B:
--   Lock seat 50401
--   Lock seat 50402
--
-- Both transactions follow the same ordering.
--
-- Avoid:
--
-- Transaction A:
--   Lock 50401
--   Lock 50402
--
-- Transaction B:
--   Lock 50402
--   Lock 50401
--
-- The second pattern can produce a circular wait.
--
-- The application should also handle MySQL deadlock errors
-- by rolling back and retrying the transaction when appropriate.

-- ============================================================
-- 8. TRANSACTION ISOLATION
-- ============================================================
--
-- InnoDB provides row-level locking and transactional
-- guarantees required for seat allocation.
--
-- SELECT ... FOR UPDATE is used when the application needs
-- to lock a specific seat before changing its state.
--
-- The application should keep seat-booking transactions
-- short to reduce lock contention.
--
-- Example:
--
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
--
-- START TRANSACTION;
-- ...
-- COMMIT;
--
-- The exact isolation level should be selected based on the
-- application's consistency and concurrency requirements.