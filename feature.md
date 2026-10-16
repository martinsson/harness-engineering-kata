## Missing feature to implement

### Feature: Stock reservation with expiry

1. Add command: `RESERVE;<customer>;<sku>;<qty>;<minutes>`
2. Reserve only if enough available stock exists.
3. Add command: `CONFIRM;<reservationId>` to convert reservation into a shipped order.
4. Add command: `RELEASE;<reservationId>` to release stock manually.
5. Reservations should expire automatically based on the configured minutes, returning stock to availability.

