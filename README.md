# High-Concurrency Booking Engine

This project contains a BookMyShow-style ticketing backend design and MySQL schema for a movie booking system where users book seats for a show at a theatre.

## Scenario

For a given theatre, the application shows the next 7 dates. When a date is selected, it displays all shows running at that theatre on that date, along with their timings.

The goal is to design a database that can safely handle high concurrency with:

- seat-level locking
- automatic release of holds after timeout
- idempotent payment webhook handling
- scalable indexing and query design

## Project structure

- `bookmyshow_schema.sql` – complete MySQL schema, sample data, and query examples
- `docs/assignment-writeup.md` – readable assignment document for submission

## P1: Entities and schema

### Main tables

- theatres
- screens
- movies
- shows
- seats
- show_seat_inventory
- users
- bookings
- booking_seats
- payments
- payment_webhooks

### Normalization notes

- 1NF: atomic values and non-repeating fields
- 2NF: attributes depend on the whole key
- 3NF: no transitive dependency
- BCNF: every determinant is a candidate key

### Concurrency rule

The `show_seat_inventory` table is the main seat state table. Every seat is uniquely identified by `(show_id, seat_id)`, and status transitions are guarded by row-level locking.

Typical pattern:

1. Lock the seat row with `SELECT ... FOR UPDATE`
2. Check status
3. Update to `HELD` if available
4. Set `hold_expires_at`
5. Release lock after commit

This prevents double-booking and lost holds under concurrent requests.

## P2: Query to list shows for a theatre and date

The SQL query is included in `bookmyshow_schema.sql`.

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

## How to use

1. Open MySQL Workbench or mysql CLI.
2. Run the SQL script from `bookmyshow_schema.sql`.
3. Verify tables and sample data exist.
4. Execute the query for the required theatre and date.
