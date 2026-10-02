# BookMyShow-Style Ticketing System — Database Design

A MySQL database design for a BookMyShow-style movie ticketing platform, focusing on **seat-level concurrency, temporary seat holds, booking consistency, payment idempotency, indexing, and query optimization**.

The design is intended to handle scenarios where thousands of users may attempt to book seats for the same show concurrently.

---

## 1. Problem Statement

The system supports:

* Theatres with multiple screens
* Movies and scheduled shows
* Seat-level availability
* Temporary seat holds with automatic expiry
* Concurrent booking attempts
* Booking and booking-seat management
* Payment processing
* Idempotent payment webhooks
* Query optimization through appropriate indexes

The primary challenge is preventing **double booking when multiple users attempt to reserve the same seat simultaneously**.

---

## 2. Key Design Decisions

### Seat-Level Inventory

Seats are represented independently for each show using the `show_seat` table.

Each show therefore has its own inventory:

```text
Show
 └── Show Seats
      ├── A1 → AVAILABLE
      ├── A2 → HELD
      ├── A3 → BOOKED
      └── ...
```

This allows seat availability to be updated atomically without locking an entire show or theatre.

### Concurrency Control

InnoDB row-level locking is used with:

```sql
SELECT ... FOR UPDATE;
```

The booking flow locks the target `show_seat` row before changing its status.

This ensures that two concurrent transactions cannot successfully acquire the same seat.

### Temporary Holds

A seat can temporarily transition to:

```text
AVAILABLE → HELD → BOOKED
                  │
                  └──→ AVAILABLE
```

if the hold expires.

The `seat_hold` table maintains the hold lifecycle and expiration timestamp.

A generated-column-based unique constraint ensures that only one active hold can exist for a particular show seat.

### Payment Idempotency

Payment webhooks may be delivered more than once.

The following constraint prevents duplicate provider payment records:

```sql
UNIQUE (provider, provider_payment_id)
```

Therefore, the same payment event can safely be retried without creating duplicate payments.

---

## 3. Database Schema

The database contains the following core tables:

| Table          | Purpose                        |
| -------------- | ------------------------------ |
| `theatre`      | Theatre information            |
| `screen`       | Screens within theatres        |
| `seat`         | Physical seats within screens  |
| `movie`        | Movie information              |
| `movie_show`   | Movie schedules                |
| `show_seat`    | Seat inventory for each show   |
| `seat_hold`    | Temporary seat reservations    |
| `booking`      | Booking/order information      |
| `booking_seat` | Seats associated with bookings |
| `payment`      | Payment transactions           |

### Main Relationships

```text
THEATRE
   │
   └── SCREEN
         │
         └── SEAT

MOVIE
   │
   └── MOVIE_SHOW
         │
         └── SHOW_SEAT
               │
               └── SEAT_HOLD

MOVIE_SHOW
   │
   └── BOOKING
         │
         ├── BOOKING_SEAT
         │
         └── PAYMENT
```

---

## 4. Normalization

The schema is designed around **1NF, 2NF, 3NF, and BCNF principles**.

Key normalization decisions include:

* Theatre information is separated from screens.
* Screen information is separated from physical seats.
* Movie information is separated from show scheduling.
* Show-specific seat inventory is separated from physical seat definitions.
* Booking and booking-seat relationships are separated to support multiple seats per booking.
* Payment information is separated from booking information.
* Derived values such as screen seat count are not stored redundantly.

This reduces update anomalies and keeps each relation focused on a single responsibility.

Detailed normalization analysis is available in:

`docs/database-design.md`

---

## 5. Concurrency Strategy

A simplified seat-hold transaction is:

```text
BEGIN TRANSACTION

        │
        ▼
Lock show_seat row
        │
        ▼
Check status = AVAILABLE
        │
        ▼
Change status → HELD
        │
        ▼
Create seat_hold
        │
        ▼
COMMIT
```

If another transaction attempts to acquire the same seat concurrently, it waits for the existing row lock.

After the first transaction commits, the second transaction observes that the seat is no longer available and does not create another hold.

The detailed concurrency scenarios are documented in:

`sql/04_concurrency.sql`

---

## 6. Hold Expiration

Each active hold contains an `expires_at` timestamp.

Expired holds can be identified using:

```sql
SELECT hold_id, show_seat_id, expires_at
FROM seat_hold
WHERE status = 'ACTIVE'
  AND expires_at <= NOW();
```

The cleanup process changes:

```text
ACTIVE → EXPIRED
```

and releases the associated seat:

```text
HELD → AVAILABLE
```

The update is performed transactionally to avoid releasing a seat that has already progressed to another state.

---

## 7. Payment Webhook Idempotency

Payment providers may send the same webhook multiple times.

The schema protects against duplicate processing using:

```sql
UNIQUE (provider, provider_payment_id)
```

