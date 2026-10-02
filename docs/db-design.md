# BookMyShow Ticketing System — Database Design

## 1. Overview

This project models the database for a movie-ticketing platform similar to BookMyShow.

The database is designed to support:

* Multiple theatres and screens
* Physical seats belonging to screens
* Movies and scheduled shows
* Seat-level availability for each show
* Temporary seat holds
* Bookings and booking seats
* Payments and payment webhook idempotency
* Concurrent users competing for the same seats
* Automatic release of expired holds
* Efficient show and seat-availability queries

The design uses **MySQL with InnoDB** to provide transactional guarantees and row-level locking.

---

# 2. Core Entities

The database contains the following tables:

| Table          | Purpose                                        |
| -------------- | ---------------------------------------------- |
| `theatre`      | Stores theatre information                     |
| `screen`       | Stores screens within a theatre                |
| `seat`         | Stores physical seats belonging to a screen    |
| `movie`        | Stores movie information                       |
| `show`         | Stores scheduled movie shows                   |
| `show_seat`    | Represents a physical seat for a specific show |
| `seat_hold`    | Stores temporary seat reservations             |
| `booking`      | Stores customer bookings                       |
| `booking_seat` | Maps bookings to individual seats              |
| `payment`      | Stores payment transactions                    |

User authentication and user-profile management are outside the scope of this assignment. Therefore, `user_id` is stored where required without maintaining a separate `user` table.

---

# 3. Entity Relationships

The major relationships are:

```text
Theatre
   │
   └── 1:N ── Screen
                │
                └── 1:N ── Seat


Movie
   │
   └── 1:N ── Show ── N:1 ── Screen
                 │
                 └── 1:N ── Show Seat
                              │
                              └── N:1 ── Seat


Show Seat
   │
   ├── 1:N ── Seat Hold
   │
   └── 1:N ── Booking Seat ── N:1 ── Booking
                                      │
                                      └── 1:N ── Payment
```

The important distinction is between a **physical seat** and a **seat for a particular show**.

For example:

```text
seat
----
A1

show_seat
---------
Interstellar 10:00 → A1 → AVAILABLE
Inception 14:00    → A1 → BOOKED
```

The physical seat remains the same, while its availability changes independently for each show.

---

# 4. Table Design

## 4.1 Theatre

Stores information about a theatre.

Important attributes:

* `theatre_id` — Primary key
* `name`
* `address`
* `city`
* `created_at`

A theatre can contain multiple screens.

---

## 4.2 Screen

Represents an individual screen inside a theatre.

Important attributes:

* `screen_id` — Primary key
* `theatre_id` — Foreign key
* `name`

Constraint:

```text
UNIQUE(theatre_id, name)
```

This prevents two screens with the same name from being created within the same theatre.

`total_seats` is intentionally not stored because it is a derived value that can be calculated from the `seat` table.

---

## 4.3 Seat

Represents a physical seat belonging to a screen.

Important attributes:

* `seat_id` — Primary key
* `screen_id` — Foreign key
* `row_label`
* `seat_number`
* `seat_type`

Constraint:

```text
UNIQUE(screen_id, row_label, seat_number)
```

This prevents duplicate physical seat positions within a screen.

Supported seat types in the sample schema:

* `REGULAR`
* `PREMIUM`
* `RECLINER`

---

## 4.4 Movie

Stores movie metadata.

Important attributes:

* `movie_id`
* `title`
* `duration_minutes`
* `language`
* `release_date`

Movie information is independent of a particular theatre or screen.

---

## 4.5 Show

Represents a scheduled screening of a movie.

Important attributes:

* `show_id`
* `movie_id`
* `screen_id`
* `show_date`
* `start_time`
* `end_time`

A show connects a movie to a particular screen at a particular date and time.

Constraint:

```text
UNIQUE(screen_id, show_date, start_time)
```

This prevents two shows from being scheduled at the same starting time on the same screen.

The theatre is not directly stored in this table because it can be derived through:

```text
show → screen → theatre
```

This avoids redundant data.

---

# 5. Show Seat

`show_seat` is one of the most important tables in the design.

It represents:

> A particular physical seat for a particular show.

Attributes:

* `show_seat_id`
* `show_id`
* `seat_id`
* `status`
* `price`

Possible states:

```text
AVAILABLE
HELD
BOOKED
```

Constraint:

```text
UNIQUE(show_id, seat_id)
```

This ensures that a physical seat appears only once for a particular show.

### Why is this table necessary?

A physical seat does not have one global availability status.

For example:

```text
Seat A1

Show 1 → AVAILABLE
Show 2 → BOOKED
Show 3 → HELD
```

Therefore, seat availability must be modeled at the **show-seat level**.

The `price` is also stored here because ticket prices may vary between shows.

---

# 6. Seat Hold

`seat_hold` represents a temporary reservation while the user proceeds through the booking/payment flow.

Important attributes:

