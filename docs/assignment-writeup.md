# BookMyShow-Style High-Concurrency Booking Engine

## Objective

Design a database schema and SQL solution for a ticketing system where users book movie tickets for a theatre and specific show timings. The design must handle high concurrency without allowing double booking and without losing seat holds.

## Entities

1. Theatre
2. Screen
3. Movie
4. Show
5. Seat
6. Show seat inventory
7. User
8. Booking
9. Booking seat
10. Payment
11. Payment webhook

## Normalization and integrity

The schema follows:

- 1NF: each table contains atomic values and each row is unique for its entity
- 2NF: all non-key attributes depend on the whole primary key
- 3NF: no transitive dependencies
- BCNF: all determinants are candidate keys

The `show_seat_inventory` table is the critical concurrency table. It stores the seat state per show and seat, which allows row-level locking to prevent simultaneous seat reservations.

## High-concurrency design

- Use `SELECT ... FOR UPDATE` on the seat row
- Update status to `HELD` when seats are reserved
- Set expiry time using `hold_expires_at`
- Release or expire stale holds automatically
- Use idempotent payment webhook processing through unique `(payment_id, provider_event_id)`

## SQL schema

The schema is implemented in `bookmyshow_schema.sql` and is directly executable in MySQL.

## P2 query

```sql
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
```

## Submission summary

This assignment provides:

- complete table design
- sample records
- normalized schema
- concurrency-safe seat locking strategy
- query for listing shows on a theatre + date
