from dataclasses import dataclass
from datetime import datetime, timedelta


@dataclass
class _Reservation:
    customer: str
    sku: str
    qty: int
    expires_at: datetime


class ReservationService:
    """Handles RESERVE/CONFIRM/RELEASE and time-based expiry of holds."""

    def __init__(self, inventory, ledger, clock):
        self._inventory = inventory
        self._ledger = ledger
        self._clock = clock
        self._items: dict[str, _Reservation] = {}
        self._next_id: int = 1

    def purge(self):
        now = self._clock()
        expired = [rid for rid, item in self._items.items() if now >= item.expires_at]
        for reservation_id in expired:
            item = self._items.pop(reservation_id)
            self._inventory.free(item.sku, item.qty)

    def reserve(self, parts):
        customer, sku = parts[1], parts[2]
        qty, minutes = int(parts[3].strip()), int(parts[4].strip())
        self.purge()
        if self._inventory.available(sku) < qty:
            self._ledger.record(f"reservation failed for {customer} sku={sku} qty={qty}: insufficient stock")
            return
        reservation_id = f"R{self._next_id}"
        self._next_id += 1
        self._items[reservation_id] = _Reservation(customer, sku, qty, self._clock() + timedelta(minutes=minutes))
        self._inventory.hold(sku, qty)
        self._ledger.record(f"reserved {qty} of {sku} for {customer} reservation={reservation_id}")

    def confirm(self, parts):
        reservation_id = parts[1]
        item = self._items.get(reservation_id)
        if item is None:
            self._ledger.record(f"reservation {reservation_id} not found")
            return
        if self._clock() >= item.expires_at:
            self._expire(reservation_id, item)
            return
        self._ship(reservation_id, item)

    def release(self, parts):
        reservation_id = parts[1]
        item = self._items.get(reservation_id)
        if item is None:
            self._ledger.record(f"reservation {reservation_id} not found")
            return
        del self._items[reservation_id]
        self._inventory.free(item.sku, item.qty)
        self._ledger.record(f"released reservation={reservation_id} sku={item.sku} qty={item.qty}")

    def _expire(self, reservation_id, item):
        del self._items[reservation_id]
        self._inventory.free(item.sku, item.qty)
        self._ledger.record(f"reservation {reservation_id} expired")

    def _ship(self, reservation_id, item):
        self._inventory.take(item.sku, item.qty)
        self._inventory.free(item.sku, item.qty)
        order_total = self._inventory.price(item.sku) * item.qty
        self._ledger.credit(order_total)
        del self._items[reservation_id]
        self._ledger.record(
            f"confirmed reservation={reservation_id} shipped to {item.customer}"
            f" sku={item.sku} qty={item.qty} amount={order_total}"
        )