* `hold_id`
* `show_seat_id`
* `user_id`
* `hold_token`
* `expires_at`
* `status`
* `created_at`

Possible hold states:

```text
ACTIVE
EXPIRED
RELEASED
CONVERTED
```

An active hold prevents another user from acquiring the same seat.

The schema also uses a generated column:

```text
active_show_seat_id
```

which contains the `show_seat_id` only when the hold is `ACTIVE`.

A unique constraint on this generated value ensures that only one active hold can exist for a particular show seat.

Historical holds can still remain in the table after they expire or are converted.

---

# 7. Booking

The `booking` table represents a customer's booking attempt.

Important attributes:

* `booking_id`
* `user_id`
* `show_id`
* `status`
* `total_amount`
* timestamps

Possible booking states:

```text
PENDING
CONFIRMED
FAILED
CANCELLED
EXPIRED
```

A booking can contain multiple seats.

---

# 8. Booking Seat

`booking_seat` represents the seats associated with a booking.

Attributes:

* `booking_seat_id`
* `booking_id`
* `show_seat_id`
* `price`

This is a many-to-many-style relationship table between bookings and show seats.

The price is stored here as a **price snapshot**.

For example, if the price was ₹250 when the booking was created, later changes to pricing should not change the historical booking amount.

The schema intentionally does **not** enforce:

```text
UNIQUE(show_seat_id)
```

because historical booking records must be retained even if a booking is cancelled or failed.

The concurrency logic instead ensures that a seat cannot be successfully booked by two users at the same time.

---

# 9. Payment

The `payment` table stores payment transactions.

Important attributes:

* `payment_id`
* `booking_id`
* `provider`
* `provider_payment_id`
* `amount`
* `status`
* timestamps

Possible states:

```text
CREATED
SUCCESS
FAILED
```

The following constraint is particularly important:

```text
UNIQUE(provider, provider_payment_id)
```

Payment providers can retry webhook delivery.

For example:

```text
Webhook 1 → pay_123 → SUCCESS
Webhook 2 → pay_123 → SUCCESS
Webhook 3 → pay_123 → SUCCESS
```

The database must not create three payment records.

The unique constraint makes the payment operation idempotent at the database level.

---

# 10. Normalization

The schema is designed to avoid unnecessary duplication and update anomalies.

## 10.1 First Normal Form — 1NF

The tables contain atomic values.

For example, seats are not stored as:

```text
A1,A2,A3,A4,A5
```

inside a single column.

Instead, each seat is represented as a separate row.

Similarly, multiple seats belonging to a booking are stored in `booking_seat`.

---

## 10.2 Second Normal Form — 2NF

Non-key attributes depend on the complete key of their respective entity.

Relationship-specific information is separated into appropriate tables.

For example:

```text
booking
booking_seat
```

are separated because seat-level information belongs to the booking-seat relationship rather than the booking itself.

---

## 10.3 Third Normal Form — 3NF

Non-key attributes do not unnecessarily depend on other non-key attributes.

For example, `show` does not store:

```text
theatre_id
theatre_name
```

because the theatre can be determined through:

```text
show → screen → theatre
```

Similarly, screen seat counts are not duplicated in `screen`.

---

## 10.4 BCNF

The main entities use candidate/primary keys appropriately, while relationship-specific data is separated into relationship tables.

Examples include:

```text
UNIQUE(screen_id, seat_position)
UNIQUE(show_id, seat_id)
UNIQUE(provider, provider_payment_id)
```

These constraints ensure that alternate candidate keys are also respected.

---

# 11. Indexing Strategy

Indexes are created according to expected query patterns.

### Theatre

```text
(city)
(name, city)
```

Useful for theatre discovery.

### Screen

```text
(theatre_id)
```

Useful for retrieving screens belonging to a theatre.

### Seat

```text
(screen_id)
UNIQUE(screen_id, row_label, seat_number)
```

Useful for retrieving seats for a screen.

### Show

```text
(screen_id, show_date, start_time)
(movie_id, show_date)
(show_date)
```

The most important query is:

> Get all shows for a theatre on a particular date.

The query follows:

```text
theatre
   ↓
screen
   ↓
show
```

and filters by:

```text
screen.theatre_id
show.show_date
```

The `show` indexes support efficient date/time retrieval.

### Show Seat

```text
(show_id, status)
```

This supports seat-availability queries such as:

```text
Get AVAILABLE seats for show X
```

### Seat Hold

```text
(status, expires_at)
```

This supports finding expired active holds.

### Booking

```text
(user_id)
(show_id, status)
(created_at)
```

These support user booking history and booking-status queries.

### Payment

```text
UNIQUE(provider, provider_payment_id)
```

This supports webhook idempotency and prevents duplicate payment records.

---

# 12. Concurrency and Seat Locking

Seat booking is the most concurrency-sensitive operation.

Multiple users may attempt to acquire the same seat simultaneously.

The system uses InnoDB transactions and:

```sql
SELECT ... FOR UPDATE
```

to lock the specific `show_seat` row.