Example:

```text
Webhook #1
    ↓
pay_demo_10001
    ↓
Payment created

Webhook #2
    ↓
pay_demo_10001
    ↓
Existing payment detected
    ↓
No duplicate payment record
```

This allows payment processing to safely tolerate retries.

---

## 8. Query Optimization

Indexes are created based on expected access patterns.

Examples include:

```text
(screen_id, show_date, start_time)
(show_id, status)
(status, expires_at)
(provider, provider_payment_id)
(show_id, seat_id)
```

The P2 query retrieves all shows for a theatre on a specified date and returns their movie names, screens, and timings.

Example:

```sql
SELECT
    s.show_id,
    m.title AS movie,
    sc.name AS screen,
    s.show_date,
    s.start_time,
    s.end_time
FROM movie_show s
JOIN movie m
    ON s.movie_id = m.movie_id
JOIN screen sc
    ON s.screen_id = sc.screen_id
WHERE sc.theatre_id = 1
  AND s.show_date = '2026-10-01'
ORDER BY s.start_time;
```

---

## 9. Repository Structure

```text
bookmyshow-ticketing-system/
│
├── README.md
│
├── docs/
│   └── database-design.md
│
├── sql/
│   ├── 01_schema.sql
│   ├── 02_sample_data.sql
│   ├── 03_queries.sql
│   └── 04_concurrency.sql
│
└── .gitignore
```

### File Descriptions

| File                 | Description                                                           |
| -------------------- | --------------------------------------------------------------------- |
| `01_schema.sql`      | Database and table definitions                                        |
| `02_sample_data.sql` | Sample theatres, screens, seats, shows, bookings, holds, and payments |
| `03_queries.sql`     | P2 query and operational/read queries                                 |
| `04_concurrency.sql` | Seat locking, hold expiry, booking, and payment concurrency examples  |
| `database-design.md` | Detailed design and normalization documentation                       |

---

## 10. How to Run

### Prerequisites

* MySQL 8.0+
* MySQL client, MySQL Workbench, or another MySQL-compatible SQL client

### Step 1 — Create the schema

Execute:

```text
sql/01_schema.sql
```

This creates the `bookmyshow` database and all required tables.

### Step 2 — Insert sample data

Execute:

```text
sql/02_sample_data.sql
```

### Step 3 — Run queries

Execute individual queries from:

```text
sql/03_queries.sql
```

This includes:

* Shows by theatre and date
* Seat availability
* Active holds
* Expired holds
* Booking details
* Booking seats
* Payment status
* Pending bookings
* Payment idempotency lookup

### Step 4 — Review concurrency scenarios

Open:

```text
sql/04_concurrency.sql
```

The concurrency examples demonstrate:

* Row-level seat locking
* Concurrent seat acquisition
* Hold expiration
* Hold-to-booking conversion
* Payment webhook idempotency
* Booking/payment consistency
* Deadlock prevention considerations

Some concurrency examples are intended to be executed across **two MySQL sessions** to observe transaction behavior.

---

## 11. Sample Scenario

The sample data demonstrates multiple real-world states.

### Confirmed booking

```text
Show 10003
 ├── A1 → BOOKED
 └── A2 → BOOKED

Booking 90001
Payment → SUCCESS
Booking → CONFIRMED
```

### Pending booking with active holds

```text
Show 10005
 ├── A1 → HELD
 ├── A2 → HELD
 └── A3 → HELD

Booking 90002
Payment → CREATED
Booking → PENDING
```

### Cancelled booking

```text
Show 10001
 └── A1 → AVAILABLE

Booking 90003
Payment → FAILED
Booking → CANCELLED
```

This demonstrates that historical booking records can be retained without incorrectly making a cancelled seat permanently unavailable.

---

## 12. Design Goals

The database design prioritizes:

* **Correctness** — prevent double booking and inconsistent payment states
* **Concurrency safety** — use transactional row-level locking
* **Normalization** — minimize redundancy and update anomalies
* **Performance** — support common theatre/show/seat queries through indexes
* **Idempotency** — safely handle repeated payment webhooks
* **Maintainability** — separate physical seats, show inventory, bookings, and payments
* **Auditability** — retain booking and payment history

---

## 13. Detailed Documentation

For the complete explanation of:

* Entity design
* Relationships
* Table structures
* Normalization
* Indexing strategy
* Concurrency
* Seat locking
* Hold expiration
* Booking lifecycle
* Payment idempotency
* Deadlock prevention

see:

```text
docs/database-design.md
```

---

## 14. Submission Notes

This repository contains the database design and SQL implementation for the assignment.

The SQL files are organized so that the schema and sample data can be created first, followed by query and concurrency demonstrations.

The design intentionally focuses on the **database and transaction layer** of a high-concurrency ticketing system rather than implementing the application/API layer.