The basic flow is:

```text
START TRANSACTION
        ↓
SELECT show_seat
FOR UPDATE
        ↓
Is status AVAILABLE?
     /        \
   NO          YES
   ↓            ↓
ROLLBACK    UPDATE → HELD
                ↓
          Create seat_hold
                ↓
             COMMIT
```

The row-level lock ensures that concurrent transactions cannot simultaneously modify the same seat.

### Example

Two users attempt to acquire:

```text
show_seat_id = 50401
```

Transaction A obtains the lock first.

Transaction B waits for the lock.

After Transaction A commits, Transaction B obtains the lock and sees:

```text
HELD
```

Transaction B therefore cannot acquire the seat.

This prevents double allocation of the same seat.

---

# 13. Hold Expiration

Seats should not remain locked indefinitely if the user abandons the payment flow.

The system tracks:

```text
expires_at
```

for every hold.

Expired holds transition from:

```text
ACTIVE → EXPIRED
```

and the corresponding seat transitions from:

```text
HELD → AVAILABLE
```

These operations should occur in a transaction so that the hold and seat state remain consistent.

A scheduled worker or background process can periodically identify:

```sql
WHERE status = 'ACTIVE'
AND expires_at <= NOW()
```

and release those holds.

---

# 14. Booking Lifecycle

The intended lifecycle is:

```text
AVAILABLE
    ↓
HELD
    ↓
PENDING BOOKING
    ↓
PAYMENT
    ↓
CONFIRMED
```

If the hold expires:

```text
HELD
  ↓
EXPIRED
  ↓
AVAILABLE
```

If payment fails:

```text
PENDING
  ↓
FAILED
```

The exact release/retry behavior can be implemented by the application service according to the payment workflow.

---

# 15. Payment Idempotency

Payment providers may deliver the same webhook multiple times.

The database protects against duplicate processing through:

```text
UNIQUE(provider, provider_payment_id)
```

Example:

```text
Webhook
provider = RAZORPAY
provider_payment_id = pay_123
```

If the same event arrives again, the database rejects a duplicate payment record.

The application should then retrieve the existing payment and treat the repeated webhook as already processed.

---

# 16. Deadlock Prevention

When multiple seats are selected in one transaction, locks should be acquired in a consistent order.

For example:

```text
50401
50402
50403
```

should always be locked in ascending order.

Avoid one transaction locking:

```text
50401 → 50402
```

while another locks:

```text
50402 → 50401
```

because this can create a circular wait.

The application should also handle transaction/deadlock errors appropriately, including rollback and retry where safe.

---

# 17. Query — Shows at a Theatre on a Date

The main P2 query follows:

```text
Theatre
   ↓
Screen
   ↓
Show
   ↓
Movie
```

Example:

```sql
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
```

This returns all shows scheduled at the requested theatre on the requested date.

---

# 18. Sample Data

The sample dataset contains:

* 2 theatres
* 3 screens
* Multiple physical seats
* 3 movies
* Multiple shows across different dates
* Available, held and booked seats
* Active, expired and released holds
* Confirmed, pending and cancelled bookings
* Successful, created and failed payments

The data intentionally demonstrates different lifecycle states rather than containing only successful transactions.

---

# 19. SQL File Structure

The repository separates schema, data, queries and concurrency examples:

```text
sql/
├── 01_schema.sql
├── 02_sample_data.sql
├── 03_queries.sql
└── 04_concurrency.sql
```

### `01_schema.sql`

Contains:

* Database creation
* Table definitions
* Primary keys
* Foreign keys
* Unique constraints
* Check constraints
* Indexes

### `02_sample_data.sql`

Contains executable sample `INSERT` statements.

### `03_queries.sql`

Contains:

* Theatre/show queries
* Seat availability
* Active holds
* Expired holds
* Booking queries
* Payment queries
* Idempotency checks

### `04_concurrency.sql`

Contains:

* Row-level locking
* Concurrent seat acquisition
* Hold expiration
* Booking conversion
* Payment idempotency
* Deadlock considerations
* Transaction isolation considerations

---

# 20. Design Summary

The database separates different concepts rather than storing everything in a single booking table.

The most important design decisions are:

1. **Physical seats are separated from show-specific seats.**
2. **`show_seat` maintains seat state for each show.**
3. **Temporary holds are represented separately from permanent bookings.**
4. **Historical booking and hold records are retained.**
5. **Prices are stored as snapshots where required.**
6. **Payment provider IDs are unique for webhook idempotency.**
7. **`SELECT ... FOR UPDATE` provides seat-level concurrency control.**
8. **Transactions keep related state changes consistent.**
9. **Indexes target the primary read and concurrency paths.**
10. **The schema avoids unnecessary redundant attributes and follows normalization principles.**

The resulting design provides a normalized relational foundation for a high-concurrency movie-ticketing system while leaving distributed concerns such as caching, queues, rate limiting and horizontal scaling to the application/infrastructure layer.
